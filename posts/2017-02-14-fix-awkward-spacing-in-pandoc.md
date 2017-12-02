---
title: "Hakyllで日本語文章の改行が空白に変換される問題の解決"
date: "2017-02-14"
---

Markdownで日本語の文章を書くと改行が空白に変換されてしまい
HTML文章中に不自然な空白がところどころ入ります。
これがHakyllに移行してからずっと気になっていました。
実はPandocの`east_asian_line_breaks`という拡張で解決できことを知り、
Hakyllからその拡張を利用する方法を書くことにしました。

[Hakyllドキュメンテーションによると](https://jaspervdj.be/hakyll/reference/Hakyll-Web-Pandoc.html)
HakyllでMarkdownをHTMLに変換してくれるのは`Compiler (Item String)`です。
そこで、それをくれつつPandocの`WriterOptions`を弄らせてくれる
`renderPandocWith :: ReaderOptions -> WriterOptions -> Item String -> Compiler (Item String)`
を使います。

[Pandocドキュメンテーションによれば](https://hackage.haskell.org/package/pandoc-1.19.2.1/docs/Text-Pandoc-Options.html)
`readerExtensions :: Set Extension`[^1]に`Ext_east_asian_line_breaks`
を追加できればよさそうなので適宜インポートした上でこう書きます。

```haskell
import qualified Data.Set as S
import Text.Pandoc.Options
```

```haskell
customPandocCompiler :: Compiler (Item String)
customPandocCompiler =
  pandocCompilerWith readerOptions defaultHakyllWriterOptions
  where
    customExtensions = [Ext_east_asian_line_breaks]
    defaultExtensions = readerExtensions defaultHakyllReaderOptions
    newExtensions = foldr S.insert defaultExtensions customExtensions
    readerOptions =
      defaultHakyllReaderOptions { readerExtensions = newExtensions }
```

# 参照

- [Pandoc で日本語文書の改行が空白に変換される問題](http://tnoda-journal.tumblr.com/post/141345727462/pandoc-%E3%81%A7%E6%97%A5%E6%9C%AC%E8%AA%9E%E6%96%87%E6%9B%B8%E3%81%AE%E6%94%B9%E8%A1%8C%E3%81%8C%E7%A9%BA%E7%99%BD%E3%81%AB%E5%A4%89%E6%8F%9B%E3%81%95%E3%82%8C%E3%82%8B%E5%95%8F%E9%A1%8C)
- [Custom Pandoc Options with Hakyll 4](https://nickcharlton.net/posts/custom-pandoc-options-hakyll-4.html)

[^1]: なぜ`writerExtensions`ではないかというと、試して上手く行かなかった
からです。😢 `Extension`が`writerExtensions`か`readerExtensions`に属するべき
ものなのかの判断はドキュメントを軽く読んだだけではできませんでした。
知っている方が居ましたら是非教えてください。
