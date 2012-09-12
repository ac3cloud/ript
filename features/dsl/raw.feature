Feature: Raw iptables rules
  When implementing firewalls in complex environments
  Sometimes an operator needs a more precise vocabulary
  To express non-partition specific rules

  @raw
  Scenario: Raw rules
    When I run `ript rules generate examples/raw.rb`
    Then the output should match:
      """
      # setup-\w+
      """
    #Then the created chain name in all tables should match

  @raw @error
  Scenario: Raw rules validation
    When I run `ript rules generate examples/raw-with-flush.rb`
    Then the output should match:
      """
      Error: partition boilerplate - you can't use raw rules that flush tables or chains!
      """
    When I run `ript rules generate examples/raw-with-chain-deletion.rb`
    Then the output should match:
      """
      Error: partition boilerplate - you can't use raw rules that delete chains!
      """
    #Then the created chain name in all tables should match

