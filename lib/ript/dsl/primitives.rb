#!/usr/bin/env ruby
$: << Pathname.new(__FILE__).dirname.parent.parent.expand_path.to_s

require 'ript/dsl/primitives/common'
require 'ript/dsl/primitives/nat'
require 'ript/dsl/primitives/filter'
require 'ript/dsl/primitives/raw'
