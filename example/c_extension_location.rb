#!/usr/bin/env ruby

require 'rubygems'
require 'c_location'

puts CompiledLocation.instance_method(:compiled_location).c_location.inspect
