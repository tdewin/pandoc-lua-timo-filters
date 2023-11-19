---
title: Photo Album with Pandoc
author: Timo
date: 2024
---

# Guidelines

## Howto
```bash
pandoc -L imgdirexplode.lua -o testout/photoalbum.pptx imgdirexplode.md
# edit the pptx for fullscreen, optional
pandoc lua imgdirpostfull.lua testout/photoalbum.pptx -metric=px -x=0 -y=0 -cx=960 -cy=540
```

## Optional 2 step
```bash
pandoc -L imgdirexplode.lua -s -o imgdirexploded.md imgdirexplode.md
pandoc -L imgdirexplode.lua -o testout/photoalbum.pptx imgdirexploded.md
# edit the pptx for fullscreen, optional, use auto for auto fit
pandoc lua imgdirpostfull.lua testout/photoalbum.pptx -auto=1
```

# Screenshots
```imgdirexplode {dir="./imgdir" match="png"}
## ${fileOnly}

![](${file})
``````


