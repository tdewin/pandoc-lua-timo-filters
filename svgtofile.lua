local templates = {}

function CodeBlock (cb)
  for k,v in pairs(cb) do
    --print("key", k, "value", v)
  end
  if #cb.attr.classes  > 0 then
	data = cb.text

	fromfile = cb.attr.attributes["fromfile"]
	wasfromfile = false

	if (fromfile ~= nil and fromfile ~= "") then
		file = io.open ( fromfile, "r")
		io.input(file)
		filedata = io.read("*all")
		io.close(file)

		data = filedata
		wasfromfile = true
	end


	if (cb.attr.classes[1] == "template" and cb.attr.attributes["name"]) then
		templates[cb.attr.attributes["name"]] = data
		return {}
	end
	-- Very minimal
	if (cb.attr.classes[1] == "use" and cb.attr.attributes["ref"]) then
		template = templates[cb.attr.attributes["ref"]]
		if ( template ~= nil) then
			ind = 0
			vartext = "" .. data


			rettable = {}
			for block in string.gmatch( "---" .. vartext .. "---","(.-)%-%-%-") do
				if (block ~= nil and block ~= "") then
					tmptpl = "" .. template
					ind = ind+1
					
					for line in string.gmatch(block .. "\n", "(.-)\n") do
						
						local si, sj = string.find(line, ": ")
						
						if (si and sj ) then
							--print(line,si,sj)
							n = string.sub(line, 0, si-1)
							v = string.sub(line,sj+1,#line)

							v = v:gsub("%%","%%%%")
							tmptpl = tmptpl:gsub("{{" .. n .. "}}", v)

						end
						
					end
					table.insert(rettable,tmptpl)
					
				end
			end

			inceptionmarkdown = table.concat(rettable,"")
			blockdata = cb.attr.attributes["blockdata"]
			if (blockdata ~= nil and wasfromfile) then
				if blockdata == "append" then
					inceptionmarkdown = inceptionmarkdown .. cb.text
				elseif blockdata == "insert" then
					inceptionmarkdown = cb.text .. inceptionmarkdown
				end
			end

			return pandoc.read(inceptionmarkdown, "markdown").blocks
		end
		return {pandoc.Str(out)}
	end
	if (cb.attr.classes[1] == "svg" and cb.attr.attributes["out"]) then
		fname = cb.attr.attributes["out"] .. ".svg"

		rettable = {}

		if (cb.attr.attributes["ref"]) then
			--out = "<svg height='40' width='600'><text x='0' y='30'  class='text'>Template Not Found</text></svg>"
			
			template = templates[cb.attr.attributes["ref"]]
			nf = cb.attr.attributes["namefield"]
			if ( template ~= nil) then
				vartext = data

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
			io.write(data)
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


