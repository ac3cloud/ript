Feature: Logging
  When debugging complex problems
  A user may want to know
  If certain rules are being used

  @log @filter @accept
  Scenario: Log and accept
    When I run `ript rules generate examples/log-and-accept.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain keepalived-d\w+
      iptables --table nat --new-chain keepalived-s\w+
      iptables --table filter --new-chain keepalived-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --insert partition-a --destination 224.0.0.0/8 --jump keepalived-a\w+
      iptables --table filter --insert partition-a --destination 224.0.0.0/8 --jump LOG
      """
    Then the output should match:
      """
      iptables --table filter --append keepalived-a\w+ --protocol vrrp --destination 224.0.0.0/8 --source 172.16.0.216 --jump LOG
      iptables --table filter --append keepalived-a\w+ --protocol vrrp --destination 224.0.0.0/8 --source 172.16.0.216 --jump ACCEPT
      iptables --table filter --append keepalived-a\w+ --protocol vrrp --destination 224.0.0.0/8 --source 172.16.0.217 --jump LOG
      iptables --table filter --append keepalived-a\w+ --protocol vrrp --destination 224.0.0.0/8 --source 172.16.0.217 --jump ACCEPT
      """
    Then the created chain name in all tables should match

  @log @filter @drop
  Scenario: Log and drop
    When I run `ript rules generate examples/log-and-drop.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --insert partition-a --destination 172.23.0.95 --jump bar-a\w+
      iptables --table filter --insert partition-a --destination 172.23.0.95 --jump LOG
      """
    Then the output should match:
      """
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 172.23.0.95 --source 127.0.0.1 --jump LOG
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 172.23.0.95 --source 127.0.0.1 --jump DROP
      """
    Then the created chain name in all tables should match

  @log @nat @dnat
  Scenario: Logging complex DNAT
    When I run `ript rules generate examples/log-dnat.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --insert partition-d --destination 172.23.0.95 --jump bar-d\w+
      iptables --table nat --insert partition-d --destination 172.23.0.95 --jump LOG
      """
    Then the output should match:
      """
      iptables --table nat --append bar-d\w+ --protocol TCP --destination 172.23.0.95 --dport 80 --jump LOG --to-destination 192.168.19.2
      iptables --table nat --append bar-d\w+ --protocol TCP --destination 172.23.0.95 --dport 80 --jump DNAT --to-destination 192.168.19.2
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 192.168.19.2 --dport 80 --jump LOG
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 192.168.19.2 --dport 80 --jump ACCEPT
      iptables --table nat --append bar-d\w+ --protocol TCP --destination 172.23.0.95 --dport 22 --jump LOG --to-destination 192.168.19.2
      iptables --table nat --append bar-d\w+ --protocol TCP --destination 172.23.0.95 --dport 22 --jump DNAT --to-destination 192.168.19.2
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 192.168.19.2 --dport 22 --jump LOG
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 192.168.19.2 --dport 22 --jump ACCEPT
      """
    Then the created chain name in all tables should match

  @log @nat @snat
  Scenario: Logging complex SNAT
    When I run `ript rules generate examples/log-snat.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --append bar-s\w+ --source 10.33.0.0/24 --jump LOG --to-source 172.23.0.95
      iptables --table nat --append bar-s\w+ --source 10.33.0.0/24 --jump SNAT --to-source 172.23.0.95
      iptables --table filter --append bar-a\w+ --source 10.33.0.0/24 --jump LOG
      iptables --table filter --append bar-a\w+ --source 10.33.0.0/24 --jump ACCEPT
      iptables --table nat --append bar-s\w+ --source 10.44.0.0/24 --jump LOG --to-source 172.23.0.95
      iptables --table nat --append bar-s\w+ --source 10.44.0.0/24 --jump SNAT --to-source 172.23.0.95
      iptables --table filter --append bar-a\w+ --source 10.44.0.0/24 --jump LOG
      iptables --table filter --append bar-a\w+ --source 10.44.0.0/24 --jump ACCEPT
      iptables --table nat --append bar-s\w+ --source 10.55.0.0/24 --jump LOG --to-source 172.23.0.95
      iptables --table nat --append bar-s\w+ --source 10.55.0.0/24 --jump SNAT --to-source 172.23.0.95
      iptables --table filter --append bar-a\w+ --source 10.55.0.0/24 --jump LOG
      iptables --table filter --append bar-a\w+ --source 10.55.0.0/24 --jump ACCEPT
      iptables --table nat --insert partition-s --source 10.33.0.0/24 --jump bar-s\w+
      iptables --table nat --insert partition-s --source 10.33.0.0/24 --jump LOG
      iptables --table nat --insert partition-s --source 10.44.0.0/24 --jump bar-s\w+
      iptables --table nat --insert partition-s --source 10.44.0.0/24 --jump LOG
      iptables --table nat --insert partition-s --source 10.55.0.0/24 --jump bar-s\w+
      iptables --table nat --insert partition-s --source 10.55.0.0/24 --jump LOG
      iptables --table filter --insert partition-a --source 10.33.0.0/24 --jump bar-a\w+
      iptables --table filter --insert partition-a --source 10.33.0.0/24 --jump LOG
      iptables --table filter --insert partition-a --source 10.44.0.0/24 --jump bar-a\w+
      iptables --table filter --insert partition-a --source 10.44.0.0/24 --jump LOG
      iptables --table filter --insert partition-a --source 10.55.0.0/24 --jump bar-a\w+
      iptables --table filter --insert partition-a --source 10.55.0.0/24 --jump LOG
      """
    Then the created chain name in all tables should match

