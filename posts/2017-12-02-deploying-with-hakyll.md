---
title: Deploying a Hakyll-based site to Github Pages
---

I've come up with a nice workflow for deploying a site built with Hakyll to
Github Pages[^1], so I thought I'd share it.

The problem with Hakyll is that commands like `site rebuild` overwrite the
`_site` directory, including `.git/`. Considering the fact that cloning a repo
that's tens to hundreds of MBs takes a **long** time, this complicates making
use of both Hakyll's built-in commands and git's efficient diffing functionality.
So, the deploy workflow for my blog used to be a combination of a Makefile and some
scripts to make sure I don't mess up and need to clone a giant repo yet again.[^2]

Now I think I have the answer. Create a separate directory for the git repo
linked with Github Pages (say `_deploy`) and rsync `_site` to my new directory.
This lets me run `site rebuild` and `site clean` to my heart's content.
To show how simple it is here's `deploy.sh`:

``` bash
#!/usr/bin/env bash
set -e
rsync -a --exclude ".*" --delete-after _site/ _deploy
```

I haven't got around to automating the timestamp commit + push, but I hope you
get the idea.

[^1]: There's actually an
[official tutorial on deploying to Github Pages with Hakyll](https://jaspervdj.be/hakyll/tutorials/github-pages-tutorial.html#removing-old-files-with-rsync)
but I think my approach is more
[simple and easy](https://www.infoq.com/presentations/Simple-Made-Easy).
[^2]: The cache gets corrupted once in a while for some reason, forcing me to
run `site clean` which also removes `.git`.

