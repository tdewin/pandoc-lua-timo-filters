-- some crude way to export to csv
-- keeps the headers intact and just put them in csv code blocks
-- use with pandoc <input> -t csvwriter.lua -o csvembed.md
function Writer (doc, opts)
    --https://pandoc.org/lua-filters.html#type-table
    local filter = {
      Table = function (tb)
          --print(tb["head"]["rows"])
          local flatified = {}

          for i, v in ipairs(tb["bodies"]) do
            for j,r in ipairs(v["body"]) do
                local flatifiedrow = {}
                for k,c in ipairs(r["cells"]) do
                    local content = "\""..pandoc.utils.stringify(c["contents"]).."\""
                    table.insert(flatifiedrow,content)
                end
                table.insert(flatified,table.concat(flatifiedrow,","))
            end
            
          end
          local cb = pandoc.CodeBlock(table.concat(flatified,"\n"))
          cb["attr"]["classes"] = {"csv"}
          return cb
      end,
      Para = function(t) 
         return ""
      end,
      List = function(l) 
         return {}
      end,
      BulletList = function(l) 
        return {}
     end
    }
    return pandoc.write(doc:walk(filter), 'markdown', opts)
  end
