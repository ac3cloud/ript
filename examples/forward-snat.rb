partition "bar" do
  label "www.bar.com", :address => "172.23.0.95"
  label "bar subnet",  :address => "10.30.0.0/24"

  rewrite "bar.com public website" do
    snat "bar subnet" =>  "www.bar.com"
  end
end

