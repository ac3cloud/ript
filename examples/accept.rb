partition "keepalived" do
  label "primary lvs",    :address => "172.16.0.216"
  label "secondary lvs",  :address => "172.16.0.217"
  label "fw multicast",  :address => "224.0.0.0/8"

  accept "keepalive chatter on the fw multicast" do
    protocols "vrrp"
    from      "primary lvs", "secondary lvs"
    to        "fw multicast"
  end
end

