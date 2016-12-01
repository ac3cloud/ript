#!/usr/bin/env ruby

if RUBY_VERSION =~ /^1.8/ then
  puts "Ript requires Ruby 1.9 to run. Exiting."
  exit 2
end

$: << Pathname.new(__FILE__).dirname.parent.expand_path.to_s
require 'ript/dsl/primitives'
require 'ript/rule'
require 'ript/partition'
require 'ript/exceptions'
require 'ript/patches'
