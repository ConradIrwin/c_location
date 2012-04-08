module CompiledLocation
  class Resolver
    attr_accessor :shared_library, :offset

    def initialize(shared_library, offset)
      self.shared_library, self.offset = [shared_library, offset]
      self.shared_library = `which ruby` if self.shared_library == 'ruby'
    end

    def source_location
      if RUBY_PLATFORM =~ /darwin/
        nm(shared_library, offset)
      else
        objdump(shared_library, offset)
      end
    end

    def objdump(shared_library, offset)
      command = "#{Shellwords.escape which_objdump} --dwarf=decodedline #{Shellwords.escape shared_library}"
      output = run(command)

      if m = output.lines.detect{ |line| line =~ /\s+0x#{offset.to_s(16)}$/ }
        file, line, address = m.split(/\s+/)

        [absolutify_file(file, shared_library), line.to_i(10)]
      else
        raise "Could not find #{shared_library}@0x#{offset.to_s(16)} using #{command.inspect}." +
              "This may be because your ruby/extensions are not compiled with -g."
      end
    end

    def nm(shared_library, offset)
      command = "#{Shellwords.escape which_nm} -pa #{Shellwords.escape shared_library}"
      output = run(command)

      o_file = nil

      output.lines.each do |line|
        case line
        when /OSO (.*\.o\)?)/
          o_file = $1.sub(%r{(.*)/([^/]*)\((.*)\)}, '\1/\3')
        when /^[01]*#{offset.to_s(16)}.*FUN (.+)/
          raise "Your version of nm seems to not output OSO lines." unless o_file
          return objdump_tt(o_file, $1)
        end
      end

      raise "Could not find #{shared_library}@0x#{offset.to_s(16)} using #{command.inspect}." +
            "This may be because your ruby/extensions are not compiled with -g."
    end

    def objdump_tt(shared_library, name)
      output = run("#{Shellwords.escape which_objdump} -tT #{Shellwords.escape shared_library}")

      if output.lines.detect{ |line| line =~ /^([0-9a-f]+).*\.text\s#{Regexp.escape name}$/ }
        objdump(shared_library, $1.to_i(16))
      else
        raise "Could not find #{shared_library}##{name} using #{command.inspect}."
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

      if potentials.empty?
        raise "Could not find the `#{file}` that was used to build `#{shared_library}`." +
              "If you know where this file is please submit a pull request"
      else
        potentials.first
      end
    end

    def run(command)
      `#{command}`.tap do |output|
        raise "Failed to run #{command.inspect}: #{output}" unless $?.success?
      end
    end
  end
end
