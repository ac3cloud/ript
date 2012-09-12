partition "tootyfruity" do
  label "apple",      :address => "192.168.0.1"
  label "blueberry",  :address => "192.168.0.2"
  label "cranberry",  :address => "192.168.0.3"
  label "eggplant",   :address => "192.168.0.4"
  label "fennel",     :address => "192.168.0.5"
  label "grapefruit", :address => "192.168.0.6"

  accept "fruits of the forrest" do
    protocols "tcp"
    ports     22
    from      %w(apple blueberry cranberry eggplant fennel grapefruit)
    to        %w(apple blueberry cranberry eggplant fennel grapefruit)
  end
end

