#!/usr/bin/env ruby

class Hash
  def insert_before(key, opts={})
    before = self.dup.take_while {|k, v| k != key }
    after  = self.dup.drop_while {|k, v| k != key }
    before << opts.to_a.flatten
    self.clear.merge!(Hash[before]).merge!(Hash[after])
  end
end
