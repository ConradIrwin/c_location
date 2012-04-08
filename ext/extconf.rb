require 'mkmf'

extension_name = "c_location"

if RUBY_VERSION =~ /1.9/
  $CFLAGS += " -DRUBY_19"
end

dir_config(extension_name)

create_makefile(extension_name)
