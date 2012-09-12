partition 'cpm' do

  label 'internal', :address => '192.168.0.133'
  label 'external', :address => '172.18.88.33'
  label 'office',   :address => '172.19.4.55'

  rewrite 'incoming dns' do
    protocols 'udp', 'tcp'
    ports 53
    from 'office'
    to   'external'
    dnat 'external' => 'internal'
  end

end
