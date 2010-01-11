require 'spec'
require 'dropbox'

%w[DROPBOX_EMAIL DROPBOX_PASSWORD].each do |var|
  raise "Need to set #{var} to run the specs." unless ENV[var]
end
ENV["DROPBOX_FOLDER_NAMESPACE"] ||= "dropboxrb/specroot"

describe DropBox do
  before :all do
    # TODO: check for existance of DROPBOX_FOLDER_NAMESPACE
    # TODO: ensure the folder starts out empty
    @connection = connection
  end

  def connection
    DropBox.new(ENV["DROPBOX_EMAIL"],
                ENV["DROPBOX_PASSWORD"],
                ENV["DROPBOX_FOLDER_NAMESPACE"])
  end

  def dirent_for(name)
    @connection.list.find {|f| f["name"] == name }
  end

  context "uploading a file" do
    before :all do
      @file = Tempfile.new("dbrb")
      @contents = <<-EOF
        This is a temp file used by the dropbox.rb specs.
        foo
        bar
        baz
      EOF
      @file.print @contents
      @file.flush
      @basename = File.basename(@file.path)
      @connection.create(@file.path)
    end
    after :all do
      # TODO: fix the bugs that force us to reset the connection.before deleting the file
      @connection.login
      @connection.destroy @basename
      @file.close!
    end

    it "should be listed at the toplevel" do
      @connection.list.map {|f| f["name"] }.should include(@basename)
    end

    it "should be listed as not a directory" do
      dirent_for(@basename)["directory"].should be_false
    end

    it "should have a path relative to the folder namespace (containing query params)" do
      dirent_for(@basename)["path"].should match(%r{^/#{@basename}\?w=.*$})
    end

    it "should be retrievable" do
      path = dirent_for(@basename)["path"]
      @connection.get(path).should == @contents
    end

  end

  context "creating a directory at the toplevel" do
    before { @connection.create_directory("spec_create_dir") }
    after  { @connection.destroy("spec_create_dir") }

    it "should be listed at the toplevel" do
      @connection.list.map {|f| f["name"] }.should include("spec_create_dir")
    end

    it "should be listed as a directory" do
      dirent_for("spec_create_dir")["directory"].should be_true
    end

    it "should have a path relative to the folder namespace" do
      dirent_for("spec_create_dir")["path"].should == "/spec_create_dir"
    end

    it "should contain only a link to the parent directory" do
      list = @connection.list("spec_create_dir")
      list.should have(1).item
      dir = list.first
      dir["name"].should == "Parent folder"
      dir["directory"].should be_true
      dir["path"].should == ""
    end

  end

  #context "renaming a file"
  #context "deleting a file"

end

#describe DropBox, "folder namespace"
