
-- read from zip file an entry
local function zip_get_entry(openzip,path)
    for i,entry in pairs(openzip.entries) do
        if entry["path"] == path then
            return (entry["contents"])(entry)
        end
    end
    return ""
end
-- check if a table has a value
local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

-- 
local function flaky_xml_parser(xmltext,tag) 
    local mtag = "<"..tag
    local p = -1
    local n = string.find(xmltext,mtag,1)
    local matches = {}
    while true do
        -- e is the end, if we can find the next tag, its the end
        -- if we can not then the end end of the string
        local e = n
        if e == nil then e = #xmltext else e = n-1 end
        
        -- if p is not -1 (first round)
        if p ~= -1 then
         table.insert(matches,string.sub(xmltext,p,e))
        end
        
        -- if there is no next match then break
        if n == nil then 
            break 
        else
            p = n
            n = string.find(xmltext,mtag,p+1)
        end
    end
    return ipairs(matches)
end

---
-- unzip -l x.xlsx
-- unzip -p x.xlsx  xl/sharedStrings.xml
--1  [Content_Types].xml
--2  _rels/.rels
--3  xl/_rels/workbook.xml.rels
--4  xl/workbook.xml
--5  xl/sharedStrings.xml
--6  xl/styles.xml
--7  xl/worksheets/sheet1.xml
--8  xl/theme/theme1.xml
--9  docProps/app.xml
--10 docProps/core.xml
--11 xl/calcChain.xml
--
local function patternTag(tag)
    return "<"..tag.." ([^>]-)/?>"
end 

-- A = 0, AA = 27
local function XLSAZtoNum(az)
    n = 0
    for i=1,#az do
        n = n*26+(string.byte(string.sub(az,i,i))-64)
    end
    return n
end

local function XLScoord(aznum)
    a,d = string.match(aznum,"([%a]+)([%d]+)")
    return XLSAZtoNum(a),tonumber(d)
end

local function get_default_style()
    return { font= {i=false,u=false,b=false} , align=pandoc.AlignDefault}
end

local function log(debug,line)
    if(debug) then
        print("[DEBUG] "..line)
    end
