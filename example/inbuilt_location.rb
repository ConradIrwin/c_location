#!/usr/bin/env ruby

require 'rubygems'
require 'c_location'

puts Math.method(:sin).c_location.inspect
