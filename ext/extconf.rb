require 'mkmf'

extension_name = "c_location"

$CFLAGS += " -DRUBY_19" if RUBY_VERSION =~ /1.9/
$CFLAGS += " -DRUBY_193" if RUBY_VERSION =~ /1.9.3/

dir_config(extension_name)

create_makefile(extension_name)
