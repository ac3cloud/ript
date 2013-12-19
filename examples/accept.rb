partition "keepalived" do
  label "primary lvs",    :address => "172.16.0.216"
  label "secondary lvs",  :address => "172.16.0.217"
  label "fw multicast",  :address => "224.0.0.0/8"

  accept "keepalive chatter on the fw multicast" do
    protocols "vrrp"
    from      "primary lvs", "secondary lvs"
    to        "fw multicast"
  end

  label "primary lvs ipv6",    :address => "2001:db8::01"
  label "secondary lvs ipv6",  :address => "2001:db8::02"
  label "fw multicast ipv6",        :address => "FF02:0:0:0:0:0:0:12"

  accept "keepalive chatter on the fw multicast ipv6" do
    protocols "vrrp"
    from      "primary lvs ipv6", "secondary lvs ipv6"
    to        "fw multicast ipv6"
  end
end
