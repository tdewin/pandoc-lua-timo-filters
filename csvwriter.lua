-- some crude way to export to csv
-- csv writer
-- use with pandoc <input> -t csvwriter.lua -o output.csv

function escape(text)
    ln = {}
    for c in text:gmatch"." do
        if c == "\"" then
            --If double-quotes are used to enclose fields, then a double-quote appearing inside a field must be escaped by preceding it with another double quot
            table.insert(ln,c)
            table.insert(ln,c)
        else
            table.insert(ln,c)
        end
    end
    return "\""..table.concat(ln,"").."\""
end

function Writer (doc, opts)
    local flatified = {}

    --https://pandoc.org/lua-filters.html#type-table
    local filter = {
      Table = function (tb)
          for i, r in ipairs(tb["head"]["rows"]) do
                local flatifiedrow = {}
                for k,c in ipairs(r["cells"]) do
                    local content = pandoc.utils.stringify(c["contents"])
                    table.insert(flatifiedrow,escape(content))
                end
                table.insert(flatified,table.concat(flatifiedrow,","))
          end
          for i, v in ipairs(tb["bodies"]) do
            for j,r in ipairs(v["body"]) do
                local flatifiedrow = {}
                for k,c in ipairs(r["cells"]) do
                    local content = pandoc.utils.stringify(c["contents"])
                    table.insert(flatifiedrow,escape(content))
                end
                table.insert(flatified,table.concat(flatifiedrow,","))
                
            end
            
          end          
      end,
      Para = function(t) 
         return ""
      end,
      List = function(l) 
         return {}
      end,
      BulletList = function(l) 
        return {}
     end,
     Header = function(c) 
        local content = pandoc.utils.stringify(c)
        table.insert(flatified,"\"\"\n"..escape(content))
        return {}
     end
    }
    res = doc:walk(filter)
    local raw = table.concat(flatified,"\n")
    return raw
end
