partition "bar" do
  label :jamdev,                :address => "192.168.23.70/27"
  label "www.bar.com",          :address => "172.23.0.95"
  label "barprod-blackhole-01", :address => "192.168.27.66"

  rewrite "bar" do
    ports 139 => 2011
    from  :jamdev
    dnat "www.bar.com" => "barprod-blackhole-01"
  end
end
