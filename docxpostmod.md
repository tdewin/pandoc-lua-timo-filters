---
author: Timo
title: All custom docx
subtitle: With sub
date: 2024
abstract-title: "Disclaimer:"
abstract: |
  Watch out, this is too cool! You might actually start loving pandoc.
---


# Header

 | Header 1		 | Header 2		  |
 |--------------|------------|
 | Cell 1		 | Cell 2		  |

# How To 
 
Create a reference doc and instantly update its colors
```bash
pandoc --print-default-data-file=reference.docx > testout/reference.docx
pandoc lua docxpostmod.lua testout/reference.docx -action=updatecolor\
 -name="dk1,lt1,dk2,lt2,accent1,accent2,accent3,accent4,accent5,accent6,hlink,folHlink"\
 -val="222222,fafafa,333333,eeeeee,E63462,F79256,FBD1A2,7DCFB6,00B2CA,1D4E89,333745,C7EFCF"
pandoc lua docxpostmod.lua testout/reference.docx -action=updatefont -fontCat=major -font="Tahoma" 
pandoc lua docxpostmod.lua testout/reference.docx -action=updatefont -fontCat=minor -font="Tahoma"
pandoc lua docxpostmod.lua testout/reference.docx -action=mod -pgSz="a4" -docOrient="portrait"
pandoc lua docxpostmod.lua testout/reference.docx -action=mod -titlePg=1
```

tbh i like [Poppins](https://fonts.google.com/specimen/Poppins)
```bash
pandoc lua docxpostmod.lua testout/reference.docx -action=updatefont -fontCat=major -font="Poppins" 
pandoc lua docxpostmod.lua testout/reference.docx -action=updatefont -fontCat=minor -font="Poppins"
```

hard style updating
```bash
pandoc lua docxpostmod.lua testout/reference.docx -action=liststyles

pandoc lua docxpostmod.lua testout/reference.docx -action=liststyle -name="AbstractTitle"
pandoc lua docxpostmod.lua testout/reference.docx -action=updatestyle -name="AbstractTitle" -rPr="sz,szCs,b" -val="20,20"
pandoc lua docxpostmod.lua testout/reference.docx -action=updatestyle -name="AbstractTitle" -pPr="jc,spacing,keepNext,keepLines,pageBreakBefore" -val="start,{before:300;after:0}"

pandoc lua docxpostmod.lua testout/reference.docx -action=liststyle -name="Date" 
pandoc lua docxpostmod.lua testout/reference.docx -action=updatestyle -name="Date" -pPr="jc,keepNext,keepLines" -val="start"

pandoc lua docxpostmod.lua testout/reference.docx -action=liststyle -name="Author"
pandoc lua docxpostmod.lua testout/reference.docx -action=updatestyle -name="Author" -pPr="jc,keepNext,keepLines" -val="start"

pandoc lua docxpostmod.lua testout/reference.docx -action=liststyle -name="Title"
pandoc lua docxpostmod.lua testout/reference.docx -action=updatestyle -name="Title" -pPr="jc,spacing,keepNext,keepLines" -val="start,{before:4800;after:240}"

pandoc lua docxpostmod.lua testout/reference.docx -action=liststyle -name="Subtitle"
pandoc lua docxpostmod.lua testout/reference.docx -action=updatestyle -name="Subtitle" -pPr="jc,spacing,keepNext,keepLines" -val="start,{before:240;after:240}"


pandoc lua docxpostmod.lua testout/reference.docx -action=liststyle -name="VerbatimChar"
pandoc lua docxpostmod.lua testout/reference.docx -action=updatestyle -name="VerbatimChar" -rPr="sz,rFonts,color" -val="22,{ascii:Cascadia Code;hAnsi:Cascadia Code},{themeColor:accent2}"

pandoc lua docxpostmod.lua testout/reference.docx -action=liststyle -name="Hyperlink"
pandoc lua docxpostmod.lua testout/reference.docx -action=updatestyle -name="Hyperlink" -rPr="color" -val="{themeColor:accent5}"

pandoc lua docxpostmod.lua testout/reference.docx -action=liststyle -name="Heading1"
pandoc lua docxpostmod.lua testout/reference.docx -action=updatestyle -name="Heading1" -pPr="jc,spacing,outlineLvl,keepNext,keepLines,pageBreakBefore" -val="start,{before:480;after:0},0"

pandoc lua docxpostmod.lua $REFDOC -action=addstyle -name="AltHeader1"
pandoc lua docxpostmod.lua $REFDOC -action=updatestyle -name="AltHeader1" -pPr="jc,spacing,outlineLvl,keepNext,keepLines,pageBreakBefore" -val="start,{before:480;after:0},0"
pandoc lua docxpostmod.lua $REFDOC -action=updatestyle -name="AltHeader1" -rPr="sz,szCs,rFonts,color,b" -val="32,32,{asciiTheme:majorHAnsi;hAnsiTheme:majorHAnsi},{themeColor:accent4}"
pandoc lua docxpostmod.lua $REFDOC -action=liststyle -name="AltHeader1"
```

::: {custom-style="AltHeader1"}
Custom Style
:::

<https://github.com/tdewin/pandoc-lua-timo-filters>

Check if your style made it in the doc. Use the name listed here (spaces might be removed)
```bash
pandoc lua docxpostmod.lua testout/reference.docx -action=liststyles -filter=table 
pandoc lua docxpostmod.lua testout/reference.docx -action=addtabstyle --name="customtab"
```

Make a new style called customtabstyle.
```bash
pandoc -o testout/docxpostmod.docx --toc --reference-doc=testout/reference.docx docxpostmod.md --highlight-style=monochrome
pandoc lua docxpostmod.lua testout/docxpostmod.docx -tblStyle="customtab"
```

Or some post replacers. For example a test about {{animaltype}} being the coolest animals in the world. Probably you want to create your own lua filter that replaces string but this is just for editing the end xml directly (you can use -action=dump to dump the xml to console or -action=listfiles to list file and use -file to select the non default document file)
```bash
pandoc lua docxpostmod.lua testout/docxpostmod.docx -repl="{{animaltype}}" -val="dogs"
```