end
local function XLSReadFile(filename,input,opts,cell)
    local openzip = pandoc.zip.Archive(input)
    local xlsxname = filename:gsub(".xlsx$","")


    local wb = zip_get_entry(openzip,"xl/workbook.xml")
    local rwb = zip_get_entry(openzip,"xl/_rels/workbook.xml.rels")
    local shst =  zip_get_entry(openzip,"xl/sharedStrings.xml")
    local stylesxml = zip_get_entry(openzip,"xl/styles.xml")
    --log(debug,stylesxml)

    doc = {}

    debug = (opts["debug"] ~= false)

    log(debug,"Debugging Enabled")
    
    
    local patternAttr = "([%w:]+)=\"([^\"]+)\""

    local styles = {}
    local fonts = {}

    

    local fonts_cellxfs = string.match(stylesxml,"<fonts[^>]*>(.-)</fonts>")
    if(fonts_cellxfs) then
        --log(debug,fonts_cellxfs)
        local fontid=0
        for f in string.gmatch(fonts_cellxfs,"<font[^>]*>(.-)</font>") do
            local newFont = {i=false,u=false,b=false}
            for s,v in pairs(newFont) do
                if string.find(f,"<"..s.."/>") then
                    newFont[s] = true
                end
            end
            fonts[fontid] = newFont
            fontid = fontid + 1
        end
    end

    --for i,f in pairs(fonts) do
    --    log(debug,i.." b"..tostring(f["b"]).." i"..tostring(f["i"]).." u"..tostring(f["u"]))
    --end
    
    local style_cellxfs = string.match(stylesxml,"<cellXfs[^>]*>(.-)</cellXfs>")
    if (style_cellxfs) then
        --log(debug,style_cellxfs)
        
        local xfi = 0

        
        for i,xf in flaky_xml_parser(style_cellxfs,"xf") do
            
            
            local style = get_default_style()

            local fontId = string.match(xf,"fontId=\"(%d+)\"")
            if (fontId ~= nil) then
                local id = (tonumber(fontId))
                style["font"] = fonts[id]
                
            end

            local halign = string.match(xf,"alignment[^>]+horizontal=\"(%w+)\"")
            if (halign ~= nil) then
                
                if halign == "right" then
                    style["align"] = pandoc.AlignRight
                elseif halign == "left" then
                    style["align"] = pandoc.AlignLeft
                elseif halign == "center" then
                    style["align"] = pandoc.AlignCenter
                end
            end

            styles[xfi] = style
            log(debug,tostring(xfi)..xf)
            xfi = xfi + 1
            
        end
    end
    
    --for i,s in pairs(styles) do
    --    print(i,tostring(s["font"]["b"]))
    --end
    
    sharedStrings = {}
    s=0
    --log(debug,"Shared string "..shst)
    for w in string.gmatch(shst, "<si[^<]*><t[^<]*>([^<]+)</t></si>") do
        log(debug,"Shared string "..s.." "..w)
        sharedStrings[s] = w
        s = s+1
        
    end



    rels = {}
    relbytype = {}
    relbytarget = {}
    for w in string.gmatch(rwb, patternTag("Relationship")) do
        local m = {Id="-",Type="-",Target="-"}

        for attr,v in string.gmatch(w,patternAttr) do
            if m[attr] == "-" then
                m[attr] = v
            end
        end
        
        if m["Id"] ~= "-" and m["Type"] ~= "-" and m["Target"] ~= "-" then
            rels[m["Id"]] = m
            if relbytype[m["Type"]] == nil then
                relbytype[m["Type"]] = {}
            end
            table.insert(relbytype[m["Type"]],m)
            relbytarget[m["Target"]] = m
        end
    end

    rvrels = {}

    if (relbytarget["richData/richValueRel.xml"] ~= nil)  then
        local tmprel = {}

        local richvaluerel = zip_get_entry(openzip,"xl/richData/richValueRel.xml")
        i = 1
        for rel in string.gmatch(richvaluerel,"<rel r:id=\"(%w+)\"") do
            tmprel[rel] = i 
            i = i+1
        end

        local richvaluerelrels = zip_get_entry(openzip,"xl/richData/_rels/richValueRel.xml.rels")
        for rel in string.gmatch(richvaluerelrels,patternTag("Relationship")) do
            local rid = string.match(rel,"Id=\"(%w+)\"")
            local target = string.match(rel,"Target=\"([^\"]+)\"")
            if rid ~= nil and target ~= nil and tmprel[rid] ~= nil then
                local target = target:gsub("^../media/","xl/media/")
                local outtarget = target:gsub("^../media/","")

                local outstack = {}
                table.insert(outstack,".")
                table.insert(outstack,xlsxname)
                table.insert(outstack,outtarget)
                local outf = table.concat(outstack,pandoc.path.separator)

            
                rvrels[tmprel[rid]] = {src=target,out=outf}
                log(debug,"media".." "..tmprel[rid].." "..target.." "..outf)
            end
        end
    end



    local sheets = {}
    --log(debug,wb)
    for w in string.gmatch(wb, patternTag("sheet")) do
        local name = ""
        local rid = ""
        local sheetId = ""

        

        for attr,v in string.gmatch(w,patternAttr) do
            if attr == "name" then
                name = v
            elseif attr == "r:id" then
                rid = v
            elseif attr == "sheetId" then
                sheetId = v
            end 
        end 
        if (name ~= "" and sheetId ~= "" and rid ~= "") then
            table.insert(sheets,{name=name,sid=sheetId,rid=rid})
            log(debug,"Detected sheet "..name)
        end
    end

    
    --for n,v in pairs(rels) do
    --    print(n,v["Id"],v["Target"],v["Type"])
    --end

    local skiprows = opts["skiprows"]
    local defwidth = opts["defwidth"]

    log(debug,"Skip rows "..skiprows)

    for n,v in pairs(sheets) do
        log(debug,"Check sheet "..v["name"])
        
        local includesheet = has_value(opts["sheets"],v["name"])
        log(debug,"Is in sheet table? "..tostring(includesheet))

        
        if (rels[v["rid"]] and (#opts["sheets"] == 0 or includesheet)) then
            local cont = zip_get_entry(openzip,"xl/"..rels[v["rid"]]["Target"])
            if (cont ~= nil and cont ~= "") then
                local sstart,send = nil,nil
                if (opts["cellrange"] ~= nil) then
                    sstart = opts["cellrange"][1]
                    send = opts["cellrange"][2]
                else 
                    sstart,send = string.match(cont, "<dimension ref=\"([%a]+[%d]+):([%a]+[%d]+)\"/>")
                end
                if (sstart) then
                    log(debug,"Dimension "..sstart.." "..send)
                    --A1:C5
                    --A=65
                    
                    local sx,sy = XLScoord(sstart)
                    local ex,ey = XLScoord(send)
                   
                    sy = sy + skiprows

                    colsn = ex-sx+1
                    rowsn = ey-sy+1
                    
                    local rows = {}
                    local headers = opts["headers"]

                    

                    local notflh = opts["firstlineheader"] == false or opts["firstlineheader"] == "false"
                    
                    local rplus = 1
                    if notflh then
                        rplus = 0
                    end
                    
                    if (debug) then
                        log(debug,"Has header header row "..tostring(notflh ~= true))
                        log(debug,"Rplus "..rplus)
                    end

                    for c=(#headers+1),colsn do
                        table.insert(headers,"")
                    end
                    for r=(1+rplus),rowsn do
                        cols = {}
                        for c=1,colsn do
                            table.insert(cols,"")
                        end
                        table.insert(rows,cols)
                    end
                    
                    local aligns = {}
                    for i=1,colsn do
                        table.insert(aligns,pandoc.AlignDefault)
                    end


                    --log(debug,cont)
                    for rown,row in string.gmatch(cont,"<row r=\"([%d]+)\"(.-)</row>") do
                       log(debug,"Row "..rown)
                       
                       for celln,t,cell in string.gmatch(row,"<c r=\"([%a]+[%d]+)\"(.-)>(.-)</c>") do
                            local v = string.match(cell,"<v>(.-)</v>")
                            
                            local style = get_default_style()
                            local stylematch = string.match(t,"s=\"(%d+)\"")
                            if stylematch then
                                local n = tonumber(stylematch)
                                style = styles[n]
                            end

                            if v then
                                log(debug,"Cell "..celln.." "..v.." "..t)
                                
                                local col,row = XLScoord(celln)
                                if sx <= col and col <= ex and sy <= row and row <= ey then

                                    local localcol = col-sx+1
                                    local localrow = row-sy+1

                                    local pandocOpt = "str"
                                    celltype = string.match(t,"t=\"(%a+)\"")
                                    
                                    if localrow > 0 then
                                        local cv = v
                                        -- if a cell type is defined (not a regular number)
                                        if celltype ~= nil then
                                            -- in case the cell is a sting, it needs to be looked up
                                            if celltype == "s" then
                                                cv = sharedStrings[tonumber(v)]
                                                if cv == nil then
                                                    cv = v
                                                    log(debug,"Err SS lookup "..v.."in"..celln)
                                                end
                                            -- in case the cell is an image
                                            elseif celltype == "e" then
                                                local vmnum = string.match(t,"vm=\"(%d+)\"")
                                                if vmnum then
                                                    vmnum = tonumber(vmnum)
                                                    if rvrels[vmnum] then
                                                        local out = rvrels[vmnum]["out"]
                                                        local parent = pandoc.path.directory(out)
                                                        
                                                        local content = zip_get_entry(openzip,rvrels[vmnum]["src"])
                                                        

                                                        local f = io.open(parent, "r")
                                                        if f == nil then
                                                            pandoc.system.make_directory(parent)
                                                        else
                                                            f:close()
                                                        end

                                                        local f = io.open(out, "r")
                                                        if f == nil then
                                                            local f = io.open(out, "w")
                                                            f:write(content)
                                                            f:close()
                                                            log(debug,"fc extract "..rvrels[vmnum]["src"].." to "..out)
                                                        else
                                                            f:close()
                                                            log(debug,"fc refusing, already exists "..rvrels[vmnum]["src"].." to "..out)
                                                        end

                                                        


                                                        cv = pandoc.Image("",out)
                                                        pandocOpt = "img"
                                                    else
                                                        log(debug,"Couldnt find vm on image celltype that works "..celltype)
                                                    end
                                                else
                                                    log(debug,"Couldnt find vm on image celltype "..celltype)
                                                end
                                            else
                                                log(debug,"Err unknown celltype, defaulting "..celltype.." "..celln.." "..cv.." "..cont)
                                            end
                                        end

                                        --local wrap = pandoc.utils.blocks_to_inlines(pandoc.read(cv,"markdown").blocks)
                                        local wrap = cv
                                        if pandocOpt == "str" then
                                            wrap = pandoc.Str(cv)

                                            if style["font"]["b"] then
                                                wrap = pandoc.Strong(wrap)
                                            end

                                            if style["font"]["u"] then
                                                wrap = pandoc.Underline(wrap)
                                            end

                                            if style["font"]["i"] then
                                                wrap = pandoc.Emph(wrap)
                                            end
                                        end

                                        if opts["cellonly"] ~= nil and opts["cellonly"] == celln then
                                            return wrap
                                        end

                                        if localrow == 1 then
                                            aligns[localcol] = style["align"]
                                        end

                                        if notflh or localrow ~= 1 then
                                            local rowcoord = localrow-rplus
                                            rows[rowcoord][localcol] = wrap

                                            log(debug,"Setting cell "..rowcoord.." "..localcol..":")
                                            if (pandocOpt == "str") then
                                                log(debug,cv)
                                            end
                                        else
                                            headers[localcol] = wrap
                                            

                                            log(debug,"Setting header"..localcol.." "..cv)
                                        end
                                    end
                                end
                            end
                       end
                    end
                    

                    if opts["header"] then 
                        table.insert(doc,pandoc.Header(opts["headerlevel"],pandoc.Str(v["name"])))
                    end
                    local caption = ""
                    
                    local widths = {} 
                    
                    
                    
                    --pad if ommit
                    widths=opts["widths"]
                    
                    log(debug,"Default width "..defwidth)
                    local remaining = (colsn-#widths)
                    if defwidth == 0 and remaining > 0 then
                        --creates a nice full width table in docx
                        budget = 1
                        for n,v in pairs(widths) do
                            log(debug,"Budget decrease "..v)
                            budget = budget - v
                        end
                        defwidth = (budget/remaining)
                    end

                    log(debug,"Default width "..defwidth)
                    for i=(#widths+1),colsn do
                        table.insert(widths,defwidth)    
                    end
                    
                    isemptyheader = true
                    for i,h in pairs(headers) do
                        if h ~= "" then
                            isemptyheader = false
                        end
                    end
                    log(debug,"Empty header? "..tostring(isemptyheader))

                    if isemptyheader then
                        headers = {}
                    end

                    local tab = pandoc.SimpleTable(
                    caption,
                    aligns,
                    widths,
                    headers,
                    rows
                    )

                    local stab = pandoc.utils.from_simple_table(tab)
                    
                    table.insert(doc,stab)


                --else
                    --print("Cant find range for",v["name"])
                end
                
            end
        end
    end
    
    return doc
end

-- default values used when using stdin
local function default_opts() 
    return {
        header= true,
        headerlevel= 2,
        skiprows=0,
        sheets={},
        cellonly=nil,
        cellrange=nil,
        firstlineheader=true,
        headers= {},
        defwidth=0,
        widths= {},
        debug=false
    }
end


function Str(elem)
    local xfile,suffix = string.match(elem.text,"xlsx://(.-)[%?](.+)")
    if (xfile ~= nil) then
        local sheet = suffix:match("sheet=([^&]+)")
        local cell = suffix:match("cell=([^&]+)")

        if cell ~= nil and sheet ~= nil then
            local inp = assert(io.open(xfile, "rb"))
            local data = inp:read("*all")
            local opts = default_opts()
            table.insert(opts["sheets"],sheet)
            opts["cellonly"] = cell

            return XLSReadFile(xfile,data,opts)
        end
    end
    
end

-- when defined as a codeblock
function CodeBlock (cb)
  
    
    if #cb.attr.classes  > 0 then
        if (cb.attr.classes[1] == "xlsx") then
            local f = cb.attr.attributes["file"]
            local inp = assert(io.open(f, "rb"))
            local data = inp:read("*all")
            
            local opts = default_opts() 

            -- if a header should be printed
            if cb.attr.attributes["header"] ~= nil then
                opts["header"] = (cb.attr.attributes["header"] ~= "false")
            end

            -- what markdown header level should be chosen
            if cb.attr.attributes["headerlevel"] ~= nil then
                opts["headerlevel"] = tonumber(cb.attr.attributes["headerlevel"])
            end

            local sheets = {}
            
            rawparams = cb.text.."\n"
            --print(rawparams)
            svals = {"firstlineheader","skiprows","debug","defwidth","cellonly"}
            numvals = {"skiprows","defwidth"}

            for line in rawparams:gmatch("[^\r\n]+") do
                for n,multiv in string.gmatch(line,"([%w_]-): [%[]?(.-)[%]]?$") do
                    vs = {}
                    for v in string.gmatch(multiv,"[ ]*([^,]+)") do
                        table.insert(vs,v)
                        --print(n,v)
                    end
                    if has_value(svals,n) then
                        if has_value(numvals,n) then
                            opts[n] = tonumber(vs[1])
                        else
                            opts[n] = vs[1]
                        end
                    else
                        opts[n] = vs
                    end
                end
            end
            
            return XLSReadFile(f,data,opts)
        end
    end
end

-- when reading from stdin
function ByteStringReader (input)
    return pandoc.Pandoc(XLSReadFile("stdin",input,default_opts()))
end