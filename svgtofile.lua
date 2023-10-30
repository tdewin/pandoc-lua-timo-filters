local templates = {}

function CodeBlock (cb)
  for k,v in pairs(cb) do
    --print("key", k, "value", v)
  end
  if #cb.attr.classes  > 0 then
	if (cb.attr.classes[1] == "template" and cb.attr.attributes["name"]) then
		templates[cb.attr.attributes["name"]] = cb.text
		return {}
	end
	if (cb.attr.classes[1] == "svg" and cb.attr.attributes["out"]) then
		fname = cb.attr.attributes["out"] .. ".svg"
		out = cb.text

		rettable = {}

		if (cb.attr.attributes["ref"]) then
			out = "<svg height='40' width='600'><text x='0' y='30'  class='text'>Template Not Found</text></svg>"
			
			template = templates[cb.attr.attributes["ref"]]
			nf = cb.attr.attributes["namefield"]
			if ( template ) then
				vartext = cb.text 

				ind = 0
				for block in string.gmatch( "---" .. vartext .. "---","(.-)%-%-%-") do
					if (block ~= nil and block ~= "") then
						tmptpl = "" .. template
						ind = ind+1
						suffix = ind
						
						for line in string.gmatch(block .. "\n", "(.-)\n") do
							
							local si, sj = string.find(line, ": ")
							
							if (si and sj ) then
								--print(line,si,sj)
								n = string.sub(line, 0, si-1)
								v = string.sub(line,sj+1,#line)

								v = v:gsub("%%","%%%%")
								tmptpl = tmptpl:gsub("{{" .. n .. "}}", v)

								if (nf ~= nil and nf ~= "" and nf == n) then
									suffix = v
								end
							end
							
						end
						

						fname = cb.attr.attributes["out"] .. "-" .. suffix .. ".svg"
						--print(fname)

						file = io.open ( fname, "w")
						io.output(file)
						io.write(tmptpl)
						io.close(file)
			
						alt = fname
						if cb.attr.attributes["alt"] then
							alt = cb.attr.attributes["alt"].." "..suffix
						end
						table.insert(rettable,pandoc.Image(alt,fname))
					end
					
				end

				
			end
		else
			file = io.open ( fname, "w")
			io.output(file)
			io.write(out)
			io.close(file)

			alt = fname
			if cb.attr.attributes["alt"] then
				alt = cb.attr.attributes["alt"]
			end
			table.insert(rettable,pandoc.Image(alt,fname))
		end
		return {
			rettable
		}
		
	end
  end
  return cb
end


