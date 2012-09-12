partition "setup" do
  raw <<-RAW
####################
#      policy      #
####################
iptables --policy INPUT DROP
iptables --policy OUTPUT DROP
iptables --policy FORWARD DROP
iptables --table mangle --policy PREROUTING ACCEPT
iptables --table mangle --policy OUTPUT ACCEPT

####################
#      before      #
####################
# Clean all traffic by sending it through a "before" chain.
iptables --new-chain before-a

iptables --insert INPUT 1 --jump before-a
iptables --insert OUTPUT 1 --jump before-a
iptables --insert FORWARD 1 --jump before-a

# ICMP cleaning
iptables --append before-a --protocol ICMP --icmp-type echo-reply --jump ACCEPT
iptables --append before-a --protocol ICMP --icmp-type destination-unreachable --jump ACCEPT
iptables --append before-a --protocol ICMP --icmp-type source-quench --jump ACCEPT
iptables --append before-a --protocol ICMP --icmp-type echo-request --jump ACCEPT
iptables --append before-a --protocol ICMP --icmp-type time-exceeded --jump ACCEPT
iptables --append before-a --protocol ICMP --icmp-type parameter-problem --jump ACCEPT
iptables --append before-a --protocol ICMP --jump LOG --log-prefix "INVALID_ICMP " --log-level debug
iptables --append before-a --protocol ICMP --jump DROP

# State cleaning
iptables --append before-a --match state --state INVALID --jump LOG --log-prefix "INVALID_STATE " --log-level debug
iptables --append before-a --match state --state INVALID --jump DROP
iptables --append before-a --protocol TCP --match state --state ESTABLISHED,RELATED --jump ACCEPT
iptables --append before-a --protocol UDP --match state --state ESTABLISHED,RELATED --jump ACCEPT

# Allow loopback
iptables --insert before-a --protocol ALL --in-interface lo --jump ACCEPT
iptables --insert before-a --protocol ALL --out-interface lo --jump ACCEPT

####################
#      after       #
####################
# Clean all traffic by sending it through an "after" chain.
iptables --new-chain after-a
iptables --append after-a --jump LOG --log-prefix "END_DROP " --log-level debug
  RAW
end

