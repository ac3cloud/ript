partition "supercow" do
  label "cow",    :address => "172.27.1.2"
  label "person", :address => "172.29.2.3"

  accept "moo" do
    from "cow"
    to "person"
  end
end

