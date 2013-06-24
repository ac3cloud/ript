Before do
  rules_src  = File.join(File.dirname(__FILE__), '..', '..', 'examples', '.')
  rules_dest = File.join(current_dir, 'examples')
  FileUtils.mkdir_p(rules_dest)
  FileUtils.cp_r(rules_src, rules_dest)
end

Then /^the created chain name in all tables should match$/ do
  lines = all_output.split("\n")

  lines.each do |line|
    @chain_names ||= []
    if line =~ /^# /
      @chain_name = line[2..-1]
      @chain_names = ['s', 'd', 'a'].map { |table| client, hash = @chain_name.split(/-/); "#{client}-#{table}#{hash}" }
    end

    next if line.size == 0
    next if line =~ /--(new-chain|jump) partition-/
    next if line =~ /--(new-chain|jump) ript_bootstrap-/
    next if line =~ /^\(in \/.*\)$/ # Exclude rake output from clean_slate

    line.should match(%r{(^\# #{@chain_name})|(#{@chain_names.join('|')})}) if line !~ /LOG/
  end
end

When /^I generate rules for packet filtering$/ do
  examples_path = Pathname.new(__FILE__).parent.parent.parent.join('examples')

  examples = Dir.glob("#{examples_path}/{accept,drop,reject,log}*.rb")
  examples.each do |example|
    run_simple("ript rules generate #{example}")
    commands = all_output.split("\n").find_all {|line| line =~ /^iptables/ }

    @all_outputs ||= []
    @all_outputs += commands
  end
end

Then /^I should see a protocol specified when a port is specified$/ do
  dports = @all_outputs.find_all {|line| line =~ /dport/}
  dports.each do |command|
    command.should =~ / --protocol /
  end
end
