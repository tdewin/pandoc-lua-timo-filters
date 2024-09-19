-- run with                                                                                                                                                                 
-- -L defaulttabstyle.lua -M tabstyle:mystyle
-- set a custom tab style for docx output
-- only works with pandoc 3.4>
                                                                                                                                                                            
local tabstyle = "table"                                                                                                                                                    
                                                                                                                                                                            
function Meta(meta)                                                                                                                                                         
        if meta.tabstyle ~= nil then                                                                                                                                        
                tabstyle = meta.tabstyle                                                                                                                                    
        end                                                                                                                                                                 
                                                                                                                                                                            
end                                                                                                                                                                         
                                                                                                                                                                            
function Table(elem)                                                                                                                                                                                                                                                                                                                 
  if elem.attr.attributes["custom-style"] == nil then                                                                                                                       
    elem.attr.attributes["custom-style"] = tabstyle                                                                                                                         
  end                                                                                                                                                                       
  return elem                                                                                                                                                               
end                                                                                                                                                                         
                                                                                                                                                                            
return {                                                                                                                                                                    
  {Meta = Meta},                                                                                                                                                            
  {Table = Table}                                                                                                                                                           
} 
