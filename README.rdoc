= DropBox

A simple Ruby API for DropBox

== INSTALL:
* sudo gem install dropbox

== USAGE:

  d = DropBox.new("you@email.com","password!")
  p d.list("/")