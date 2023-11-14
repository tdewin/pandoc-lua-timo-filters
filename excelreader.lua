

local function zip_get_entry(openzip,path)
    for i,entry in pairs(openzip.entries) do
        if entry["path"] == path then
            return (entry["contents"])(entry)
        end
    end
    return ""
end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end
---
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

local function log(debug,line)
    if(debug) then
        print("[DEBUG] "..line)
    end
end
local function XLSReadFile(input,opts)
    local openzip = pandoc.zip.Archive(input)

    local wb = zip_get_entry(openzip,"xl/workbook.xml")
    local rwb = zip_get_entry(openzip,"xl/_rels/workbook.xml.rels")
    local shst =  zip_get_entry(openzip,"xl/sharedStrings.xml")
    doc = {}

    debug = (opts["debug"] ~= false)

    log(debug,"Debugging Enabled")
    
    
    local patternAttr = "([%w:]+)=\"([^\"]+)\""

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

    sharedStrings = {}
    s=0
    --log(debug,"Shared string "..shst)
    for w in string.gmatch(shst, "<si[^<]*><t[^<]*>([^<]+)</t></si>") do
        log(debug,"Shared string "..s.." "..w)
        sharedStrings[s] = w
        s = s+1
        
    end



    rels = {}
    for w in string.gmatch(rwb, patternTag("Relationship")) do
        local m = {Id="-",Type="-",Target="-"}

        for attr,v in string.gmatch(w,patternAttr) do
            if m[attr] == "-" then
                m[attr] = v
            end
        end
        
        if m["Id"] ~= "-" and m["Type"] ~= "-" and m["Target"] ~= "-" then
            rels[m["Id"]] = m
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
                local sstart,send = string.match(cont, "<dimension ref=\"([%a]+[%d]+):([%a]+[%d]+)\"/>")
                
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
                    
                    for rown,row in string.gmatch(cont,"<row r=\"([%d]+)\"(.-)</row>") do
                       log(debug,"Row "..rown)
                       for celln,t,cell in string.gmatch(row,"<c r=\"([%a]+[%d]+)\"(.-)>(.-)</c>") do
                            local v = string.match(cell,"<v>(.-)</v>")
                            log(debug,"Cell "..celln.." "..v.." "..t)
                            if v then
                                local col,row = XLScoord(celln)
                                local localcol = col-sx+1
                                local localrow = row-sy+1

                                if localrow > 0 then
                                    local cv = v
                                    if string.find(t,"t=\"s\"") then
                                        cv = sharedStrings[tonumber(v)]
                                        if cv == nil then
                                            cv = v
                                            log(debug,"Err SS lookup "..v.."in"..celln)
                                        end
                                    end
                                    if notflh or localrow ~= 1 then
                                        local rowcoord = localrow-rplus
                                        rows[rowcoord][localcol] = cv

                                        log(debug,"Setting cell "..rowcoord.." "..localcol..":")
                                        log(debug,cv)
                                    else
                                        headers[localcol] = cv
                                        log(debug,"Setting header"..localcol.." "..cv)
                                    end
                                end
                            end
                       end
                    end
                    

                    if opts["header"] then 
                        table.insert(doc,pandoc.Header(opts["headerlevel"],pandoc.Str(v["name"])))
                    end
                    local caption = ""
                    local aligns = {}
                    local widths = {} 
                    
                    

                    for i=1,colsn do
                        table.insert(aligns,pandoc.AlignDefault)
                        
                    end

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

local function default_opts() 
    return {
        header= true,
        headerlevel= 2,
        skiprows=0,
        sheets={},
        firstlineheader=true,
        headers= {},
        defwidth=0,
        widths= {},
        debug=false
    }
end

function CodeBlock (cb)
  
    
    if #cb.attr.classes  > 0 then
        if (cb.attr.classes[1] == "xlsx") then
            local f = cb.attr.attributes["file"]
            local inp = assert(io.open(f, "rb"))
            local data = inp:read("*all")
            
            local opts = default_opts() 

            if cb.attr.attributes["header"] ~= nil then
                opts["header"] = (cb.attr.attributes["header"] ~= "false")
            end

            if cb.attr.attributes["headerlevel"] ~= nil then
                opts["headerlevel"] = tonumber(cb.attr.attributes["headerlevel"])
            end

            local sheets = {}
            
            rawparams = cb.text.."\n"
            --print(rawparams)
            svals = {"firstlineheader","skiprows","debug","defwidth"}
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

            return XLSReadFile(data,opts)
        end
    end
end

function ByteStringReader (input)
    return pandoc.Pandoc(XLSReadFile(input,default_opts()))
end