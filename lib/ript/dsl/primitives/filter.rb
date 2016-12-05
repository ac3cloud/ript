#!/usr/bin/env ruby

module Ript
  module DSL
    module Primitives
      module Filter
        # Accept traffic to/from a destination/source.
        #
        # This allows traffic for a particular port/protocol to be passed into
        # userland on the local machine.
        def accept(name, opts={}, &block)
          opts.merge!(:jump => "ACCEPT")
          build_rule(name, block, opts)
        end

        # Reject traffic to/from a destination/source.
        #
        # Send an error packet back for traffic that matches.
        def reject(name, opts={}, &block)
          opts.merge!(:jump => "REJECT")
          build_rule(name, block, opts)
        end

        # Drop traffic to/from a destination/source.
        #
        # Silently drop packets that match.
        def drop(name, opts={}, &block)
          opts.merge!(:jump => "DROP")
          build_rule(name, block, opts)
        end

        # Log traffic to/from a destination/source.
        #
        # Log packets that match via the kernel log (read with dmesg or syslog).
        def log(name, opts={}, &block)
          opts.merge!(:jump => "LOG")
          build_rule(name, block, opts)
        end

        private
        # Construct a rule to be applied to the `filter` table.
        #
        # This method is used to construct simple rules on the filter table to
        # accept/reject/drop/log traffic to and from various addresses.
        #
        # Accepts a block of the actual rule definition to evaluate, and
        # appends the generated rule to the @table instance variable on the
        # partition instance.
        #
        # This method returns nothing.
        #
        def build_rule(name, block, opts={})
          @froms     = []
          @tos       = []
          @ports     = []
          @protocols = []
          insert     = opts[:insert] || "partition-a"
          jump       = opts[:jump]   || "DROP"
          log        = opts[:log]

          # Evaluate the block.
          instance_eval &block

          # Default all rules to apply to TCP packets if no protocol is specified
          @protocols << 'TCP' if @protocols.size == 0

          @protocols.map! {|protocol| {"protocol" => protocol} }
          @ports.map!     {|port| {"dport" => port} }

          # Provide a default from address, so the @ports => @protocols => @froms
          # nested iteration below works.
          @froms << 'all' if @froms.size == 0

          @froms.each do |from|
            @tos.each do |to|
              validate(:from => from, :to => to)

              from_address  = @labels[from][:address]
              to_address    = @labels[to][:address]

              attributes = {
                             "table"       => "filter",
                             "insert"      => insert,
                             "destination" => to_address,
                             "jump"        => "#{@name}-a",
                           }
              @input << Rule.new(attributes)
              @input << Rule.new(attributes.merge("jump" => "LOG")) if log

              attributes = {
                             "table"       => "filter",
                             "append"      => "#{@name}-a",
                             "destination" => to_address,
                             "source"      => from_address,
                             "jump"        => jump
                           }
              attributes.insert_before("destination", [ "in-interface", @interface ]) if @interface
              # Build up a list of arguments we need to build expanded rules.
              #
              # This allows us to expand shorthand definitions like:
              #
              #   accept "multiple rules in one" do
              #     from "foo", "bar", "baz"
              #     to   "spoons"
              #   end
              #
              # ... into multiple rules, one ACCEPT rule for foo, bar, baz.
              #
              case
              when @ports.size > 0 && @protocols.size > 0
                # build the rules based on the arguments supplied
                arguments = @protocols.product(@ports).map {|ary| ary.inject(:merge) }
              when @ports.size == 0 && @protocols.size > 0
                arguments = @protocols
              when @protocols.size == 0 && @ports.size > 0
                arguments = @ports
              else
                arguments = []
              end

              # If we have arguments, iterate through them
              if arguments.size > 0
                arguments.each do |options|
                    options.each_pair do |key, value|
                      supported_protocols = IO.readlines("/etc/protocols")
                      ignored_values = %w(all tcp udp)
                      supported_protocols.map! {|proto| proto.split("\t")[0] }
                      if key == "protocol" and value.instance_of?(String) and !ignored_values.include? value.downcase and value != "" and !supported_protocols.include? value
                              puts "Invalid protocol a) #{value} specified cannot continue"
                              exit
                      end 
                      if value.is_a? Array
                        value.each do |valueout|
                          if !ignored_values.include? valueout.downcase and !supported_protocols.include? valueout
                            puts "Invalid protocol b) #{valueout} specified cannot continue"
                            exit 100 
                          end 
                          attributes = attributes.dup # avoid overwriting existing hash values from previous iterations
                          attributes.insert_before("destination", [ key,  valueout ])
                          @table << Rule.new(attributes.merge("jump" => "LOG")) if log 
                          @table << Rule.new(attributes)
                        end 
                        return
                      else
                      attributes = attributes.dup # avoid overwriting existing hash values from previous iterations
                      attributes.insert_before("destination", [ key,  value ])
                    end 
                  end 
                  @table << Rule.new(attributes.merge("jump" => "LOG")) if log 
                  @table << Rule.new(attributes)
                end 
              else
                @table << Rule.new(attributes.merge("jump" => "LOG")) if log 
                @table << Rule.new(attributes)
              end # if
            end # @tos.each
          end # @froms.each
        end # def build_rule
      end
    end
  end
end
