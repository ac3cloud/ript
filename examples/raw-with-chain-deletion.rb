partition "boilerplate" do
  raw <<-RAW
# Delete created chains
iptables -X
iptables -t nat -X
iptables -t mangle -X
  RAW
end

