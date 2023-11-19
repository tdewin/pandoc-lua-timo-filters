function CodeBlock (cb)
    if #cb.attr.classes  > 0 then
        if (cb.attr.classes[1] == "imgdirexplode") then
            local dir = cb.attr.attributes["dir"]
            local match = "(.+)"

            if cb.attr.attributes["match"] then
                match = cb.attr.attributes["match"]
            end

            if dir ~= nil then
                local list = {}
                
                for i,v in pairs(pandoc.system.list_directory(dir)) do
                    if v:find(match) then
                        local tmpl = "\n"..cb.text
                        
                        local relfile = pandoc.path.join({dir,v})

                        tmpl = tmpl:gsub("${fileOnly}",v)
                        tmpl = tmpl:gsub("${file}",relfile)
                        tmpl = tmpl:gsub("${dir}",dir)
                        
                        table.insert(list,tmpl)
                    end
                end
                if #list > 0 then
                    return pandoc.read(table.concat(list,"\n"),"markdown").blocks
                end
            end

            -- if we didn't get anything just make empty return
            return pandoc.Str("")
        end
    end
end
