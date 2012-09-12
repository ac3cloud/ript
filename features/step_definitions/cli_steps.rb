Before("@timeout-10") do
  @aruba_timeout_seconds = 10
end

Then /^the output from "([^"]*)" should match:$/ do |cmd, partial_output|
  output_from(cmd).should =~ /#{partial_output}/
end

Then /^the output from "([^"]*)" should contain exactly:$/ do |cmd, exact_output|
  output_from(cmd).should == exact_output
end

Given /^I have no iptables rules loaded$/ do
  run_simple("rake clean_slate")
end
