function CodeBlock (cb)
    if #cb.attr.classes  > 0 and cb.attr.attributes["path"] ~= nil then
        local gittype = cb.attr.classes[1]:match("git([^%s]+)")
        local user, repo, file =   cb.attr.attributes["path"]:match("([^/]+)/([^/]+)(/[^%s]+)")
        local branch = "main"
        if cb.attr.attributes["branch"] ~= nil then
            branch = cb.attr.attributes["branch"]
        end

        if gittype ~= nil then
            if gittype == "hub" then
                local urimain =  "https://raw.githubusercontent.com/"..user.."/"..repo.."/"..branch
                local uri = urimain..file

                local relpath,relfile = file:match("(.-)/([^/]+)$")

                print(relpath,relfile)

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
end
