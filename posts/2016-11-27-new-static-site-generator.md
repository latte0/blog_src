---
document_type: post
language: ja
title: Hakyllへ移行
date: '2016-11-27'
categories:
- meta
tags:
---

JavaScriptの勉強がてらwebpackベースのStatic Site Generatorを組んでそれでブログを
書いていましたが、つらくなってきたのでHaskellを勉強しているついでにHakyllに移行
しました。数日掛けて実装していた機能でもHakyllで一瞬で実現できてしまうのは
複雑な気分になります。

MathJaxの導入は少しハマりましたが、```site.hs```で

```haskell
pandocCompilerWithMath :: Compiler (Item String)
pandocCompilerWithMath =
  pandocCompilerWith defaultHakyllReaderOptions $
    defaultHakyllWriterOptions { writerHTMLMathMethod = MathJax "" }
```

を```pandocCompiler```のかわりに使用したら解決しました。

Hakyllは天下のpandocとの親和性を謳っていますが、今のところあまり旨味を
引き出せていない感じがします。

[古いSSGの残骸](https://github.com/mt-caret/nemui-ssg)

追記： [新しいSSGのソース](https://github.com/mt-caret/blog_src)です。
