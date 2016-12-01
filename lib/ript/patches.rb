class Hash
  def insert_before(key, kvpair)
    arr = to_a
    pos = arr.index(arr.assoc(key))
    if pos
      arr.insert(pos, kvpair)
    else
      arr << kvpair
    end
    replace Hash[arr]
  end
end
