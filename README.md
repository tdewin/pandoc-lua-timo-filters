# pandoc-lua-timo-filters


| plugin          | description                                            |
|-----------------|--------------------------------------------------------|
| excelreader.lua | Reads data from xlsx files and produces a pandoc table |
| svgtofile.lua   | Inline svg filter (codeblock svg) with templating      |

All is MIT License

## Excelreader

Creates table from excel sheets. Every sheets get a header 1 and the sheet is converted to a cell. Only keeps the value of course
```bash
pandoc -f excelreader.lua -t gfm exceltest.xlsx
```
Soon you will wonder, did I create the header table manually?

## Svgtofile

Will convert the inline svg to real files
```bash
pandoc -L svgtofile.lua -o mydoc.docx test.md
```

