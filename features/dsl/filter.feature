Feature: Ript DSL

  Scenario: Basic partition
    When I run `ript rules generate examples/basic.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain basic-d\w+
      iptables --table nat --new-chain basic-s\w+
      iptables --table filter --new-chain basic-a\w+
      """
    Then the created chain name in all tables should match

  @filter @drop
  Scenario: Drop someone
    When I run `ript rules generate examples/drop.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --insert partition-a --destination 172.23.0.95 --jump bar-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 172.23.0.95 --source 127.0.0.1 --jump DROP
      """
    Then the created chain name in all tables should match

  @filter @accept
  Scenario: Accept someone
    When I run `ript rules generate examples/accept.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain keepalived-d\w+
      iptables --table nat --new-chain keepalived-s\w+
      iptables --table filter --new-chain keepalived-a\w+
      iptables6 --table nat --new-chain keepalived-d\w+
      iptables6 --table nat --new-chain keepalived-s\w+
      iptables6 --table filter --new-chain keepalived-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --insert partition-a --destination 224.0.0.0/8 --jump keepalived-a\w+
      iptables6 --table filter --insert partition-a --destination FF02:0:0:0:0:0:0:12 --jump keepalived-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --append keepalived-a\w+ --protocol vrrp --destination 224.0.0.0/8 --source 172.16.0.216 --jump ACCEPT
      iptables --table filter --append keepalived-a\w+ --protocol vrrp --destination 224.0.0.0/8 --source 172.16.0.217 --jump ACCEPT
      iptables6 --table filter --append keepalived-a\w+ --protocol vrrp --destination FF02:0:0:0:0:0:0:12 --source 2001:db8::01 --jump ACCEPT
      iptables6 --table filter --append keepalived-a\w+ --protocol vrrp --destination FF02:0:0:0:0:0:0:12 --source 2001:db8::02 --jump ACCEPT
      """
    Then the created chain name in all tables should match

  @filter @accept
  Scenario: Accept someone with a specific port and interface
    When I run `ript rules generate examples/accept-with-specific-port-and-interface.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain keepalived-d\w+
      iptables --table nat --new-chain keepalived-s\w+
      iptables --table filter --new-chain keepalived-a\w+
      iptables6 --table nat --new-chain keepalived-d\w+
      iptables6 --table nat --new-chain keepalived-s\w+
      iptables6 --table filter --new-chain keepalived-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --insert partition-a --destination 192.168.0.76 --jump keepalived-a\w+
      iptables6 --table filter --insert partition-a --destination 2001:db8::03 --jump keepalived-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --append keepalived-a\w+ --in-interface vlan\+ --protocol tcp --dport 22 --destination 192.168.0.76 --source 192.168.0.76 --jump ACCEPT
      """
    Then the output should match:
      """
      iptables6 --table filter --append keepalived-a\w+ --in-interface vlan\+ --protocol tcp --dport 22 --destination 2001:db8::03 --source 2001:db8::03 --jump ACCEPT
      """
    Then the created chain name in all tables should match

  @filter @reject
  Scenario: Reject someone
    When I run `ript rules generate examples/reject.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --insert partition-a --destination 172.23.0.95 --jump bar-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 172.23.0.95 --source 127.0.0.1 --jump REJECT
      """
    Then the created chain name in all tables should match

  @filter @log
  Scenario: Log someone
    When I run `ript rules generate examples/log.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --insert partition-a --destination 172.23.0.95 --jump bar-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 172.23.0.95 --source 127.0.0.1 --jump LOG
      """
    Then the created chain name in all tables should match

  @filter @accept @port-range
  Scenario: Accept a list of ports
    When I run `ript rules generate examples/accept-with-a-list-of-ports.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain keepalived-d\w+
      iptables --table nat --new-chain keepalived-s\w+
      iptables --table filter --new-chain keepalived-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --insert partition-a --destination 224.0.0.0/8 --jump keepalived-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --append keepalived-a\w+ --protocol tcp --dport 80 --destination 224.0.0.0/8 --source 172.16.0.216 --jump ACCEPT
      iptables --table filter --append keepalived-a\w+ --protocol tcp --dport 8600:8900 --destination 224.0.0.0/8 --source 172.16.0.216 --jump ACCEPT
      """
    Then the created chain name in all tables should match

  @filter @accept @multiple
  Scenario: Accept multiple from and to
    When I run `ript rules generate examples/accept-multiple-from-and-to.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain tootyfruity-d\w+
      iptables --table nat --new-chain tootyfruity-s\w+
      iptables --table filter --new-chain tootyfruity-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --insert partition-a --destination 192.168.0.1 --jump tootyfruity-a\w+
      iptables --table filter --insert partition-a --destination 192.168.0.2 --jump tootyfruity-a\w+
      iptables --table filter --insert partition-a --destination 192.168.0.3 --jump tootyfruity-a\w+
      iptables --table filter --insert partition-a --destination 192.168.0.4 --jump tootyfruity-a\w+
      iptables --table filter --insert partition-a --destination 192.168.0.5 --jump tootyfruity-a\w+
      iptables --table filter --insert partition-a --destination 192.168.0.6 --jump tootyfruity-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --append tootyfruity-a\w+ --protocol tcp --dport 22 --destination 192.168.0.1 --source 192.168.0.1 --jump ACCEPT
      iptables --table filter --append tootyfruity-a\w+ --protocol tcp --dport 22 --destination 192.168.0.2 --source 192.168.0.1 --jump ACCEPT
      iptables --table filter --append tootyfruity-a\w+ --protocol tcp --dport 22 --destination 192.168.0.3 --source 192.168.0.1 --jump ACCEPT
      iptables --table filter --append tootyfruity-a\w+ --protocol tcp --dport 22 --destination 192.168.0.4 --source 192.168.0.1 --jump ACCEPT
      iptables --table filter --append tootyfruity-a\w+ --protocol tcp --dport 22 --destination 192.168.0.5 --source 192.168.0.1 --jump ACCEPT
      iptables --table filter --append tootyfruity-a\w+ --protocol tcp --dport 22 --destination 192.168.0.6 --source 192.168.0.1 --jump ACCEPT
      iptables --table filter --append tootyfruity-a\w+ --protocol tcp --dport 22 --destination 192.168.0.1 --source 192.168.0.2 --jump ACCEPT
      iptables --table filter --append tootyfruity-a\w+ --protocol tcp --dport 22 --destination 192.168.0.2 --source 192.168.0.2 --jump ACCEPT
      iptables --table filter --append tootyfruity-a\w+ --protocol tcp --dport 22 --destination 192.168.0.3 --source 192.168.0.2 --jump ACCEPT
      iptables --table filter --append tootyfruity-a\w+ --protocol tcp --dport 22 --destination 192.168.0.4 --source 192.168.0.2 --jump ACCEPT
      iptables --table filter --append tootyfruity-a\w+ --protocol tcp --dport 22 --destination 192.168.0.5 --source 192.168.0.2 --jump ACCEPT
      iptables --table filter --append tootyfruity-a\w+ --protocol tcp --dport 22 --destination 192.168.0.6 --source 192.168.0.2 --jump ACCEPT
      """
    Then the created chain name in all tables should match

  @filter @accept @regression
  Scenario: Accept someone without a specific from
    When I run `ript rules generate examples/accept-without-specific-from.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain joeblogsco-d\w+
      iptables --table nat --new-chain joeblogsco-s\w+
      iptables --table filter --new-chain joeblogsco-a\w+
      """
    Then the output should match:
      """
      iptables --table filter --append joeblogsco-a\w+ --protocol TCP --dport 80 --destination 172.22.111.99 --source 0.0.0.0/0 --jump ACCEPT
      iptables --table filter --append joeblogsco-a\w+ --protocol TCP --dport 443 --destination 172.22.111.99 --source 0.0.0.0/0 --jump ACCEPT
      """
    Then the output should match:
      """
      iptables --table filter --insert partition-a --destination 172.22.111.99 --jump joeblogsco-a\w+
      """
    Then the created chain name in all tables should match

  @filter @regression
  Scenario: Always include protocol when specifying port
    When I generate rules for packet filtering
    Then I should see a protocol specified when a port is specified
