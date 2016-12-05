#
# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ript/version"

Gem::Specification.new do |s|
  s.name        = "ript"
  s.version     = Ript::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = [ "Bulletproof Group Ltd" ]
  s.email       = [ "foundation@bulletproof.net" ]
  s.homepage    = "http://bulletproof.net/"
  s.summary     = %q{DSL for iptables, and tool for incrementally applying firewall rules}
  s.description = %q{Ript provides a clean Ruby DSL for describing firewall rules, and implements database migrations-like functionality for applying the rules}

  s.rubyforge_project = "ript"

  s.required_ruby_version     = ">= 1.9.2"
  s.required_rubygems_version = ">= 1.3.6"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  #s.add_runtime_dependency     "colorize",  ">= 0"
  s.add_development_dependency "rake",      ">= 0"
  s.add_development_dependency "rspec",     ">= 0"
  s.add_development_dependency "cucumber",  ">= 1.1.9"
  s.add_development_dependency "aruba",     ">= 0"
  s.add_development_dependency "colorize",  ">= 0"
  s.add_development_dependency "fpm",       ">= 0.4.5"
end
