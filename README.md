# pandoc-lua-timo-filters


| plugin          | description                                            |
|-----------------|--------------------------------------------------------|
| excelreader.lua | Reads data from xlsx files and produces a pandoc table |
| svgtofile.lua   | Inline svg filter (codeblock svg) with templating      |

All is MIT License

## Excelreader

Pretty bad excel reader. Doesn't use propper XML parser so breaks faster than a flinstone car. It is only meant to extract some strings and values.

Creates table from excel sheets. Every sheets get a header 1 and the sheet is converted to a cell. Only keeps the value of course
```bash
pandoc -f excelreader.lua -t gfm exceltest.xlsx
```
Soon you will wonder, did I create the header table manually?

Or also inline. header false means that a title will not be added in front of the table

* Sheets is a list of sheet separated by ,
* firstlineheader decides if a the first row is the header row. If it is not you might set headers with headers. Most likely works only well when you use 1 sheet only or the sheets are all the same
* Widths is a list of column widths. If not all columns are separated, the remaining space is divided over the remaining columns. Eg 3 columns but one define with 0.2 results in budget = 1-0.2, budget over the remaining 2 columns is 0.4 per column. Alternative use defwidth to set up a default width instead of using a budget calculation.

This does not use a real yaml parser, so stick to the format 
````markdown
```xlsx {file="myexcel.xlsx" header="false"}
sheets: [Data]
widths: [0.2]
firstlineheader: false
headers: [Head 1,Head 2]
```
````

## Svgtofile

Will convert the inline svg to real files
```bash
pandoc -L svgtofile.lua -o mydoc.docx svgtofiledemo.md
```

