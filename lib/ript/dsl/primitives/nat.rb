#!/usr/bin/env ruby

module Ript
  module DSL
    module Primitives
      module NAT
        def rewrite(name, opts={}, &block)
          # Reset these so parameters don't leak between calls to forward.
          @sources      = []
          @destinations = []
          @ports        = []
          @protocols    = []
          @tos          = []
          @froms        = []
          log           = opts[:log]

          @snat_sources      = []
          @snat_destinations = []

          # Evaluate the block.
          instance_eval &block

          # Default all rules to apply to TCP packets if no protocol is specified
          @protocols << 'TCP' if @protocols.size == 0

          @snat_sources.zip(@snat_destinations) do |source, destination|
            validate(:source => source, :destination => destination)

            source_address      = @labels[source][:address]
            destination_address = @labels[destination][:address]

            attributes = { "table"  => "nat",
                           "insert" => "partition-s",
                           "source" => source_address,
                           "jump"   => "#{@name}-s" }

            fattributes = { "table"  => "filter",
                            "insert" => "partition-a",
                            "source" => source_address,
                            "jump"   => "#{@name}-a" }

            @postrouting << Rule.new(attributes)
            @postrouting << Rule.new(attributes.merge("jump" => "LOG")) if log
            @input << Rule.new(fattributes)
            @input << Rule.new(fattributes.merge("jump" => "LOG")) if log


            attributes = { "table"     => "nat",
                           "append"    => "#{@name}-s",
                           "source"    => source_address,
                           "jump"      => "SNAT",
                           "to-source" => destination_address }

            fattributes = { "table"       => "filter",
                            "append"      => "#{@name}-a",
                            "source"      => source_address,
                            "jump"        => "ACCEPT" }

            @froms.map {|from| @labels[from][:address]}.each do |address|
              attributes.insert_before("destination", ["source", address])
            end

            @table << Rule.new(attributes.merge("jump" => "LOG")) if log
            @table << Rule.new(attributes)
            @table << Rule.new(fattributes.merge("jump" => "LOG")) if log
            @table << Rule.new(fattributes)
          end


          # Provide a default from address, so the @ports => @protocols => @froms
          # nested iteration below works.
          @froms << 'all' if @froms.size == 0

          # Build up rules based on evaluation.
          @sources.zip(@destinations).each do |source, destination|
            validate(:source => source, :destination => destination)

            source_address      = @labels[source][:address]
            destination_address = @labels[destination][:address]

            attributes = { "table"       => "nat",
                           "insert"      => "partition-d",
                           "destination" => source_address,
                           "jump"        => "#{@name}-d" }

            fattributes = { "table"       => "filter",
                            "insert"      => "partition-a",
                            "destination" => destination_address,
                            "jump"        => "#{@name}-a" }

            @prerouting << Rule.new(attributes)
            @prerouting << Rule.new(attributes.merge("jump" => "LOG")) if log
            @input << Rule.new(fattributes)
            @input << Rule.new(fattributes.merge("jump" => "LOG")) if log

            @ports.each do |port|
              @protocols.each do |protocol|
                @froms.map {|from| @labels[from][:address]}.each do |from_address|
                  if port.class == Hash
                    port.each_pair do |source_port, destination_port|
                      attributes = { "table"          => "nat",
                                     "append"         => "#{@name}-d",
                                     "protocol"       => protocol,
                                     "destination"    => source_address,
                                     "dport"          => source_port,
                                     "jump"           => "DNAT",
                                     "to-destination" => destination_address + ":#{destination_port}" }

                      fattributes = { "table"       => "filter",
                                      "append"      => "#{@name}-a",
                                      "protocol"    => protocol,
                                      "destination" => destination_address,
                                      "dport"       => destination_port,
                                      "jump"        => "ACCEPT" }

                      attributes.insert_before("destination", ["source", from_address]) unless from_address == "0.0.0.0/0"

                      @table << Rule.new(attributes.merge("jump" => "LOG")) if log
                      @table << Rule.new(attributes)
                      @table << Rule.new(fattributes.merge("jump" => "LOG")) if log
                      @table << Rule.new(fattributes)
                    end
                  else
                    attributes = { "table"          => "nat",
                                   "append"         => "#{@name}-d",
                                   "protocol"       => protocol,
                                   "destination"    => source_address,
                                   "dport"          => port,
                                   "jump"           => "DNAT",
                                   "to-destination" => destination_address }

                    fattributes = { "table"       => "filter",
                                    "append"      => "#{@name}-a",
                                    "protocol"    => protocol,
                                    "destination" => destination_address,
                                    "dport"       => port,
                                    "jump"        => "ACCEPT" }

                    attributes.insert_before("destination", ["source" , from_address]) unless from_address == "0.0.0.0/0"

                    @table << Rule.new(attributes.merge("jump" => "LOG")) if log
                    @table << Rule.new(attributes)
                    @table << Rule.new(fattributes.merge("jump" => "LOG")) if log
                    @table << Rule.new(fattributes)
                  end
                end
              end
            end
          end
        end

        def dnat(opts={})
          opts.each_pair do |source, destination|
            # If the source argument to dnat is an Array:
            #
            #     dnat  [ "www.bar.com",
            #             "secure.bar.com",
            #             "static.bar.com"  ] => "barprod-proxy-01"
            #
            # loop through each source, and create the associated destination.
            if source.is_a?(Array)
              source.each do |s|
                @sources << s
                @destinations << destination
              end
            # If the source is just a plain label:
            #
            #     dnat  "www.bar.com" => "barprod-proxy-01"
            #
            # simply add it and the destination to the collection.
            else
              @sources << source
              @destinations << destination
            end
          end
        end

        def snat(opts={})
          opts.each_pair do |source, destination|
            # If the source argument to snat is an Array:
            #
            #     snat  [ "www.bar.com",
            #             "secure.bar.com",
            #             "static.bar.com"  ] => "barprod-proxy-01"
            #
            # loop through each source, and create the associated destination.
            if source.is_a?(Array)
              source.each do |s|
                @snat_sources << s
                @snat_destinations << destination
              end
            # If the source is just a plain label:
            #
            #     snat  "www.bar.com" => "barprod-proxy-01"
            #
            # simply add it and the destination to the collection.
            else
              @snat_sources << source
              @snat_destinations << destination
            end
          end
        end
      end
    end
  end
end
