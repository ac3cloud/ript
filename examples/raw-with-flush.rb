partition "boilerplate" do
  raw <<-RAW
# Flush everything
iptables -t filter -F
iptables -t nat -F
iptables -t mangle -F
  RAW
end

