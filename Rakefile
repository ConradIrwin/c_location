def dir(*args); Dir.chdir(File.join(File.dirname(__FILE__), *args)); end
desc "Compile local copy"
task :compile do
  dir('ext')
  system "make clean"
  system "ruby extconf.rb && make"
end

desc "Run an interactive shell"
task :pry do
  dir('.')
  system "pry -f -r lib/c_location"
end

task :default => [:clean, :compile, :test]
