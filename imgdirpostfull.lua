local function zip_get_entry(openzip,path)
    for i,entry in pairs(openzip.entries) do
        if entry["path"] == path then
            return (entry["contents"])(entry)
        end
    end
    return ""
end

local function zip_set_entry(openzip,path,content)
    for i,entry in pairs(openzip.entries) do
        if entry["path"] == path then
            openzip.entries[i] = pandoc.zip.Entry(entry["path"],content)
        end
    end
    return ""
end


local opts = {
    x = 0,
    y = 0,
    cx = 960,
    cy = 540,
    metric = "px",
    auto = "0",
}
for i,a in ipairs(arg) do
    n,v = a:match("-([%w]+)=([%w]+)")
    if n ~= nil and v ~= nil and opts[n] ~= nil then
        opts[n] = v
    end
end
--360 000 (An English Metric Unit (EMU) is defined as 1/360,000 of a centimeter )
--and thus there are 914,400 EMUs per inch, and 12,700 EMUs per point.
--9144000 / 360 000 = 25.4 cm or 10 inch (9144000/914400)
--5143500 / 360 000 = 14.2875 cm or 5,625inch (5143500/914400)
--https://developers.google.com/slides/api/reference/rest/v1/Unit

m = 360000
convtable = {
    cm = 360000,
    inch = 914400,
    pt = 12700,
    px = 9525,
    emu = 1,
}
if convtable[opts.metric] then
    m = convtable[opts.metric]
    --print("converting to "..opts.metric.." "..m)
end

for i,n in pairs({"x","y","cx","cy"}) do
    opts[n] = math.floor(tonumber(opts[n])*m)
    --print(n..": "..opts[n])
end


for i,pptx in ipairs(arg) do
    fname = pptx:match("(.+).pptx$") 
    if fname then
        --print("Processing "..pptx.." ")

        local inp = assert(io.open(pptx, "rb"))
        local zipdata = inp:read("*all")    
        inp:close()

        local openzip = pandoc.zip.Archive(zipdata)

        local pptxml = zip_get_entry(openzip,"ppt/presentation.xml")
        --<p:sldSz cx="9144000" cy="5143500" type="screen16x9" />
        if pptxml and opts.auto == "1" then
            local acx,acy = pptxml:match("sldSz cx=\"([%.%-%d]+)\" cy=\"([%.%-%d]+)\"[^>]+>")
            if acx ~= nil and acy ~= nil then
                opts.x = 0
                opts.y = 0
                opts.cx = acx
                opts.cy = acy
            end
        end

        
        for i,entry in pairs(openzip.entries) do
            p = entry["path"]
            if p:match("ppt/slides/slide%d+.xml") then
                local content = zip_get_entry(openzip,p)

                if (content:match("<p:blipFill>")) then
                    
                    content = content:gsub("<a:off x=\"[%.%-%d]+\" y=\"[%.%-%d]+\"[^>]+>","<a:off x=\""..opts.x.."\" y=\""..opts.y.."\" />")
                    content = content:gsub("<a:ext cx=\"[%.%-%d]+\" cy=\"[%.%-%d]+\"[^>]+>","<a:ext cx=\""..opts.cx.."\" cy=\""..opts.cy.."\" />")
                    
                    --print("Detect blipFill on, resized "..p)
                    --print(content)
                    zip_set_entry(openzip,p,content)
                end
            end
        end

        local newzip = io.open(pptx, "wb")
        newzip:write(openzip.bytestring(openzip))
        newzip:close()

    end
end