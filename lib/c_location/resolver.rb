module CompiledLocation
  class Resolver
    attr_accessor :shared_library, :offset, :file, :line

    def initialize(shared_library, offset)
      self.shared_library, self.offset = [shared_library, offset]
      self.shared_library = `which ruby` if self.shared_library == 'ruby'
    end

    def source_location
      case shared_library
      when /\.so[.0-9]*\z/, /\.o\z/
        objdump

      when /.\.(bundle|dylib)\z/
        nm

      end

      return [self.file, self.line] if self.file

      raise "Could not find which file or line represented #{shared_library}@0x#{offset.to_s(16)}. " +
            "This may be because your ruby/extensions are not being compiled with -g, " +
            "or it may just be broken."
    end

    def objdump(lib=shared_library)
      command = "#{Shellwords.escape which_objdump} --dwarf=decodedline #{Shellwords.escape shared_library}"
      output = `#{command}`
      raise "Failed to run #{command.inspect}: #{output}" unless $?.success?

      output.lines.grep(/\s+0x#{offset.to_s(16)}$/).each do |m|

        file, line, address = m.split(/\s+/)

        self.file = absolutify_file(file)
        self.line = line.to_i
      end
    end

    def nm
      output = `#{Shellwords.escape which_nm} -a #{Shellwords.escape shared_library}`
      raise "Failed to run #{which_nm}: #{output}" unless $?.success?

      output.lines.grep(/\.o$/).each do |line|
        objdump(line.split(/\s+/).last)
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
      nm = `which gnm`.chomp
      return nm if $?.success?
      nm = `which nm`.chomp
      return nm if $?.success?
      nm = `which /usr/local/bin/gnm`.chomp
      return nm if $?.success?

      raise "You need to have `nm` installed to use c_location. " +
            "Try installing the binutils package (apt-get install binutils; brew install binutils)."

    end

    def absolutify_file(file)
      if shared_library =~ %r{(.*/gems/[^/]*)/}
        potentials = Dir["#{$1}/**/#{file}"]
      else
        potentials = Dir["./**/#{file}"]
      end

      if potentials.size == 1
        potentials.first
      elsif potentials.empty?
        raise "You are looking for a file called `#{file}`, but I can't find it :("
      else
        raise "You are looking for one of `#{potentials.join(", ")}`"
      end
    end
  end
end
