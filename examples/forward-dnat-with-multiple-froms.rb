partition "joeblogsco" do
  label :office1,             :address => "1.2.3.4"
  label :office2,             :address => "4.5.6.7"
  label :office3,             :address => "7.8.9.10"
  label "www.joeblogsco.com", :address => "172.19.10.99"
  label "joeblogsco-app-01",  :address => "192.168.27.66"

  rewrite "bar" do
    ports 80
    from  :office1, :office2, :office3
    dnat "www.joeblogsco.com" => "joeblogsco-app-01"
  end
end
