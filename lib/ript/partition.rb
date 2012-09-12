#!/usr/bin/env ruby

$: << Pathname.new(__FILE__).dirname.parent.expand_path.to_s

module Ript
  class Partition
    attr_reader :name, :filename, :line

    include DSL::Primitives::Common
    include DSL::Primitives::NAT
    include DSL::Primitives::Filter
    include DSL::Primitives::Raw

    def initialize(name, block, options={})
      @filename, @line = caller[2].split(':')[0..1]
      @labels       = {}
      @prerouting   = []
      @postrouting  = []
      @input        = []
      @forward      = []
      @table        = []
      @name         = name
      # TODO should we rename this to no_is or something since that is what it really means
      if options[:rules]
        @raw = true
        @table = options[:rules]
      end

      # Even when suplying our own rules we need the placeholders below to know if anything changed
      @setup = []
      @setup << Rule.new("table" => "nat",    "new-chain" => "#{@name}-d")
      @setup << Rule.new("table" => "nat",    "new-chain" => "#{@name}-s")
      @setup << Rule.new("table" => "filter", "new-chain" => "#{@name}-a")

      # Provide a label for the zero-address
      label "all", :address => "0.0.0.0/0"

      begin
        instance_eval &block unless block.nil?
      rescue NoMethodError => e
        method = e.message[/`(.+)'/, 1]
        filename, line = e.backtrace.first[/(.*):(\d)/].split(':')
        if filename =~ /\/lib\/ript\//
          puts "Looks like you found a bug in Ript around line #{line} in #{filename}"
          puts "Specifically, this is the exception raised:"
          puts
          puts "  #{e.message}"
          puts
          puts "And here is the backtrace:"
          puts
          puts e.backtrace.map {|l| "  #{l}\n" }.join
          puts
          puts "Please report this bug at http://github.com/bulletproofnetworks/ript"
          puts
        else
          puts "You tried using the '#{method}' method on line #{line} in #{filename}"
          similar = self.class.instance_methods.grep(/#{method}/)
          if similar.size > 0
            puts "This method doesn't exist in the DSL. Did you mean:"
            puts
            self.class.instance_methods.grep(/#{method}/).each do |m|
              puts " - #{m}"
            end
            puts
          else
            puts "This method doesn't exist in the DSL. There aren't any other methods with similar names. :-("
          end
        end
        puts "Aborting."
        exit 131
      rescue LabelError => e
        puts e.message
        puts "Aborting."
        exit 131
      end
    end

    # FIXME: Maybe implement the concept of dirtiness?
    def id
      return @id if @id
      joined = (@setup.map       {|rule| rule.to_iptables } +
                @prerouting.map  {|rule| rule.to_iptables }.uniq +
                @postrouting.map {|rule| rule.to_iptables }.uniq +
                @input.map       {|rule| rule.to_iptables }.uniq +
                @forward.map     {|rule| rule.to_iptables }.uniq +
                @table.map       {|rule| rule.to_iptables }.uniq).join(' ')
      @id = "#{Digest::MD5.hexdigest(joined)[0..5]}"
    end

    def update_id(object, key, id)
      object.map { |rule|
        rule[key] += "#{id}" unless rule[key] == "LOG"
        rule.to_iptables
      }
    end

    def to_iptables
      if raw?
        # TODO How do we clean up raw rules?
        puts update_id(@setup,  "new-chain", id).uniq
        puts @table.map {|rule| rule.to_iptables }
        puts
      else
        puts update_id(@setup,  "new-chain", id).uniq
        puts update_id(@table,     "append", id).uniq
        puts update_id(@prerouting,  "jump", id).uniq
        puts update_id(@postrouting, "jump", id).uniq
        puts update_id(@input,       "jump", id).uniq
        puts update_id(@forward,     "jump", id).uniq
        puts
      end
    end
  end
end

@partitions = []
@filenames = []

def partition(name, &block)
  filename, line = caller.first.split(':')[0..1]

  if c = @partitions.find {|c| c.name == name } then
    puts "Error: Partition name '#{name}' is already defined!"
    puts " - existing definition: #{c.filename}:#{c.line}"
    puts " - new definition: #{filename}:#{line}"
    puts "Aborting."
    exit 140
  end

  if name =~ /\s+/
    puts "Error: #{filename}:#{line}"
    puts "Error: Partition name '#{name}' can't contain whitespace."
    puts "Aborting."
    exit 140
  end

  if name.count('-') > 0
    puts "Error: #{filename}:#{line}"
    puts "Error: Partition name '#{name}' can't contain dashes ('-')."
    puts "Aborting."
    exit 140
  end

  if name.length > 20
    puts "Error: #{filename}:#{line}"
    puts "Error: Partition name '#{name}' cannot be longer than 20 characters."
    puts "Aborting."
    exit 140
  end

  if @filenames.include?(filename)
    puts "Error: #{filename}:#{line}"
    puts "Error: Multiple partition definitions are not permitted in the same file."
    puts "Aborting."
    exit 140
  else
    @filenames << filename
  end

  partition = Ript::Partition.new(name, block)
  @partitions << partition
end
