Gem::Specification.new do |s|
  s.name = "c_location"
  s.version = "0.2"
  s.platform = Gem::Platform::RUBY
  s.author = "Conrad Irwin"
  s.email = "conrad.irwin@gmail.com"
  s.license = "MIT"
  s.homepage = "http://github.com/ConradIrwin/c_location"
  s.summary = "Adds a #c_location to Method and UnboundMethod objects."
  s.description = "Allows you to find the source location of methods written in C"
  s.files = ["lib/c_location.rb",
             "lib/c_location/resolver.rb",
             "ext/extconf.rb",
             "ext/c_location.c",
             "ext/c_location.h",
             "example/c_extension_location.rb",
             "example/inbuilt_location.rb",
             "README.md",
             "LICENSE.MIT"]
  s.require_path = "lib"
  s.extensions = ["ext/extconf.rb"]
end
