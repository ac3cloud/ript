#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'aruba/cucumber'
require 'colorize'

if Process.uid != 0
  puts "You need to be root to run these tests!"
  abort
end

def clean_slate_after_2_minutes
  root    = Pathname.new(__FILE__).parent.parent.parent
  path    = ENV['PATH']

  clean_command = "export PATH=#{path} && echo 'cd #{root} && rake clean_slate'"
  at_command    = "at 'now + 2 minutes' >/dev/null 2>&1"
  command       = "#{clean_command} | #{at_command}"

  puts "If these tests lock you out, all iptables rules will be flushed in 2 minutes.\n".yellow
  system(command)
end

clean_slate_after_2_minutes
