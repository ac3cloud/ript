partition "bar" do
  label "www.bar.com",    :address => "172.23.0.95"
  label "barprod-web-01", :address => "192.168.19.2"
  label "localhost",      :address => "127.0.0.1"

  log "localhost on www.bar.com" do
    from "localhost"
    to   "www.bar.com"
  end
end

