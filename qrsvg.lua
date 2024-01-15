-- use qrencode by http://speedata.github.io/luaqrcode/)
-- see qrencode.lua for full reference
-- bugs in the encoding should be reported there
local qrencode = dofile("qrencode.lua")


function tag_opts() 
    return {
        attr = {},
        printend = false,
        ns = ""
    }
end
function closed_tag_opts(attr) 
    local opts = tag_opts()
    opts.attr = attr
    opts.printend = true
    return opts
end
function open_tag_opts(attr) 
    local opts = tag_opts()
    opts.attr = attr
    opts.printend = false
    return opts
end
--add a new element to the the stream and stack
--you can close it by using pop(doc)
--printend means the element should instantly be closed
function add_starttag(doc,tag,opts)
    local attr = opts.attr
    local printend = opts.printend

    local str = ""
    
    for i=1,#doc.stack do 
        str=str.." " 
    end

    local ns = opts.ns
    if ns ~= "" then
        ns = ns..":"
    end
    str = str.."<"..ns..tag

    for k,v in pairs(attr) do
        str = str .. " "..k.."=\""..v.."\""
    end
    if printend then
        str = str .."/"
    else
        table.insert(doc.stack,tag)
    end
    str = str .. ">"
    table.insert(doc.stream,str)
end
-- creates an xml doc
function create_doc()
    local doc = {stream={},stack={}}
    return doc
