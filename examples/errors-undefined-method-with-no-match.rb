partition "keepalived" do
  label "foobar-lvs-04", :address => "192.168.0.76"
  label "util-01",       :address => "172.16.0.246"
  label "util-02",       :address => "172.16.0.247"

  accept "ssh access between lvs/firewalls with incorrect invocation" do
    blahblahblah 22
    from         "foobar-lvs-04", "util-01", "util-02"
    to           "foobar-lvs-04"
  end
end

