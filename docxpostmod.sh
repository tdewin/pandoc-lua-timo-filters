#!/bin/bash

# Complete sample for unix based systems
REFDOC=testout/reference.docx
pandoc --print-default-data-file=reference.docx > $REFDOC

# Set theme color
pandoc lua docxpostmod.lua $REFDOC -action=updatecolor\
 -name="dk1,lt1,dk2,lt2,accent1,accent2,accent3,accent4,accent5,accent6,hlink,folHlink"\
 -val="222222,fafafa,333333,eeeeee,E63462,F79256,FBD1A2,7DCFB6,00B2CA,1D4E89,333745,C7EFCF"
# Set A4 (vs default US)
pandoc lua docxpostmod.lua $REFDOC -action=mod -pgSz="a4" -docOrient="portrait"
# First page is different
pandoc lua docxpostmod.lua $REFDOC -action=mod -titlePg=1
# Poppins as default fault instead of 2000 Calibri
pandoc lua docxpostmod.lua $REFDOC -action=updatefont -fontCat=major -font="Poppins" 
pandoc lua docxpostmod.lua $REFDOC -action=updatefont -fontCat=minor -font="Poppins"

# Update everything to align start (left)
pandoc lua docxpostmod.lua $REFDOC -action=updatestyle -name="AbstractTitle" -rPr="sz,szCs,b" -val="20,20"
pandoc lua docxpostmod.lua $REFDOC -action=updatestyle -name="AbstractTitle" -pPr="jc,spacing,keepNext,keepLines,pageBreakBefore" -val="start,{before:12800;after:0}"
pandoc lua docxpostmod.lua $REFDOC -action=updatestyle -name="Date" -pPr="jc,keepNext,keepLines" -val="start"
pandoc lua docxpostmod.lua $REFDOC -action=updatestyle -name="Author" -pPr="jc,keepNext,keepLines" -val="start"
pandoc lua docxpostmod.lua $REFDOC -action=updatestyle -name="Title" -pPr="jc,spacing,keepNext,keepLines" -val="start,{before:4800;after:240}"
pandoc lua docxpostmod.lua $REFDOC -action=updatestyle -name="Subtitle" -pPr="jc,spacing,keepNext,keepLines" -val="start,{before:240;after:240}"
pandoc lua docxpostmod.lua $REFDOC -action=updatestyle -name="VerbatimChar" -rPr="sz,rFonts,color" -val="22,{ascii:Cascadia Code;hAnsi:Cascadia Code},{themeColor:accent2}"
pandoc lua docxpostmod.lua $REFDOC -action=updatestyle -name="Hyperlink" -rPr="color" -val="{themeColor:accent5}"

# Make heading 1 do a pageBreak so every chapters start a new page
pandoc lua docxpostmod.lua $REFDOC -action=updatestyle -name="Heading1" -pPr="jc,spacing,outlineLvl,keepNext,keepLines,pageBreakBefore" -val="start,{before:480;after:0},0"

# Create an AltHeader with different color
pandoc lua docxpostmod.lua $REFDOC -action=addstyle -name="AltHeader1"
pandoc lua docxpostmod.lua $REFDOC -action=updatestyle -name="AltHeader1" -pPr="jc,spacing,outlineLvl,keepNext,keepLines,pageBreakBefore" -val="start,{before:480;after:0},0"
pandoc lua docxpostmod.lua $REFDOC -action=updatestyle -name="AltHeader1" -rPr="sz,szCs,rFonts,color,b" -val="32,32,{asciiTheme:majorHAnsi;hAnsiTheme:majorHAnsi},{themeColor:accent4}"

# Create a custom table style.
pandoc lua docxpostmod.lua $REFDOC -action=addtabstyle --name="customtab"

pandoc -o testout/docxpostmod.docx --toc --reference-doc=testout/reference.docx docxpostmod.md --highlight-style=monochrome

# to apply the custom table style
pandoc lua docxpostmod.lua testout/docxpostmod.docx -tblStyle="customtab"