partition "bar" do
  label "www.bar.com",    :address => "172.23.0.95"
  label "barprod-web-01", :address => "192.168.19.2"
  label "barprod-web-02", :address => "192.168.19.4"

  rewrite "bar.com public website" do
    ports 80
    dnat  "www.bar.com" => "barprod-web-01"
  end

  rewrite "bar.com public website" do
    ports 22
    dnat  "www.bar.com" => "barprod-web-02"
  end
end

