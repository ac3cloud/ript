#!/usr/bin/env ruby

module Ript
  module DSL
    module Primitives
      module Raw

        def raw?
          @raw
        end

        def raw(rules)
          @raw = true
          commands = rules.split("\n").reject {|l| l !~ /^\s*[^#]+$/}

          commands.each do |command|
            validate_destructiveness(command)

            attributes = {:raw => command}

            @table << Rule.new(attributes)
          end
        end

        private
        def validate_destructiveness(command)
          if command =~ /(\-F|\-\-flush)/
            puts "Error: partition #{@name} - you can't use raw rules that flush tables or chains!"
            puts "Offending rule:\n\n  #{command}\n\n"
            puts "Exiting."
            exit 140
          end

          if command =~ /\s+(\-X|\-\-delete-chain)/
            puts "Error: partition #{@name} - you can't use raw rules that delete chains!"
            puts "Offending rule:\n\n  #{command}\n\n"
            puts "Exiting."
            exit 140
          end
        end
      end
    end
  end
end

