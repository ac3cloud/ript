partition "bar" do
  label "www.bar.com",     :address => "172.23.0.95"
  label "api.bar.com",     :address => "172.24.0.99"
  label "barprod-api-01",  :address => "10.55.0.45"
  label "bar prod subnet", :address => "10.55.0.0/24"


  # FIXME: should things with a netmask be inserted lower into the chain?
  rewrite "bar" do
    snat "barprod-api-01" => "api.bar.com"
  end

  rewrite "bar prod outbound" do
    snat "bar prod subnet" => "www.bar.com"
  end
end
