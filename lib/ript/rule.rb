#!/usr/bin/env ruby

$: << Pathname.new(__FILE__).dirname.parent.expand_path.to_s

require 'digest/md5'

module Ript
  class Rule
    def initialize(opts={})
      @comment = opts.delete(:comment)
      @raw     = opts.delete(:raw)
      @args    = []
      @opts    = opts
    end

    def [](key)
      @opts[key]
    end

    def []=(key, value)
      @opts[key] = value
    end

    def add_option(argument, parameter)
      @args << "--#{argument} #{parameter}"
    end

    def to_iptables
      @args.clear
      @opts.each_pair do |argument, parameter|
        add_option(argument, parameter)
      end

      if comment?
        "#{self.to_command} #{self.comment}"
      else
        self.to_command
      end
    end

    def raw?
      @raw
    end

    def to_command
      if raw?
        @raw
      else
        "iptables #{@args.join(' ')}"
      end
    end

    def comment
      "--match comment --comment '#{id}'"
    end

    def id
      Digest::MD5.hexdigest(self.to_command)
    end

    def comment?
      @comment
    end

    # Display the rule in iptables form, perferably before an update_id has been run
    def to_s
      %("#{to_command}")
    end
  end
end
