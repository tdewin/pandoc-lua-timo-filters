local vars = {}
local baselibrary = ""

function collect (meta)
  for k, v in pairs(meta) do
    if k == "baselibrary" then
        baselibrary =  pandoc.utils.stringify(v)
        
        meta[k] = ""
    end

    if pandoc.utils.type(v) == 'Inlines' then
      vars[k] = pandoc.utils.stringify(v)
    end
  end
  return meta
end

function updateimg(img) 
    if img.src:match("^./") then
        img.src = pandoc.path.normalize(pandoc.path.join({baselibrary,img.src}))
    end
    return img
end

function replace (cb)
    local file = cb.attr.attributes["file"]

    if cb.attr.attributes["partial"] then
        for i,fname in ipairs(pandoc.system.list_directory(baselibrary)) do 
             if fname:match(cb.attr.attributes["partial"]) then
                file = fname
                print(file)
             end
        end
    end
    
    if #cb.attr.classes  > 0 and file ~= nil then
        local f = pandoc.path.normalize(pandoc.path.join({baselibrary,file}))

        local f = assert(io.open(f, "r"))
        local t = f:read("*all")
        f:close()

        
        for line in cb.text:gmatch("[^\r\n]+") do
            local varcheck = line

            if vars[varcheck] then
                t = t:gsub("{{"..line.."}}",vars[varcheck])
            end
        end 


        local doc = pandoc.read(t,"markdown")
        doc = doc:walk {
            Image = updateimg
        }

        return doc.blocks
    end
end


return {{Meta = collect}, {CodeBlock = replace}}