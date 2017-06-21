#!/usr/bin/env ruby

module Ript
  module DSL
    module Primitives
      module Common
        def label(label, opts={})
          @labels[label] = opts
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
                if not port.is_a? Numeric
                  raise PortError, "Port #{port} is not numeric cannot continue"
                end
                @ports << port
              end
            end
          else
            if not args.is_a? Numeric
              raise PortError, "Port #{args} is not numeric cannot continue"
            end
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
          opts.each_pair do |type, label|
            if not label_exists?(label)
              raise LabelError, "Address '#{label}' (a #{type}) isn't defined"
            end
          end
        end

        def label_exists?(label)
          @labels.has_key?(label)
        end
      end
    end
  end
end
