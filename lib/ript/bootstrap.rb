module Ript
  class Bootstrap
    def self.partition
      rules = []

      rules << Rule.new("table" => "filter",  "new-chain" => "partition-a")
      rules << Rule.new("table" => "filter",  "insert" => "INPUT 1", "jump" => "partition-a")
      rules << Rule.new("table" => "filter",  "insert" => "OUTPUT 1", "jump" => "partition-a")
      rules << Rule.new("table" => "filter",  "insert" => "FORWARD 1", "jump" => "partition-a")

      rules << Rule.new("table" => "nat",  "new-chain" => "partition-d")
      rules << Rule.new("table" => "nat",  "insert" => "PREROUTING 1", "jump" => "partition-d")

      rules << Rule.new("table" => "nat",  "new-chain" => "partition-s")
      rules << Rule.new("table" => "nat",  "insert" => "POSTROUTING 1", "jump" => "partition-s")

      Partition.new('ript_bootstrap', nil, :rules => rules)
    end
  end
end
