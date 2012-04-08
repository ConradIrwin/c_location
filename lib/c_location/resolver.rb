module CompiledLocation
  class Resolver
    attr_accessor :shared_library, :offset, :file, :line

    def initialize(shared_library, offset)
      self.shared_library, self.offset = [shared_library, offset]
      self.shared_library = `which ruby` if self.shared_library == 'ruby'
    end

    def source_location
      if RUBY_PLATFORM =~ /darwin/
        nm
      else
        objdump
      end

      return [self.file, self.line] if self.file

      raise "Could not find which file or line represented #{shared_library}@0x#{offset.to_s(16)}. " +
            "This may be because your ruby/extensions are not being compiled with -g, " +
            "or it may just be broken."
    end

    def objdump(shared_library=self.shared_library, offset=self.offset)
      output = run("#{Shellwords.escape which_objdump} --dwarf=decodedline #{Shellwords.escape shared_library}")

      output.lines.grep(/\s+0x#{offset.to_s(16)}$/).each do |m|
        file, line, address = m.split(/\s+/)

        self.file = absolutify_file(file, shared_library)
        self.line = line.to_i
      end
    end

    def nm
      output = run("#{Shellwords.escape which_nm} -pa #{Shellwords.escape shared_library}")

      o_file = nil

      output.lines.each do |line|
        case line
        when /OSO (.*\.o\)?)/
          o_file = $1.sub(%r{(.*)/([^/]*)\((.*)\)}, '\1/\3')
        when /^[01]*#{offset.to_s(16)}.*FUN (.+)/
          raise "Your version of nm seems to not output OSO lines." unless o_file
          find_offset_for_name(o_file, $1)
          break
        end
      end
    end

    def find_offset_for_name(shared_library, name)
      output = run("#{Shellwords.escape which_objdump} -tT #{Shellwords.escape shared_library}")

      if output.lines.detect{ |line| line =~ /^([0-9a-f]+).*\.text\s#{Regexp.escape name}$/ }
        objdump shared_library, $1.to_i(16)
      else
        raise "Could not find #{name.inspect} in #{shared_library}"
      end
    end

    def which_objdump
      objdump = `which gobjdump`.chomp
      return objdump if $?.success?
      objdump = `which objdump`.chomp
      return objdump if $?.success?
      objdump = `which /usr/local/bin/gobjdump`.chomp
      return objdump if $?.success?

      raise "You need to have `objdump` installed to use c_location. " +
            "Try installing the binutils package (apt-get install binutils; brew install binutils)."
    end

    def which_nm
      nm = `which nm`.chomp
      return nm if $?.success?

      raise "You need to have `nm` installed to use c_location. " +
            "Try installing Xcode from the App Store. (GNU nm from binutils doesn't work unfortunately)"

    end

    def absolutify_file(file, shared_library)
      if shared_library =~ %r{(.*/(gems|src)/[^/]*)/}
        potentials = Dir["#{$1}/**/#{file}"]
      else
        potentials = Dir["./**/#{file}"]
      end

      if potentials.size == 1
        potentials.first
      elsif potentials.empty?
        raise "You are looking for a file called `#{file}` that was used to build `#{shared_library}` but I can't find it." +
	      "Try using `rvm` or submitting a patch."
      else
        raise "You are looking for one of `#{potentials.join(", ")}`"
      end
    end

    def run(command)
      `#{command}`.tap do |output|
        raise "Failed to run #{command.inspect}: #{output}" unless $?.success?
      end
    end
  end
end
