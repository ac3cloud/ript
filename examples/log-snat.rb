partition "bar" do
  label "bar uat subnet",   :address => "10.33.0.0/24"
  label "bar stage subnet", :address => "10.44.0.0/24"
  label "bar prod subnet",  :address => "10.55.0.0/24"

  label "www.bar.com",      :address => "172.23.0.95"

  rewrite "bar", :log => true do
    snat  [ "bar uat subnet",
            "bar stage subnet",
            "bar prod subnet"  ] => "www.bar.com"
  end
end
