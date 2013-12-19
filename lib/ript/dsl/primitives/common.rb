#!/usr/bin/env ruby

module Ript
  module DSL
    module Primitives
      module Common
        def label(label, opts={})
          @labels[label] = opts
          if opts[:address] =~ /^[0-9.]+$/
            @labels[label][:family] = :ipv4
          elsif opts[:address] =~ /^[0-9a-fA-F:]+$/
            @labels[label][:family] = :ipv6
          else
            # TODO Should we default to IPv4 or should we force a protocol to be specified?
            # For when a hostname is passed?
            @labels[label][:family] ||= :ipv4
          end
        end

        def interface(arg)
          @interface = arg
        end

        def ports(*args)
          if args.class == Array
            args.each do |port|
              if port.class == Range
                @ports << "#{port.begin}:#{port.end}"
              else
                @ports << port
              end
            end
          else
            port = args
            @ports << port
          end
        end

        def from(*label)
          label.flatten!(2)
          if label.is_a?(Array)
            label.each do |l|
              @froms << l
            end
          else
            @froms << label
          end
        end

        def to(*label)
          label.flatten!(2)
          if label.is_a?(Array)
            label.each do |l|
              @tos << l
            end
          else
            @tos << label
          end
        end

        def protocols(*args)
          # FIXME: refactor to just use flatten!
          if args.class == Array
            args.each do |protocol|
              @protocols << protocol
            end
          else
            protocol = args
            @protocols << protocol
          end
        end

        def validate(opts={})
          families = []

          opts.each_pair do |type, label|
            if not label_exists?(label)
              raise LabelError, "Address '#{label}' (a #{type}) isn't defined"
            end
            families << @labels[label][:family]
          end

          if families.uniq.size != 1
            raise FamilyMixError, "Cannot mix IPv4 and IPv6 addresses in a rule: #{opts.map {|a| @labels[a]}}"
          end
        end

        def label_exists?(label)
          @labels.has_key?(label)
        end
      end
    end
  end
end
