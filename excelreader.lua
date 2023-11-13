-- Pretty bad excel reader for pandoc
-- github.com/tdewin/pandoc-lua-timo-filters
-- MIT license

function zip_get_entry(openzip,path)
    for i,entry in pairs(openzip.entries) do
        if entry["path"] == path then
            return (entry["contents"])(entry)
        end
    end
    return ""
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
function patternTag(tag)
    return "<"..tag.." [%w%\"=: /%.]+/>"
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

function ByteStringReader (input)
    local openzip = pandoc.zip.Archive(input)

    local wb = zip_get_entry(openzip,"xl/workbook.xml")
    local rwb = zip_get_entry(openzip,"xl/_rels/workbook.xml.rels")
    local shst =  zip_get_entry(openzip,"xl/sharedStrings.xml")
    doc = {}

    
    local patternAttr = "([%w:]+)=\"([^\"]+)\""

    local sheets = {}
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
        end
    end

    sharedStrings = {}
    s=0
    for w in string.gmatch(shst, "<si><t>([^<]+)</t></si>") do
        sharedStrings[s] = w
        s = s+1
    end

    --for i,w in pairs(sharedStrings) do
    --    print(i,w)
    --end

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

    for n,v in pairs(sheets) do
        if (rels[v["rid"]]) then
            local cont = zip_get_entry(openzip,"xl/"..rels[v["rid"]]["Target"])
            if (cont ~= nil and cont ~= "") then
                local sstart,send = string.match(cont, "<dimension ref=\"([%a]+[%d]+):([%a]+[%d]+)\"/>")
                if (sstart) then
                    --A1:C5
                    --A=65
                    
                    local sx,sy = XLScoord(sstart)
                    local ex,ey = XLScoord(send)
                    
                   
                    colsn = ex-sx+1
                    rowsn = ey-sy+1
                    
                    local rows = {}
                    local headers = {}

                    for c=1,colsn do
                        table.insert(headers,"")
                    end
                    for r=2,rowsn do
                        cols = {}
                        for c=1,colsn do
                            table.insert(cols,"")
                        end
                        table.insert(rows,cols)
                    end
                    
                    for rown,row in string.gmatch(cont,"<row r=\"([%d]+)\"(.-)</row>") do
                       for celln,t,cell in string.gmatch(row,"<c r=\"([%a]+[%d]+)\"(.-)>(.-)</c>") do
                            local v = string.match(cell,"<v>(.-)</v>")
                            if v then
                                local col,row = XLScoord(celln)
                                local localcol = col-sx+1
                                local localrow = row-sy+1
                                local cv = v
                                if string.find(t,"t=\"s\"") then
                                    cv = sharedStrings[tonumber(v)]
                                end
                                if localrow == 1 then
                                    headers[localcol] = cv
                                else
                                    rows[localrow-1][localcol] = cv
                                end
                            end
                       end
                    end
                    

                    table.insert(doc,pandoc.Header(1,pandoc.Str(v["name"])))
                    local caption = ""
                    local aligns = {}
                    local widths = {} 
                    

                    colwidth = (1/colsn)--creates a nice full width table in docx

                    for i=1,colsn do
                        table.insert(aligns,pandoc.AlignDefault)
                        table.insert(widths,colwidth)
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
    
    return pandoc.Pandoc(doc)
end
