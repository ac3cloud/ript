Feature: Ript cli utility

  @sudo @timeout-10
  Scenario: Check rules to apply
    Given I have no iptables rules loaded
    When I run `ript rules diff examples/basic.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain basic-d\w+
      iptables --table nat --new-chain basic-s\w+
      iptables --table filter --new-chain basic-a\w+
      """
    Then the created chain name in all tables should match

  @sudo @timeout-10
  Scenario: Apply rules
    Given I have no iptables rules loaded
    When I run `ript rules diff examples/basic.rb`
    Then the output from "ript rules diff examples/basic.rb" should match:
      """
      iptables --table nat --new-chain basic-d\w+
      iptables --table nat --new-chain basic-s\w+
      iptables --table filter --new-chain basic-a\w+
      """
    When I run `ript rules apply examples/basic.rb`
    Then the output from "ript rules diff examples/basic.rb" should match:
      """
      iptables --table nat --new-chain basic-d\w+
      iptables --table nat --new-chain basic-s\w+
      iptables --table filter --new-chain basic-a\w+
      """
    When I run `ript rules diff examples/basic.rb `
    Then the output from "ript rules diff examples/basic.rb " should contain exactly:
      """
      """
    Then the created chain name in all tables should match

  @sudo @timeout-10
  Scenario: Clean rules
    Given I have no iptables rules loaded
    When I run `ript rules apply examples/preclean.rb`
    Then the output from "ript rules apply examples/preclean.rb" should match:
      """
      iptables --table filter --new-chain partition-a
      iptables --table filter --insert INPUT 1 --jump partition-a
      iptables --table filter --insert OUTPUT 1 --jump partition-a
      iptables --table filter --insert FORWARD 1 --jump partition-a
      iptables --table nat --new-chain partition-d
      iptables --table nat --insert PREROUTING 1 --jump partition-d
      iptables --table nat --new-chain partition-s
      iptables --table nat --insert POSTROUTING 1 --jump partition-s


      # supercow-\w+
      iptables --table nat --new-chain supercow-d\w+
      iptables --table nat --new-chain supercow-s\w+
      iptables --table filter --new-chain supercow-a\w+
      iptables --table filter --append supercow-a\w+ --protocol TCP --destination 172.29.2.2 --source 172.27.1.1 --jump ACCEPT
      iptables --table filter --insert partition-a --destination 172.29.2.2 --jump supercow-a\w+
      """
    When I run `ript rules apply examples/postclean.rb`
    Then the output from "ript rules apply examples/postclean.rb" should match:
      """
      # supercow-\w+
      iptables --table nat --new-chain supercow-d\w+
      iptables --table nat --new-chain supercow-s\w+
      iptables --table filter --new-chain supercow-a\w+
      iptables --table filter --append supercow-a\w+ --protocol TCP --destination 172.29.2.3 --source 172.27.1.2 --jump ACCEPT
      iptables --table filter --insert partition-a --destination 172.29.2.3 --jump supercow-a\w+
      """
    When I run `ript rules diff examples/postclean.rb`
    Then the output from "ript rules diff examples/postclean.rb" should contain exactly:
      """
      """
    When I run `ript clean apply examples/postclean.rb `
    Then the output from "ript clean apply examples/postclean.rb " should match:
      """
      iptables --table filter --delete partition-a --destination 172.29.2.2/32 --jump supercow-a\w+
      iptables --table filter --flush supercow-a\w+
      iptables --table filter --delete-chain supercow-a\w+
      iptables --table nat --flush supercow-d\w+
      iptables --table nat --delete-chain supercow-d\w+
      iptables --table nat --flush supercow-s\w+
      iptables --table nat --delete-chain supercow-s\w+
      """
   When I run `ript clean diff examples/postclean.rb`
   Then the output from "ript clean diff examples/postclean.rb" should contain exactly:
      """
      """

  @sudo @timeout-10
  Scenario: raw rules should only apply once
    Given I have no iptables rules loaded
    When I run `ript rules apply examples/raw.rb`
    Then the output from "ript rules apply examples/raw.rb" should match:
      """
      iptables --new-chain before-a
      """
    When I run `ript rules diff examples/raw.rb`
    Then the output from "ript rules diff examples/raw.rb" should contain exactly:
      """
      """

  @sudo @timeout-10
  Scenario: Rule saving works
    Given I have no iptables rules loaded
    When I run `ript rules save`
    Then the output from "ript rules save" should match:
      """
      \*filter
      :INPUT ACCEPT \[\d+:\d+\]
      :FORWARD ACCEPT \[\d+:\d+\]
      :OUTPUT ACCEPT \[\d+:\d+\]
      COMMIT
      """

  @sudo @timeout-10
  Scenario: Flush rules
    Given I have no iptables rules loaded
    When I run `ript rules flush`
    Then the output from "ript rules flush" should match:
      """
        iptables --flush --table filter
        iptables --delete-chain --table filter
        iptables --table filter --policy INPUT ACCEPT
        iptables --table filter --policy FORWARD ACCEPT
        iptables --table filter --policy OUTPUT ACCEPT

        # Clean NAT
        iptables --flush --table nat
        iptables --delete-chain --table nat
        iptables --table nat --policy PREROUTING ACCEPT
        iptables --table nat --policy POSTROUTING ACCEPT
        iptables --table nat --policy OUTPUT ACCEPT

        # Clean mangle
        iptables --flush --table mangle
        iptables --delete-chain --table mangle
        iptables --table mangle --policy PREROUTING ACCEPT
        iptables --table mangle --policy POSTROUTING ACCEPT
        iptables --table mangle --policy INPUT ACCEPT
        iptables --table mangle --policy FORWARD ACCEPT
        iptables --table mangle --policy OUTPUT ACCEPT
      """
