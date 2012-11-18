#!/usr/bin/env ruby

#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'cucumber'
require 'cucumber/rake/task'
require 'colorize'
require 'pathname'
$: << Pathname.new(__FILE__).join('lib').expand_path.to_s
require 'ript/version'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
end

desc "Build packages for various platforms"
#task :build => [ 'build:gem', 'build:deb' ]
task :build => [ :verify, 'build:gem', 'build:deb' ]

namespace :build do
  desc "Build RubyGem"
  task :gem do
    build_output = `gem build ript.gemspec`
    puts build_output

    gem_filename = build_output[/File: (.*)/,1]
    pkg_path = "pkg"
    FileUtils.mkdir_p(pkg_path)
    FileUtils.mv(gem_filename, pkg_path)

    puts "Gem built at #{pkg_path}/#{gem_filename}".green
  end

  desc "Build a deb for Ubuntu"
  task :deb => :gem do
    gem_filename = "pkg/ript-#{Ript::VERSION}.gem"
    deb_filename = "pkg/ript-#{Ript::VERSION}.deb"
    system("rm -f #{deb_filename}")
    build_output = `fpm -s gem -t deb -p #{deb_filename} #{gem_filename}`

    require 'json'
    json = build_output[/({.+})$/, 1]
    data = JSON.parse(json)
    if path = data["path"]
      puts "Deb built at #{path}".green
    end
  end
end

namespace :verify do
  desc "Verify the CHANGELOG is in order for a release"
  task :changelog do
    changelog_filename = "CHANGELOG.md"
    version = Ript::VERSION
    command = "grep '^# #{version}' #{changelog_filename} 2>&1 >/dev/null"

    if not system(command)
      puts "#{changelog_filename} doesn't have an entry for the version (#{version}) you are about to build.".red
      exit 1
    end
  end

  desc "Verify there are no uncommitted files"
  task :uncommitted do
    uncommitted = `git ls-files -m`.split("\n")
    if uncommitted.size > 0
      puts "The following files are uncommitted:".red
      uncommitted.each do |filename|
        puts " - #{filename}".red
      end
      exit 1
    end
  end

  desc "Verify no requires of RubyGems have snuck in"
  task :no_rubygems do
    requires = `grep rubygems lib/ bin/ -rn |grep require`.split("\n")
    if requires.size > 0
      puts "The following files use RubyGems:".red
      requires.each do |filename|
        puts " - #{filename}".red
      end
      exit 1
    end
  end

  task :all => [ :changelog, :uncommitted, :no_rubygems ]
end

task :verify => 'verify:all'



desc "Clean out the state of iptables"
task :clean_slate do
  # Clean filter
  system("sudo iptables --flush --table filter")
  system("sudo iptables --delete-chain --table filter")
  system("sudo iptables --table filter --policy INPUT ACCEPT")
  system("sudo iptables --table filter --policy FORWARD ACCEPT")
  system("sudo iptables --table filter --policy OUTPUT ACCEPT")

  # Clean NAT
  system("sudo iptables --flush --table nat")
  system("sudo iptables --delete-chain --table nat")
  system("sudo iptables --table nat --policy PREROUTING ACCEPT")
  system("sudo iptables --table nat --policy POSTROUTING ACCEPT")
  system("sudo iptables --table nat --policy OUTPUT ACCEPT")

  # Clean mangle
  system("sudo iptables --flush --table mangle")
  system("sudo iptables --delete-chain --table mangle")
  system("sudo iptables --table mangle --policy PREROUTING ACCEPT")
  system("sudo iptables --table mangle --policy POSTROUTING ACCEPT")
  system("sudo iptables --table mangle --policy INPUT ACCEPT")
  system("sudo iptables --table mangle --policy FORWARD ACCEPT")
  system("sudo iptables --table mangle --policy OUTPUT ACCEPT")

  # Verify
  puts "### FILTER ###"
  system("sudo iptables --list --table filter")
  puts

  puts "### NAT ###"
  system("sudo iptables --list --table nat")
  puts

  puts "### MANGLE ###"
  system("sudo iptables --list --table mangle")
  puts
end



