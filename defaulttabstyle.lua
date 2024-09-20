-- run with                                                                                
-- -L defaulttablestyle.lua -M tablestyle:mystyle
-- set a custom tab style for docx output
-- only works with pandoc 3.4>
-- set a style for a table with a codeblock called meta data 
-- ```tablemeta {custom-style=tablestyle}
-- ```
-- the style will reset to default supplied by meta so every custom table should be decorated with a codeblock
                                                                                      
local tablestyle = "table"
local tablestylemeta = "table"

-- tablestylemeta set the default style
function Meta(meta)                                                               
 if meta.tablestyle ~= nil then 
  tablestylemeta = meta.tablestyle
  tablestyle = tablestylemeta                                                                  
 end                                                                                 
end 

function CodeBlock(elem)
  cs = elem.attr.attributes["custom-style"]
  if elem.attr.classes[1] == "tablemeta" and cs ~= nil then
    tablestyle = cs
    return {}
  end
end

function Table(elem)                                                                                                                                                      
 if elem.attr.attributes["custom-style"] == nil then
  elem.attr.attributes["custom-style"] = tablestyle
 end

 tablestyle = tablestylemeta
 return elem                                                                                
end 

return {                                      
  {Meta = Meta},
  {CodeBlock = CodeBlock, Table = Table}
} 

