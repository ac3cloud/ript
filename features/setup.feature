Feature: Ript Setup

  @sudo @timeout-10
  Scenario: Partition chain is set up
    Given I have no iptables rules loaded
    When I run `ript rules diff examples/basic.rb`
    Then the output should match:
      """
      iptables --table filter --new-chain partition-a
      iptables --table filter --insert INPUT 1 --jump partition-a
      iptables --table filter --insert OUTPUT 1 --jump partition-a
      iptables --table filter --insert FORWARD 1 --jump partition-a
      iptables --table nat --new-chain partition-d
      iptables --table nat --insert PREROUTING 1 --jump partition-d
      iptables --table nat --new-chain partition-s
      iptables --table nat --insert POSTROUTING 1 --jump partition-s


      # basic-\w+
      iptables --table nat --new-chain basic-d\w+
      iptables --table nat --new-chain basic-s\w+
      iptables --table filter --new-chain basic-a\w+
      """
    Then the created chain name in all tables should match

  @sudo @timeout-10
  Scenario: Partition chain is only added once
    Given I have no iptables rules loaded
    When I run `ript rules apply examples/basic.rb`
    Then the output from "ript rules apply examples/basic.rb" should match:
      """
      iptables --table filter --new-chain partition-a
      iptables --table filter --insert INPUT 1 --jump partition-a
      iptables --table filter --insert OUTPUT 1 --jump partition-a
      iptables --table filter --insert FORWARD 1 --jump partition-a
      iptables --table nat --new-chain partition-d
      iptables --table nat --insert PREROUTING 1 --jump partition-d
      iptables --table nat --new-chain partition-s
      iptables --table nat --insert POSTROUTING 1 --jump partition-s


      # basic-\w+
      iptables --table nat --new-chain basic-d\w+
      iptables --table nat --new-chain basic-s\w+
      iptables --table filter --new-chain basic-a\w+
      """
    When I run `ript rules apply examples/partition-name-exactly-20-characters.rb`
    Then the output from "ript rules apply examples/partition-name-exactly-20-characters.rb" should contain exactly:
      """
      # name_exactly_20_char-f9964b
      iptables --table nat --new-chain name_exactly_20_char-df9964b
      iptables --table nat --new-chain name_exactly_20_char-sf9964b
      iptables --table filter --new-chain name_exactly_20_char-af9964b



      """
    Then the created chain name in all tables should match
