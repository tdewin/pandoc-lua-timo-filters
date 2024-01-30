---
author: "Timothy"
date: 2024-01-30
baselibrary: "./libmd/"
---

# Author modified
``` libmd {file=0001_legal.md}
author
date
```

# Author not modified and use of partial name

``` libmd {partial=legal}
date
```

# Test 
```bash
pandoc -s -L libmd.lua -f markdown -t markdown libmd.md
```