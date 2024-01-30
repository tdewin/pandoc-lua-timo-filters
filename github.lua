function CodeBlock (cb)
    if #cb.attr.classes  > 0 and cb.attr.attributes["path"] ~= nil then
        local gittype = cb.attr.classes[1]:match("git([^%s]+)")
        local user, repo, file =   cb.attr.attributes["path"]:match("([^/]+)/([^/]+)(/[^%s]+)")
        local basepath = "https://raw.githubusercontent.com"

        
        
        if cb.attr.attributes["basepath"]  ~= nil then
            basepath = cb.attr.attributes["basepath"]
        end

        local branch = "main"
        if cb.attr.attributes["branch"] ~= nil then
            branch = cb.attr.attributes["branch"]
        end

        if gittype ~= nil then
            local urimain =  basepath.."/"..user.."/"..repo.."/"..branch
            local uri = urimain..file

            if gittype == "lab" then
                local urimain =  basepath.."/"..user.."/"..repo.."/-/raw/"..branch
                local uri = urimain..file
            end

            local relpath,relfile = file:match("(.-)/([^/]+)$")

            local mt, contents = pandoc.mediabag.fetch(uri)
            local pd = pandoc.read(contents,"gfm").blocks

            for i,v in pairs(pd) do
                pd[i]=pandoc.walk_block(v,{
                    Link = function(el)
                        if el["target"]:match("^http") == nil then
                            el["target"] = urimain..relpath.."/"..el["target"]
                            --print(el)
                            return el
                        end
                    end,
                    Image = function(el)
                        if el["src"]:match("^http") == nil then
                            el["src"] = urimain..relpath.."/"..el["src"]
                            return el
                        end
                    end
                    })
            end

            return pd
            
           
        end
    end
end
