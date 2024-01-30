-- this is not a filter but a utility
-- in json 
-- 100pct=50 30% 40% 30%
-- echo '[["col1","col2","col3"],[1,2,"dont split this text because it is gfmtab. I mean it is pretty but this is what is the challening part when dealing with tables"],[3,4,5]]' | pandoc lua util-jsontable-to-gfmtab.lua 80 20 20 60 > util-jsontable.md 
-- or if you just want to draw the grid
-- echo '[["","","",""],["","","",""],["","","",""]]' | pandoc lua util-jsontable-to-gfmtab.lua 80 20 20 40 20 > util-jsontable.md 
-- or some idea
-- echo '[["&#128161;","This is a very good idea in a table"]]' | pandoc lua util-jsontable-to-gfmtab.lua 80 15 85 > util-jsontable.md 
data = io.read("*a");
j=pandoc.json.decode(data);

total = tonumber(arg[1])

headers = {}
for i,v in ipairs(arg) do
    if i > 1 then
        table.insert(headers,math.floor((total/100*tonumber(v)))-3)
    end
end

newtotal = -1
for i,v in ipairs(headers) do
    newtotal = newtotal+v+3
end

-- adjust to match
headers[#headers] = headers[#headers] + total-newtotal-2

function writesplit (headers,splitter,sep)
    io.write(sep)
    for i,v in ipairs(headers) do
        for i=1,v+2 do 
            io.write(splitter)
        end
        io.write(sep)
    end
    io.write("\n")
end




for rowi,row in ipairs(j) do 
    
    hasnext = true
    ln=0

    strtab = {}
    for celli,uncell in ipairs(row) do
        table.insert(strtab,tostring(uncell))
    end


    io.write("|")

        
    for celli,uncell in ipairs(strtab) do
            cell = uncell
            collen =  headers[celli]
            io.write(string.format(" %-"..collen.."s |",cell))
    end
    io.write("\n")
   
    if rowi == 1 then
        writesplit(headers,"-","|")
    end
    
end