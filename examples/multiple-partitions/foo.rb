partition "foo" do
  label "www.foo.com",   :address => "172.23.0.88", :interface => "vlan44"
  label "foo-web-01",    :address => "192.168.38.1"
  label "stage.foo.com", :address => "172.23.0.90", :interface => "vlan44"
  label "foo-web-02",    :address => "192.168.38.2"

  rewrite "foo.com public website" do
    ports 25, 80, 11, 22 => 9876, 443 => 4443
    dnat  "www.foo.com" =>  "foo-web-01"
  end

  rewrite "foo.com stage website" do
    ports 22 => 9876, 443 => 4443
    dnat  "stage.foo.com" =>  "foo-web-02"
  end
end

