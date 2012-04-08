require 'shellwords'
require File.expand_path('../c_location/resolver', __FILE__)

module CompiledLocation
  def c_location
    if c = compiled_location
      CompiledLocation::Resolver.new(*c).source_location
    end
  end

  def compiled_location; end
  require File.expand_path('../../ext/c_location', __FILE__)
end
