-- if you put in a table cell `row` it will replace this with the row number

row = 1

filters = {
  Code = function(c)
    if c.text:match("row") then
      c.text = string.format("%02d",row)
      return c
    end
  end
}

function Table(tb)
  row = 1

  for i, v in ipairs(tb["bodies"]) do
    for j,r in ipairs(v["body"]) do
        row = j
        for k,c in ipairs(r["cells"]) do
          c.contents = c.contents:walk(filters)
        end
    end
  end
  return tb
end


