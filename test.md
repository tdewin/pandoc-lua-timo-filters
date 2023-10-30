---
author: "@tdewin"
title: Demo of inline SVG
---


# Just Inline SVG
Svg inline (should be visible) without templating
```svg {out=./media/plain alt="Hello Plain SVG"}
<svg viewbox="0 0 560 110" width="14.82cm" height="2.91cm" xmlns="http://www.w3.org/2000/svg">
   <style>
  .text {
      font-family: Tahoma;
      font-size: 40;
      font-weight: bold;
      fill: #12d800;
    }
    .subtext {
      font-family: Tahome;
      font-size: 15;
      fill: #4f4f4f;
    }
  </style>

  <g>
    <text x="0%" y="60"  class="text">100%</text>
    <text x="50%" y="60" text-anchor="middle"  class="text">10</text>
    <text x="100%" y="60" text-anchor="end"  class="text">1</text>
  </g>

  <g>
    <text x="0%" y="90" class="subtext">Happy Users</text> 
    <text x="50%" y="90" text-anchor="middle"  class="subtext">Birds in the sky</text>
    <text x="100%" y="90" text-anchor="end"  class="subtext">SVG Format</text>
  </g>

</svg>
```

# Template
template (should not be visibe) in final document:
```template {name="digitx"}
<svg viewbox="0 0 200 120" width="200" height="120" xmlns="http://www.w3.org/2000/svg">
<defs>
  <linearGradient id="linear" x1="0%" y1="0%" x2="100%" y2="100%">
  <stop offset="0%" stop-color="#12d800"/>
  <stop offset="100%" stop-color="#00d8ad"/>
  </linearGradient>
</defs>
<style>
    .text {
      font-family: Tahoma;
      font-size: 50;
      font-weight: bold;
      fill: #12d800;
    }
    .subtext {
      font-family: Tahome;
      font-size: 15;
      fill: #4f4f4f;
    }
    rect {
      fill:#ffffff;
      stroke-width:3;
      stroke:url(#linear);
    } 
</style>
 <rect x="5%" y="5%" width="90%" height="90%" rx="5" ry="5"   ></rect>
 <text y="60" x="50%"  text-anchor="middle"  class="text">{{big}}</text>
 <text y="90" x="50%"   text-anchor="middle" class="subtext">{{small}}</text> 
</svg>
```
Did you see it?

The yaml is not a real processor, it just splits on "---" and finds "key: name", notice the extra space, eg ": "
```svg {ref=digitx out=./media/stat1 alt="Hello Template" namefield="name"}
---
big: 100%
small: Happy Users
name: users
---
big: 10
small: Birds in the sky
name: experience
---
big: 1
small: SVG Format
name: format
```


```svg {ref=digitx out=./media/stat1 alt="Hello Template" namefield="name"}
---
big: 2
small: Referencing
name: secondref
```
# How to convert

should not even try to convert it
```bash
pandoc -o out.docx -L svgtofile.lua test.md
```

analytics
```bash
pandoc -t json -L svgtofile.lua test.md | jq
pandoc -t markdown -L svgtofile.lua test.md  | more
```
