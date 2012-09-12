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

  @nat @dnat
  Scenario: Basic DNAT forward
    When I run `ript rules generate examples/forward-dnat.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --append bar-d\w+ --protocol TCP --destination 172.23.0.95 --dport 80 --jump DNAT --to-destination 192.168.19.2
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 192.168.19.2 --dport 80 --jump ACCEPT
      """
    Then the output should match:
      """
      iptables --table nat --insert partition-d --destination 172.23.0.95 --jump bar-d\w+
      iptables --table filter --insert partition-a --destination 192.168.19.2 --jump bar-a\w+
      """
    Then the created chain name in all tables should match

  @nat @dnat
  Scenario: DNAT forward with multiple ports
    When I run `ript rules generate examples/forward-dnat-with-multiple-ports.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --insert partition-d --destination 172.23.0.95 --jump bar-d\w+
      """
    Then the output should match:
      """
      iptables --table nat --append bar-d\w+ --protocol TCP --destination 172.23.0.95 --dport 80 --jump DNAT --to-destination 192.168.19.2
      """
    Then the output should match:
      """
      iptables --table nat --append bar-d\w+ --protocol TCP --destination 172.23.0.95 --dport 22 --jump DNAT --to-destination 192.168.19.2
      """
    Then the created chain name in all tables should match

  @nat @dnat
  Scenario: DNAT forward with source port to different destination port
    When I run `ript rules generate examples/forward-dnat-with-different-destination-port.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain foo-d\w+
      iptables --table nat --new-chain foo-s\w+
      iptables --table filter --new-chain foo-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --insert partition-d --destination 172.23.0.88 --jump foo-d\w+
      """
    Then the output should match:
      """
      iptables --table nat --append foo-d\w+ --protocol TCP --destination 172.23.0.88 --dport 22 --jump DNAT --to-destination 192.168.38.1:9876
      """
    Then the output should match:
      """
      iptables --table nat --insert partition-d --destination 172.23.0.90 --jump foo-d\w+
      """
    Then the output should match:
      """
      iptables --table nat --append foo-d\w+ --protocol TCP --destination 172.23.0.90 --dport 22 --jump DNAT --to-destination 192.168.38.2:9876
      iptables --table filter --append foo-a\w+ --protocol TCP --destination 192.168.38.2 --dport 9876 --jump ACCEPT
      iptables --table nat --append foo-d\w+ --protocol TCP --destination 172.23.0.90 --dport 443 --jump DNAT --to-destination 192.168.38.2:4443
      iptables --table filter --append foo-a\w+ --protocol TCP --destination 192.168.38.2 --dport 4443 --jump ACCEPT
      """
    Then the created chain name in all tables should match

  @nat @dnat
  Scenario: DNAT forward for multiple sources
    When I run `ript rules generate examples/forward-dnat-with-multiple-sources.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --append bar-d\w+ --protocol TCP --destination 172.23.0.95 --dport 80 --jump DNAT --to-destination 192.168.27.88
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 192.168.27.88 --dport 80 --jump ACCEPT
      iptables --table nat --append bar-d\w+ --protocol TCP --destination 172.23.0.96 --dport 80 --jump DNAT --to-destination 192.168.27.88
      iptables --table nat --append bar-d\w+ --protocol TCP --destination 172.23.0.97 --dport 80 --jump DNAT --to-destination 192.168.27.88
      """
    Then the output should match:
      """
      iptables --table nat --insert partition-d --destination 172.23.0.95 --jump bar-d\w+
      iptables --table nat --insert partition-d --destination 172.23.0.96 --jump bar-d\w+
      iptables --table nat --insert partition-d --destination 172.23.0.97 --jump bar-d\w+
      iptables --table filter --insert partition-a --destination 192.168.27.88 --jump bar-a\w+
      """
    Then the created chain name in all tables should match

  @nat @dnat
  Scenario: DNAT forward with an explicit from
    When I run `ript rules generate examples/forward-dnat-with-explicit-from.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --append bar-d\w+ --protocol TCP --source 192.168.23.70/27 --destination 172.23.0.95 --dport 80 --jump DNAT --to-destination 192.168.27.66
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 192.168.27.66 --dport 80 --jump ACCEPT
      iptables --table nat --insert partition-d --destination 172.23.0.95 --jump bar-d\w+
      iptables --table filter --insert partition-a --destination 192.168.27.66 --jump bar-a\w+
      """
    Then the created chain name in all tables should match

  @nat @dnat
  Scenario: DNAT forward with multiple froms
    When I run `ript rules generate examples/forward-dnat-with-multiple-froms.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain joeblogsco-d\w+
      iptables --table nat --new-chain joeblogsco-s\w+
      iptables --table filter --new-chain joeblogsco-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --append joeblogsco-d\w+ --protocol TCP --source 1.2.3.4 --destination 172.19.10.99 --dport 80 --jump DNAT --to-destination 192.168.27.66
      iptables --table filter --append joeblogsco-a\w+ --protocol TCP --destination 192.168.27.66 --dport 80 --jump ACCEPT
      iptables --table nat --append joeblogsco-d\w+ --protocol TCP --source 4.5.6.7 --destination 172.19.10.99 --dport 80 --jump DNAT --to-destination 192.168.27.66
      iptables --table nat --append joeblogsco-d\w+ --protocol TCP --source 7.8.9.10 --destination 172.19.10.99 --dport 80 --jump DNAT --to-destination 192.168.27.66
      iptables --table nat --insert partition-d --destination 172.19.10.99 --jump joeblogsco-d\w+
      iptables --table filter --insert partition-a --destination 192.168.27.66 --jump joeblogsco-a\w+
      """
    Then the created chain name in all tables should match

  @nat @dnat
  Scenario: DNAT forward with an explicit from and ports
    When I run `ript rules generate examples/forward-dnat-with-explicit-from-and-ports.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --append bar-d\w+ --protocol TCP --source 192.168.23.70/27 --destination 172.23.0.95 --dport 82 --jump DNAT --to-destination 192.168.27.66
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 192.168.27.66 --dport 82 --jump ACCEPT
      iptables --table nat --insert partition-d --destination 172.23.0.95 --jump bar-d\w+
      iptables --table filter --insert partition-a --destination 192.168.27.66 --jump bar-a\w+
      """
    Then the created chain name in all tables should match

  @nat @dnat
  Scenario: DNAT forward with an explicit from and port mappings
    When I run `ript rules generate examples/forward-dnat-with-explicit-from-and-port-mappings.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --append bar-d\w+ --protocol TCP --source 192.168.23.70/27 --destination 172.23.0.95 --dport 139 --jump DNAT --to-destination 192.168.27.66:2011
      iptables --table filter --append bar-a\w+ --protocol TCP --destination 192.168.27.66 --dport 2011 --jump ACCEPT
      iptables --table nat --insert partition-d --destination 172.23.0.95 --jump bar-d\w+
      iptables --table filter --insert partition-a --destination 192.168.27.66 --jump bar-a\w+
      """
    Then the created chain name in all tables should match

  @nat @dnat
  Scenario: DNAT forward with explicit protocols
    When I run `ript rules generate examples/forward-dnat-with-explicit-protocols.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain cpm-d\w+
      iptables --table nat --new-chain cpm-s\w+
      iptables --table filter --new-chain cpm-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --append cpm-d\w+ --protocol udp --source 172.19.4.55 --destination 172.18.88.33 --dport 53 --jump DNAT --to-destination 192.168.0.133
      iptables --table filter --append cpm-a\w+ --protocol udp --destination 192.168.0.133 --dport 53 --jump ACCEPT
      iptables --table nat --append cpm-d\w+ --protocol tcp --source 172.19.4.55 --destination 172.18.88.33 --dport 53 --jump DNAT --to-destination 192.168.0.133
      iptables --table filter --append cpm-a\w+ --protocol tcp --destination 192.168.0.133 --dport 53 --jump ACCEPT
      iptables --table nat --insert partition-d --destination 172.18.88.33 --jump cpm-d\w+
      iptables --table filter --insert partition-a --destination 192.168.0.133 --jump cpm-a\w+
      """
    Then the created chain name in all tables should match


  @nat @snat
  Scenario: Basic SNAT forward
    When I run `ript rules generate examples/forward-snat.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --append bar-s\w+ --source 10.30.0.0/24 --jump SNAT --to-source 172.23.0.95
      iptables --table filter --append bar-a\w+ --source 10.30.0.0/24 --jump ACCEPT
      iptables --table nat --insert partition-s --source 10.30.0.0/24 --jump bar-s\w+
      iptables --table filter --insert partition-a --source 10.30.0.0/24 --jump bar-a\w+
      """
    Then the created chain name in all tables should match

  @nat @snat
  Scenario: SNAT forward for multiple sources
    When I run `ript rules generate examples/forward-snat-with-multiple-sources.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --append bar-s\w+ --source 10.33.0.0/24 --jump SNAT --to-source 172.23.0.95
      iptables --table filter --append bar-a\w+ --source 10.33.0.0/24 --jump ACCEPT
      iptables --table nat --append bar-s\w+ --source 10.44.0.0/24 --jump SNAT --to-source 172.23.0.95
      iptables --table filter --append bar-a\w+ --source 10.44.0.0/24 --jump ACCEPT
      iptables --table nat --append bar-s\w+ --source 10.55.0.0/24 --jump SNAT --to-source 172.23.0.95
      iptables --table filter --append bar-a\w+ --source 10.55.0.0/24 --jump ACCEPT
      iptables --table nat --insert partition-s --source 10.33.0.0/24 --jump bar-s\w+
      iptables --table nat --insert partition-s --source 10.44.0.0/24 --jump bar-s\w+
      iptables --table nat --insert partition-s --source 10.55.0.0/24 --jump bar-s\w+
      iptables --table filter --insert partition-a --source 10.33.0.0/24 --jump bar-a\w+
      iptables --table filter --insert partition-a --source 10.44.0.0/24 --jump bar-a\w+
      iptables --table filter --insert partition-a --source 10.55.0.0/24 --jump bar-a\w+
      """
    Then the created chain name in all tables should match

  @nat @snat
  Scenario: SNAT forward with an explicit from
    When I run `ript rules generate examples/forward-snat-with-explicit-from.rb`
    Then the output should match:
      """
      iptables --table nat --new-chain bar-d\w+
      iptables --table nat --new-chain bar-s\w+
      iptables --table filter --new-chain bar-a\w+
      """
    Then the output should match:
      """
      iptables --table nat --append bar-s\w+ --source 10.55.0.45 --jump SNAT --to-source 172.24.0.99
      iptables --table filter --append bar-a\w+ --source 10.55.0.45 --jump ACCEPT
      iptables --table nat --append bar-s\w+ --source 10.55.0.0/24 --jump SNAT --to-source 172.23.0.95
      iptables --table filter --append bar-a\w+ --source 10.55.0.0/24 --jump ACCEPT
      iptables --table nat --insert partition-s --source 10.55.0.45 --jump bar-s\w+
      iptables --table nat --insert partition-s --source 10.55.0.0/24 --jump bar-s\w+
      iptables --table filter --insert partition-a --source 10.55.0.45 --jump bar-a\w+
      iptables --table filter --insert partition-a --source 10.55.0.0/24 --jump bar-a\w+
      """
    Then the created chain name in all tables should match
