partition "joeblogsco" do

  label "jbc.com", :address => "172.22.111.99"

  accept "jbc.com web" do
    ports 80, 443
    to "jbc.com"
  end

end

