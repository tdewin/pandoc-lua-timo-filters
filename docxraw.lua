function CodeBlock (cb)
    if #cb.attr.classes  > 0 then
        docxraw = cb.attr.classes[1]:match("docxraw.([^%s]+)")
        if docxraw ~= nil then
            if docxraw == "pagebreak" then
                return pandoc.RawInline("openxml", "<w:br w:type=\"page\"/>")
            elseif docxraw == "spacer" then
                local space = 2500
                if cb.attr.attributes["space"] then
                    space = cb.attr.attributes["space"]
                end
                local oxml = table.concat({
                    "<w:pPr>",
                    "<w:spacing w:before=\""..space.."\"/>",
                    "</w:pPr>",
                    "<w:r>",
                    "<w:t></w:t>",
                    "</w:r>",
                },"")
                print(oxml)
                return pandoc.RawInline("openxml", oxml)
            elseif docxraw == "toc" then
                local oxml = {"<w:sdt>",
"            <w:sdtPr>",
"                <w:docPartObj>",
"                    <w:docPartGallery w:val=\"Table of Contents\"/>",
"                    <w:docPartUnique/>",
"                </w:docPartObj>",
"            </w:sdtPr>",
"            <w:sdtEndPr>",
"                <w:rPr>",
"                    <w:rFonts w:asciiTheme=\"minorHAnsi\" w:eastAsiaTheme=\"minorHAnsi\" w:hAnsiTheme=\"minorHAnsi\" w:cstheme=\"minorBidi\"/>",
"                    <w:b/>",
"                    <w:bCs/>",
"                    <w:noProof/>",
"                    <w:color w:val=\"auto\"/>",
"                    <w:sz w:val=\"24\"/>",
"                    <w:szCs w:val=\"24\"/>",
"                </w:rPr>",
"            </w:sdtEndPr>",
"            <w:sdtContent>",
"                <w:p>",
"                    <w:pPr>",
"                        <w:pStyle w:val=\"TOCHeading\"/>",
"                    </w:pPr>",
"                    <w:r>",
"                        <w:t>Contents</w:t>",
"                    </w:r>",
"                </w:p>",
"                <w:p>",
"                    <w:pPr>",
"                        <w:pStyle w:val=\"TOC1\"/>",
"                        <w:tabs>",
"                            <w:tab w:val=\"right\" w:leader=\"dot\" w:pos=\"9350\"/>",
"                        </w:tabs>",
"                        <w:rPr>",
"                            <w:noProof/>",
"                        </w:rPr>",
"                    </w:pPr>",
"                    <w:r>",
"                        <w:fldChar w:fldCharType=\"begin\" w:dirty=\"true\" />",
"                    </w:r>",
"                    <w:r>",
"                        <w:instrText xml:space=\"preserve\"> TOC \\o \"1-3\" \\h \\z \\u </w:instrText>",
"                    </w:r>",
"                    <w:r>",
"                        <w:fldChar w:fldCharType=\"separate\"/>",
"                    </w:r>",
"                </w:p>",
"                <w:p>",
"                    <w:r>",
"                        <w:rPr>",
"                            <w:b/>",
"                            <w:bCs/>",
"                            <w:noProof/>",
"                        </w:rPr>",
"                        <w:fldChar w:fldCharType=\"end\"/>",
"                    </w:r>",
"                </w:p>",
"            </w:sdtContent>",
"</w:sdt>",
""}
                return pandoc.RawInline("openxml", table.concat(oxml,"\n"))
            end
        end
    end
end