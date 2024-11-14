-- run with                                                                                
-- -L defaulttablestyle.lua -M tablestyle:mystyle
-- set a custom tab style for docx output
-- only works with pandoc 3.4>
-- set a style for a table with a codeblock called meta data 
-- ```tablemeta {custom-style=tablestyle}
-- ColWidth=0.5,0.5
-- ```
-- If you define ColWidth, the numbers of columns has to match the amount of number you list. If you want full length, the sum of these floating numbers should add up to 1, eg 0.5+0.5=1 or 0.25+0.75=1
-- the style will reset to default supplied by meta so every custom table should be decorated with a codeblock
                                                                                      
local tablestyle = "table"
local tablestylemeta = "table"
local ColWidth = {}

-- tablestylemeta set the default style
function Meta(meta)                                                               
 if meta.tablestyle ~= nil then 
  tablestylemeta = meta.tablestyle
  tablestyle = tablestylemeta                                                                  
 end                                                                                 
end 

function CodeBlock(elem)
  --https://pandoc.org/lua-filters.html#type-codeblock
 
  if elem.attr.classes[1] == "tablemeta" then
    cs = elem.attr.attributes["custom-style"]
    if cs ~= nil then
      tablestyle = cs
    end 
    
    local txt = elem.text
    if  txt ~= nil and txt ~= "" then
      for n,v in txt:gmatch("([^=]*)=([^\n]*)\n*") do
        if n == "ColWidth" then
          for colwidth in v:gmatch("([^,]*),*") do
            table.insert(ColWidth,tonumber(colwidth))
          end
        end
      end
    end

    return {}
  end

  
end

function Table(elem)   
 --https://pandoc.org/lua-filters.html#type-table                                                                                                                                                   
 if elem.attr.attributes["custom-style"] == nil then
  elem.attr.attributes["custom-style"] = tablestyle
 end

 if #ColWidth> 0 then
   for n,v in pairs(ColWidth) do
     --https://pandoc.org/lua-filters.html#type-colspec
     elem["colspecs"][n][2] = v
   end
 end

 tablestyle = tablestylemeta
 ColWidth = {}
 return elem                                                                                
end 

return {                                      
  {Meta = Meta},
  {CodeBlock = CodeBlock, Table = Table}
} 