end
-- closes the latest tag
-- it return the element so popAll can detect end of stack
function pop(doc)
    if (#doc.stack > 0) then
        local n = #doc.stack
        local pop = doc.stack[n]

        local str = ""
        for i=2,#doc.stack do 
            str=str.." " 
        end
        str = str.."</"..pop..">"
    
        table.insert(doc.stream,str)
        table.remove(doc.stack,n)
        return n
    end
    return nil
end
-- closes all the open elements
-- useful at the end of the document to close everything at once
function popAll(doc)
    while pop(doc) ~= nil do
    end
end

-- explicit endtag
-- should not really be used
function add_endtag(doc,tag)
    table.insert(doc.stream,"</"..tag..">")
end

function encode_msg(opts)
    local ok, tab_or_message = qrencode.qrcode(opts.codeword)
    if not ok then
        print(tab_or_message)
    else
        local svg = create_doc()
        
        local tab = tab_or_message
        local docsz = opts.docsz
        local sqsz = opts.sqsz
        local bleed = opts.bleed

        if docsz:match("near([0-9]+)") then
            local n = tonumber(docsz:match("near([0-9]+)"))
            sqsz = math.floor(n/(#tab+6))
            if sqsz < 1 then
                sqsz = 1
            end

            bleed = sqsz/50

            docsz = sqsz*(#tab+6)
        end

        local padding = sqsz*3

        
        local padbleed = padding-bleed
        local sqszbleed = sqsz+bleed+bleed


        local sz = (#tab*sqsz)+(padding*2)

        if docsz == "auto" then
            docsz = sz
        end

        --print(docsz)
        
        

        --stroke for individual override
        local stylesq = "fill:"..opts.black..";stroke: "..opts.black..";stroke-width: 0;stroke-opacity: 0;"
        local stylebg = "fill:"..opts.white..";stroke: "..opts.black..";stroke-width: "..sqsz..";stroke-opacity: 1;"


        add_starttag(svg,"svg",open_tag_opts({width=docsz,height=docsz,viewBox="0 0 "..sz.." "..sz,xmlns="http://www.w3.org/2000/svg"}))
        add_starttag(svg,"g",open_tag_opts({id="qr"}))
        add_starttag(svg,"g",open_tag_opts({id="bg"}))
        add_starttag(svg,"rect",closed_tag_opts({id="bgrect",x=sqsz,y=sqsz,width=sz-(2*sqsz),height=sz-(2*sqsz),rx=(padding/2),style=stylebg}))
        pop(svg)
        add_starttag(svg,"g",open_tag_opts({id="frontsqs"}))
        for x=1,#tab do
            for y=1,#tab do
                if (tab[x][y] > 0) then
                    add_starttag(svg,"rect",closed_tag_opts({id=(x.."-"..y),x=((x-1)*sqsz+padbleed),y=((y-1)*sqsz+padbleed),width=sqszbleed,height=sqszbleed,rx=0,style=stylesq}))
                end
            end
        end
        popAll(svg)
      
        local svgout = table.concat(svg.stream,"\n")
        if (opts.file == "") then
            print(svgout)
        else
            --print("out: "..opts.file)
            ofile = io.open(opts.file,"w")
            ofile:write(svgout)
            ofile:close()
        end
    end
end

function default_opts()
    return {
        codeword = nil,
        docsz = "near300",
        sqsz = 10,
        bleed = 0,
        black = "#333333",
        white = "#ffffff",
        file = "",
        alt = ""
    } 
end



function Image(elem)
    if (elem.src:match("qr://(.-)")) then
        local opts = default_opts()

        opts.codeword = pandoc.utils.stringify(elem.caption)
        opts.file = elem.src:match("qr://(.+)$")


        for n,v in pairs(elem.attr.attributes) do
            --print(n,v)
            opts[n] = v
        end

        encode_msg(opts)
        
        elem.src = opts.file
        return elem
      
    end
end

function Link(elem)
    if (elem.target:match("qr://(.-)")) then
        local opts = default_opts()

        opts.codeword = pandoc.utils.stringify(elem.content)
        opts.file = elem.target:match("qr://(.+)$")


        for n,v in pairs(elem.attr.attributes) do
            --print(n,v)
            opts[n] = v
        end

        encode_msg(opts)

        local txt = opts.codeword
        if opts.alt ~= "" then
            txt = opts.alt
        end
        
        local img = pandoc.Image({pandoc.Str(txt)}, opts.file)
        
        return img
      
    end
end

function CodeBlock(cb)
    if #cb.attr.classes  > 0 then
        qr = cb.attr.classes[1]:match("qr://(.+)$")
        if qr then
            local opts = default_opts()

            opts.codeword = cb.text
            opts.file = qr

            for n,v in pairs(cb.attr.attributes) do
                --print(n,v)
                opts[n] = v
            end

            encode_msg(opts)
            local img = pandoc.Image({pandoc.Str(opts.alt)}, opts.file)
            
            return img
        end
    end
end

if arg then
    local opts = default_opts()

    while true do
        if arg[1] == nil then
            break
        elseif arg[1] == "-h" or arg[1] == "--help" then
            opts.codeword = nil
            break
        elseif arg[1] == "-d" then
            opts.black = arg[2]
            table.remove(arg,2)
        elseif arg[1] == "-l" then
            opts.white = arg[2]
            table.remove(arg,2)
        elseif arg[1] == "-p" then
            opts.docsz = arg[2]
            table.remove(arg,2)
        elseif arg[1] == "-s" then
            opts.sqsz = tonumber(arg[2])
            table.remove(arg,2)
        elseif arg[1] == "-b" then
            opts.bleed = tonumber(arg[2])
            table.remove(arg,2)
        elseif arg[1] == "-f" then
            --if "" > stdout
            opts.file  = arg[2]
            table.remove(arg,2)
        else
            opts.codeword = arg[1]
        end
        table.remove(arg,1)
    end



    if opts.codeword then
        encode_msg(opts)
    else
        print("Usage:")
        print(arg[0] .. " [-f <>] [-l <>] [-d <>] [-p <>] [-s <>] [-b <>] \"<contents>\"")
        print("-f <file.svg>    : if empty, to stdout")
        print("-l <#ffffff>     : light color")
        print("-d <#333333>     : dark color")
        print("-p <300>         : define document height and width")
        print("-s <10>          : sq size of the block, impacts the viewbox")
        print("-b <0>           : bleed size relative to viewbox (makes the box bigger at all sides)")
        print("")
        --print("You can pipe to rsvg-convert to have png")
        --print("lua qrsvg.lua -p 400 -b 1 -l #eeffee  \"Convert to SVG and then to PNG\" | rsvg-convert -o qr.png -")
    end
end