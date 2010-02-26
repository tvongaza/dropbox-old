require 'nokogiri'
require 'mechanize'

Mechanize.html_parser = Nokogiri::HTML

# TODO: Tests (mock out expected DropBox output)
# TODO: Directory object, File object

class DropBox
	#before_filter :login_filter, :except => [:login]
	
	def initialize(email, password, folder_namespace = "")
		@email = email
		@password = password
		@agent = Mechanize.new
		@folder_namespace = folder_namespace.gsub(/^\//,"")
		@logged_in = false
	end
	
	# Lists all the files and folders in a given directory
	def index(path = "/")
 		login_filter
		path = namespace_path(path)
		
		list = @agent.post("/browse2#{path}?ajax=yes", {"d"=> 1, "t" => @token })
		
		listing = list.search('div.browse-file-box-details').collect do |file|
			details = {}
			details['name'] = file.at('div.details-filename a').content.strip
			details['url']  = file.at('div.details-filename a')["href"]
			#details['size'] = file.at('div.details-size a').try(:content).try(:strip)
			#details['modified'] = file.at('div.details-modified a').try(:content).try(:strip)
			
			if match_data = details['url'].match(/^\/browse_plain(.*)$/)
				details['directory'] = true
				details['path'] = normalize_namespace(match_data[1])
			elsif match_data = details['url'].match(%r{^https?://[^/]*/get(.*)$})
				details['directory'] = false
				details['path'] = normalize_namespace(match_data[1])
      elsif match_data = details['url'].match(%r{^https?://[^/]*/u/\d*/(.*)$})
          details['directory'] = false
          details['path'] = "Public/#{match_data[1]}"
			else
				raise "could not parse path from Dropbox URL: #{details['url'] }"
			end
			
			details
		end
		
		return listing
	end
	
	alias :list :index
	
	# Lists the full history for a file on DropBox
	def list_history(path)
		login_filter
		
		path = namespace_path(path)

		history = @agent.get("/revisions#{path}")
		listing = history.search("table.filebrowser > tr").select{|r| r.search("td").count > 1 }.collect do |r|
			
			# warning, this is very brittle!
			details = {}
			details["version"] = r.search("td a").first.content.strip
			details["url"] = r.search("td a").first["href"]
			details["size"] = r.search("td").last.content.strip
			details["modified"] = r.search("td")[2].content.strip
			details["version_id"] = details["url"].match(/^.*sjid=([\d]*)$/)[1]
			details['path'] = normalize_namespace(details['url'][33..-1])
			
			details
		end
		
		return listing
	end
	
	# Downloads the specified file from DropBox
	def show(path)
		# change to before filter
		login_filter
		
		path = namespace_path(path)
		
		#https://dl-web.dropbox.com/get/testing.txt?w=0ff80d5d&sjid=125987568
		@agent.get("https://dl-web.dropbox.com/get/#{path}").content
	end
	
	alias :get :show
	
	# Creates a directory
	def create_directory(new_path, destination = "/" )
		# change to before filter
		login unless @logged_in
		destination = namespace_path(destination)
		@agent.post("/cmd/new#{destination}",{"to_path"=>new_path, "folder"=>"yes", "t" => @token }).code == "200"
	end
	
	# Uploads a file to DropBox under the given filename
	def create(file, destination = "/")
		# change to before filter
		if @logged_in
			home_page = @agent.get('https://www.dropbox.com/home')
		else
			home_page = login
		end
		
		upload_form = home_page.forms.detect{ |f| f.action == "https://dl-web.dropbox.com/upload" }
		upload_form.dest = namespace_path(destination)
		upload_form.file_uploads.first.file_name = file if file
		
		@agent.submit(upload_form).code == "200"
	end
	
  alias :update :create
	
	# Renames a file or folder in the DropBox
	def rename(file, destination)
		login_filter
		file = namespace_path(file)
		destination = namespace_path(destination)
		@agent.post("/cmd/rename#{file}", {"to_path"=> destination, "t" => @token }).code == "200"
	end
	
	# Deletes a file/folder from the DropBox (accepts string path or an array of string paths)
	def destroy(paths)
		login_filter
		paths = [paths].flatten
		paths = paths.collect { |path| namespace_path(path) }
		@agent.post("/cmd/delete", {"files"=> paths, "t" => @token }).code == "200"
	end

  # Permanently deletes a file from the DropBox (no history!) accepts arrays, as #destroy does
	def purge(paths)
		login_filter
		paths = [paths].flatten
		paths = paths.collect { |path| namespace_path(path) }
		@agent.post("/cmd/purge", {"files"=> paths, "t" => @token }).code == "200"
	end
	
	# Will give a hash of the amount of space left on the DropBox, the amound used, the calculated amount free (all as a 1 d.p. rounded GB value) and the percentage used (scraped)
	def usage_stats
	  login_filter
	  @agent.get("/account").at('#usage-percent').content.scan(/(\d+(?:\.\d+)?)%\ used\ \((\d+(?:\.\d+)?)([MG])B of (\d+(?:\.\d+)?)GB\)/).collect{|d| {:used => d[1].to_f * ((d[2] == "M") ? 1024 : 1), :total => d[3].to_f, :free => (d[3].to_f - d[1].to_f * ((d[2] == "M") ? 1024 : 1)), :percent => Percentage.new(d[0].to_f/100)} }[0]
  end

	private
	def namespace_path(path)
		# remove the start slash if we have one
		path.gsub(/^\//,"")
		if @folder_namespace.empty?
			"/#{path}"
		else
			"/#{@folder_namespace}/#{path}"			
		end
	end
	
	def normalize_namespace(file)
		file.gsub(/^\/#{@folder_namespace}/,"")
	end

  def login
		page = @agent.get('https://www.dropbox.com/login')
		login_form = page.forms.detect { |f| f.action == "/login" }
		login_form.login_email = @email
		login_form.login_password = @password
		
		home_page = @agent.submit(login_form)
		# todo check if we are logged in! (ie search for email and "Log out"
		@logged_in = true
		@token = home_page.at('//script[contains(text(), "TOKEN")]').content.match("TOKEN: '(.*)',$")[1]
		
		# check if we have our namespace
		
		home_page
	end
	
	def login_filter
		login unless @logged_in
	end
end

# this file doesn't use the standard ruby indent settings, so the following
# modeline will make sure that the whitespace stays consistent.
# vim:noexpandtab tabstop=4 shiftwidth=4
