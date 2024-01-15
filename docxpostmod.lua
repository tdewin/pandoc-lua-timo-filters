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
    action="mod",
    file="word/document.xml",
    tblStyle = "",
    filter = ".+",
    name = "",
    val = "",
    fontCat = "major",
    fontName = "latin",
    fontScript = "",
    font = "Tahoma",
    pgSz = "",
    docH = "15840",
    docW = "12240",
    docOrient = "portrait",
    rPr="",
    pPr="",
    repl="",
    titlePg=""
}
for i,a in ipairs(arg) do
    n,v = a:match("-([%w]+)=\"?([^\"]+)\"?")
    if n ~= nil and v ~= nil and opts[n] ~= nil then
        opts[n] = v
    end
end


for i,docx in ipairs(arg) do
    fname = docx:match("(.+).docx$") 
    if fname then
        local inp = assert(io.open(docx, "rb"))
        local zipdata = inp:read("*all")    
        inp:close()

        local openzip = pandoc.zip.Archive(zipdata)

       
        
        
        local mod = false

        if opts.action == "dump" then
            local content = zip_get_entry(openzip,opts.file)
            print(content)
        elseif opts.action == "listfiles" then
            for i,e in pairs(openzip.entries) do
                print(e["path"])
            end
        elseif opts.action == "liststyles" then
            local content = zip_get_entry(openzip,"word/styles.xml")
            for m in content:gmatch("<w:style [^>]+>") do
                if m:match(opts.filter) then
                    local stype = m:match("w:type=\"([^\"]+)\"")
                    local sid = m:match("w:styleId=\"([^\"]+)\"")
                    print(stype,sid)
                end
            end
        elseif opts.action == "addtabstyle" then
            local file = "word/styles.xml"
            local content = zip_get_entry(openzip,file)
            local tsn = "customtabstyle"
            if opts.name ~= "" then
                tsn = opts.name
            end
            if content:match("w:styleId=\""..tsn)== nil then
                local cts = "<w:style w:type=\"table\" w:customStyle=\"1\" w:styleId=\""..tsn.."\"><w:name w:val=\""..tsn.."\"/><w:basedOn w:val=\"TableNormal\"/><w:uiPriority w:val=\"99\"/><w:pPr><w:spacing w:after=\"0\"/></w:pPr><w:tblPr><w:tblBorders><w:top w:val=\"single\" w:sz=\"4\" w:space=\"0\" w:color=\"auto\"/><w:left w:val=\"single\" w:sz=\"4\" w:space=\"0\" w:color=\"auto\"/><w:bottom w:val=\"single\" w:sz=\"4\" w:space=\"0\" w:color=\"auto\"/><w:right w:val=\"single\" w:sz=\"4\" w:space=\"0\" w:color=\"auto\"/></w:tblBorders></w:tblPr><w:tblStylePr w:type=\"firstRow\"><w:rPr><w:color w:val=\"FAFAFA\" w:themeColor=\"background1\"/><w:u w:val=\"none\"/></w:rPr><w:tblPr/><w:tcPr><w:tcBorders><w:bottom w:val=\"single\" w:sz=\"4\" w:space=\"0\" w:color=\"auto\"/></w:tcBorders><w:shd w:val=\"clear\" w:color=\"auto\" w:fill=\"E63462\" w:themeFill=\"accent1\"/></w:tcPr></w:tblStylePr></w:style>"
                content = content:gsub("</w:styles>",cts.."</w:styles>")
                            
                mod = true
                zip_set_entry(openzip,file,content)
            else
                print("Already found style with name "..tsn)
            end
        elseif opts.action == "addstyle" then
            local file = "word/styles.xml"
            local content = zip_get_entry(openzip,file)
            local tsn = "customstyle"
            if opts.name ~= "" then
                tsn = opts.name
            end

            if content:match("w:styleId=\""..tsn)== nil then
                local cts = "<w:style w:type=\"paragraph\" w:customStyle=\"1\" w:styleId=\""..tsn.."\"><w:name w:val=\""..tsn.."\" /><w:qFormat /><w:basedOn w:val=\"Normal\"/>  <w:next w:val=\"Normal\"/> </w:style>"
                content = content:gsub("</w:styles>",cts.."</w:styles>")
                            
                mod = true
                zip_set_entry(openzip,file,content)
            else
                print("Already found style with name "..tsn)
            end
        elseif opts.action == "updatestyle" then
            local file = "word/styles.xml"
            local content = zip_get_entry(openzip,file)
            for repl,attr,c in content:gmatch("(<w:style([^>]+)>(.-)</w:style>)") do
                    local stype = attr:match("w:type=\"([^\"]+)\"")
                    local sid = attr:match("w:styleId=\"([^\"]+)\"")
                    
                    
                    if sid == opts.name then
                        if opts.rPr ~= "" then
                            local slines = {"\n\t<w:rPr>"}
                            local vals = opts.val:gmatch("[^,]+")
                            for stname in opts.rPr:gmatch("[^,]+") do
                                local stval = vals()
                                local ln = "\t  <w:"..stname.."/>"

                                if stval ~= nil and stval ~= "" then
                                    if #stval > 3 and stval:sub(1,1) == "{" and stval:sub(#stval,#stval) == "}" then
                                        ln = "\t  <w:"..stname.." "
                                        for n,v in stval:sub(2,(#stval-1)):gmatch("([^:]+):([^;]+);?") do
                                            ln = ln.." w:"..n.."=\""..v.."\""
                                        end
                                        ln = ln.."/>"
                                        
                                    else
                                        ln = "\t  <w:"..stname.." w:val=\""..stval.."\"/>"
                                    end
                                end
                                table.insert(slines,ln)
                            end
                            table.insert(slines,"\t</w:rPr>")

                            local rPr = c:match("%s*<w:rPr[^>]*>.-</w:rPr>")
                            local newrPr = table.concat(slines,"\n")
                            if rPr then
                               c = c:gsub(rPr,newrPr)
                            else 
                                c = c..newrPr
                            end
                        elseif opts.pPr ~= "" then
                            local slines = {"\n\t<w:pPr>"}
                            local vals = opts.val:gmatch("[^,]+")
                            for stname in opts.pPr:gmatch("[^,]+") do
                                local stval = vals()
                                local ln = "\t  <w:"..stname.."/>"

                                if stval ~= nil and stval ~= "" then
                                    if #stval > 3 and stval:sub(1,1) == "{" and stval:sub(#stval,#stval) == "}" then
                                        ln = "\t  <w:"..stname.." "
                                        for n,v in stval:sub(2,(#stval-1)):gmatch("([^:]+):([^;]+);?") do
                                            ln = ln.." w:"..n.."=\""..v.."\""
                                        end
                                        ln = ln.."/>"
                                        
                                    else
                                        ln = "\t  <w:"..stname.." w:val=\""..stval.."\"/>"
                                    end
                                end
                                --print(ln)
                                table.insert(slines,ln)
                            end
                            table.insert(slines,"\t</w:pPr>")

                            local pPr = c:match("%s*<w:pPr[^>]*>.-</w:pPr>")
                            local newpPr = table.concat(slines,"\n")
                            if pPr then
                               c = c:gsub(pPr,newpPr)
                            else 
                                c = c..newpPr
                            end
                        end
                        
                        local newstyle = "<w:style "..attr..">"..c.."</w:style>"
                        content = content:gsub(repl,newstyle)
                        --print(content)
                        mod = true
                        zip_set_entry(openzip,file,content)
                    end
            end
        elseif opts.action == "liststyle" then
            local content = zip_get_entry(openzip,"word/styles.xml")
            for repl,attr,c in content:gmatch("(<w:style ([^>]+)>(.-)</w:style>)") do
                    local stype = attr:match("w:type=\"([^\"]+)\"")
                    local sid = attr:match("w:styleId=\"([^\"]+)\"")
                    if sid == opts.name then
                        
                        print(repl)
                    end
            end
        elseif opts.action == "listcolors" then
            local content = zip_get_entry(openzip,"word/theme/theme1.xml")
            local colors = content:match("<a:clrScheme[^>]+>.-</a:clrScheme>")
            if colors  then
                for c,v in colors:gmatch("<a:([%w]-)>(.-)</a:") do
                    print(c,v)
                end
            end
        elseif opts.action == "updatecolor" then
            local content = zip_get_entry(openzip,"word/theme/theme1.xml")
            local colors = content:match("<a:clrScheme[^>]+>.-</a:clrScheme>")
           
            if colors and opts.name ~= "" and opts.val ~= "" then
                local replace = ""..colors

                local names = opts.name:gmatch('[^,]+')
                local vals = opts.val:gmatch('[^,]+')
                for name in names do
                    local val = vals()
                    if val ~= nil then
                        local findcolor = colors:match("(<a:"..name..">.-</a:"..name..">)")
                        if findcolor ~= nil then
                            colors = colors:gsub(findcolor,"<a:"..name.."><a:srgbClr val=\""..val.."\"/></a:"..name..">")
                        end
                    else
                        error(string.format("unmatched color %s",name))
                    end
                end



                content = content:gsub(replace,colors)
                mod = true
                --print(content)
                zip_set_entry(openzip,"word/theme/theme1.xml",content)
            end
        elseif opts.action == "listthemefonts" then
            local content = zip_get_entry(openzip,"word/theme/theme1.xml")
            local majorFonts = content:match("<a:majorFont[^>]*>.-</a:majorFont>")
            local minorFonts = content:match("<a:minorFont[^>]*>.-</a:minorFont>")
            local fontm = "<a:([^>]-)/>"

            if majorFonts then
                print("major Fonts:")
                for font in majorFonts:gmatch(fontm) do
                    print(" ",font)
                end
            end
            if minorFonts then
                print("")
                print("minor Fonts:")
                for font in majorFonts:gmatch(fontm) do
                    print(" ",font)
                end
            end
        elseif opts.action == "updatefont" then
            local content = zip_get_entry(openzip,"word/theme/theme1.xml")
            
            local fontCat = content:match("<a:"..opts.fontCat.."Font[^>]*>.-</a:"..opts.fontCat.."Font>")
            
            if fontCat then
                tmpl = "<a:"..opts.fontName.."[^>]*>"
                rpl = "<a:"..opts.fontName.." typeface=\""..opts.font.."\" />"
                if opts.fontScript ~= "" then
                    tmpl = "<a:font script=\""..opts.fontScript.."\"[^>]*>"
                    rpl = "<a:font script=\""..opts.font.."\" typeface=\""..opts.font.."\" />"
                end
                local fontfind = fontCat:match(tmpl)
                if fontfind then
                    content = content:gsub(fontfind,rpl)
                    mod = true
                    zip_set_entry(openzip,"word/theme/theme1.xml",content)
                else 
                    error("No match with "..tmpl)
                end
            else
                error("Cant find (consider minor,major)"..fontCat)
            end
            
        elseif opts.action == "mod" then
            local docpath = "word/document.xml"
            local content = zip_get_entry(openzip,opts.file)

            if opts.file == docpath then
                --<w:tblStyle w:val="Table" />
                if opts.tblStyle ~= "" then
                    print("updating tblStyle "..opts.tblStyle)
                    content = content:gsub("<w:tblStyle[^>]+>","<w:tblStyle w:val=\""..opts.tblStyle.."\" />")
                    mod = true
                end

                --<w:pgSz w:h="15840" w:w="12240" /> -- us
                --<w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/> -- a4
                --use pgSz=man for manual values
                if opts.titlePg ~= "" then
                    local repl = "<w:titlePg/>"
                    local existing = content:match("(<w:sectPr[^>]*>.-)</w:sectPr>")

                    if content:match("<w:sectPr%s*/>") ~= nil then
                        content = content:gsub("<w:sectPr%s*/>","<w:sectPr>"..repl.."</w:sectPr>")
                    elseif content:match("<w:titlePg/") ~= nil then
                        print("already titlePg detected")
                    elseif existing ~= nil  then
                        content = content:gsub(existing,existing.."\n"..repl)
                    else
                        error("couldnt find empty sectPr or pgSz")
                    end

                    mod = true

                end
                if opts.pgSz ~= "" then
                    if opts.pgSz == "a4" then
                        opts.docH = 16838
                        opts.docW = 11906
                    elseif opts.pgSz == "us" then
                        opts.docH = 15840
                        opts.docW = 12240
                    end

                    if opts.docOrient == "landscape" and tonumber(opts.docH) > tonumber(opts.docW) then
                        local sw = opts.docH 
                        opts.docH = opts.docW
                        opts.docW = sw
                    end

                    print("updating doc to hxw ",opts.docH,opts.docW,opts.docOrient)

                    local repl = "<w:pgSz w:h=\""..opts.docH.."\" w:w=\""..opts.docW.."\" w:orient=\""..opts.docOrient.."\" />"
                    local existing = content:match("(<w:sectPr[^>]*>.-)</w:sectPr>")

                    if content:match("<w:sectPr%s*/>") ~= nil then
                        content = content:gsub("<w:sectPr%s*/>","<w:sectPr>"..repl.."</w:sectPr>")
                    elseif content:match("<w:pgSz") ~= nil then
                        content = content:gsub("<w:pgSz[^>]+/>",repl)
                    elseif existing then
                        content = content:gsub(existing,existing.."\n"..repl)
                    else
                        error("couldnt find empty sectPr or pgSz")
                    end


                    mod = true
                end
            end

            if opts.repl ~= ""  then
                print("replacing "..opts.repl.." with "..opts.val)
                content = content:gsub(opts.repl,opts.val)
                mod = true
            end

            zip_set_entry(openzip,docpath,content)
            
            
        end  

        if mod then
            local newzip = io.open(docx, "wb")
            newzip:write(openzip.bytestring(openzip))
            newzip:close()
        end  
    end
end