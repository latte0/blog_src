---
title: "不要なDockerイメージの削除"
date: "2017-02-06"
tags:
- memo
math: false
---

```bash
docker images | grep "^<none>" | tr -s ' ' | cut -d ' ' -f3 | xargs docker rmi
```

名無しのDockerイメージを削除するやつです。

## 参照

```
* Simple command to remove all untagged images (`docker rmi $(docker images | awk '/^<none>/ { print $3 }')`)
```

[docker/FIXME](https://github.com/docker/docker/blob/a665517151911866285e5a72164c5f2d2f31ba65/FIXME#L26)より。

