partition "bar" do
  label :jamdev,            :address => "192.168.23.70/27"

  label "www.bar.com",      :address => "172.23.0.95"
  label "secure.bar.com",   :address => "172.23.0.96"
  label "static.bar.com",   :address => "172.23.0.97"
  label "barprod-proxy-01", :address => "192.168.27.88"

  rewrite "bar" do
    ports 80
    dnat  [ "www.bar.com",
            "secure.bar.com",
            "static.bar.com"  ] => "barprod-proxy-01"
  end
end
