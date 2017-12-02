{-# LANGUAGE OverloadedStrings #-}
import Data.Monoid ((<>))
import Hakyll
import qualified GHC.IO.Encoding as E
import System.Process
import Text.Pandoc.XML
import Text.Pandoc.Options
import Text.Pandoc.Definition
import Text.Pandoc.Readers.HTML
import qualified Text.Pandoc.JSON as PJ
import qualified Text.Pandoc.Walk as PW
import Control.Monad ((>=>))
import qualified Data.Set as S
import qualified Data.ByteString.Lazy.Char8 as LBS
import qualified Data.Text as T
import Data.Maybe
import Codec.Binary.UTF8.String (decodeString)


main :: IO ()
main = do
    E.setLocaleEncoding E.utf8
    hakyll $ do
        match "images/*" $ do
            route   idRoute
            compile copyFileCompiler

--        match "js/service-worker.js" $ do
--            route idRoute
--            compile copyFileCompiler
        match "js/prism.js" $ do
            route idRoute
            compile copyFileCompiler

        match (fromList [ "css/sanitize.css", "css/prism.scs", "css/main.css" ])
            $ compile compressCssCompiler

        match "css/*.css" $ do
            route idRoute
            compile compressCssCompiler

        match "css/fonts/*" $ do
            route idRoute
            compile copyFileCompiler

        match "about.md" $ do
            route $ setExtension "html"
            compile $ do
                customCtx <- buildCustomCtx
                customCompiler
                    >>= loadAndApplyTemplate "templates/default.html" customCtx
                    >>= relativizeUrls

        match postPattern $ do
            route $ setExtension "html"
            compile $ do
                postCtx <- buildPostCtx
                customCompiler
                    >>= loadAndApplyTemplate "templates/post.html"    postCtx
                    >>= saveSnapshot "content"
                    >>= loadAndApplyTemplate "templates/default.html" postCtx
                    >>= relativizeUrls

        create ["archive.html"] $ do
            route idRoute
            compile $ do
                postCtx <- buildPostCtx
                customCtx <- buildCustomCtx
                posts <- recentFirst =<< loadAll postPattern
                let archiveCtx =
                        listField "posts" postCtx (return posts) <> customCtx

                makeItem ""
                    >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                    >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                    >>= relativizeUrls

        match "index.html" $ do
            route idRoute
            compile $ do
                postCtx <- buildPostCtx
                posts <- take 10 <$> (recentFirst =<< loadAll postPattern)
                let indexCtx = listField "posts" postCtx (return posts) <> postCtx

                getResourceBody
                    >>= applyAsTemplate indexCtx
                    >>= loadAndApplyTemplate "templates/default.html" indexCtx
                    >>= relativizeUrls

        match "templates/*" $ compile templateBodyCompiler

        create ["atom.xml"] $ do
            route idRoute
            compile $ do
                postCtx <- buildPostCtx
                let feedCtx = postCtx <> bodyField "description"
                posts <- fmap (take 10) . recentFirst
                    =<< loadAllSnapshots postPattern "content"
                renderAtom feedConfiguration feedCtx posts
          where
            feedConfiguration = FeedConfiguration
              { feedTitle = "mt_caret.log"
              , feedDescription = "A blog."
              , feedAuthorName = "mt_caret"
              , feedAuthorEmail = "mtakeda@keio.jp"
              , feedRoot = "https://mt-caret.github.io/blog/"
              }


postPattern = "posts/*"


buildCustomCtx :: Compiler (Context String)
buildCustomCtx = do
  sanitizecss <- loadBody "css/sanitize.css"
  prismcss <- loadBody "css/prism.css"
  maincss <- loadBody "css/main.css"
  return
      $ constField "blogname" "mt_caret.log"
      <> constField "sanitizecss" sanitizecss
      <> constField "prismcss" prismcss
      <> constField "maincss" maincss
      <> defaultContext


buildPostCtx :: Compiler (Context String)
buildPostCtx = do
    customCtx <- buildCustomCtx
    return $ dateField "date" "%F" <> customCtx


customCompiler :: Compiler (Item String)
customCompiler = do
    pandocCompilerWithTransformM rOpts wOpts f
  where
    oldrExts = readerExtensions defaultHakyllReaderOptions
    rExts =
        [ Ext_east_asian_line_breaks
        , Ext_emoji
        ]
    rOpts = defaultHakyllReaderOptions
        { readerExtensions = foldr S.insert oldrExts rExts }
    wOpts = defaultHakyllWriterOptions
        { writerHighlight = False }
--    f = prerenderKaTeX . fixCodeBlocks
--    f = prerenderKaTeX >=> pygmentize >=> emojify
    f = prerenderKaTeX . fixCodeBlocks


unixFilter' :: String -> [String] -> String -> Compiler String
unixFilter' name args input = unixFilter name args (decodeString input)


prerenderKaTeX :: Pandoc -> Compiler Pandoc
prerenderKaTeX =
    PW.walkM callKaTeX
  where
    -- TODO: respect display style (i.e. inline/block)
    callKaTeX :: Inline -> Compiler Inline
    callKaTeX (Math _ input)
        = RawInline "html" <$> unixFilter' "node" ["js/render.js"] input
    callKaTeX x = return x


fixCodeBlocks :: Pandoc -> Pandoc
fixCodeBlocks =
    PW.walk codeBlockHack
  where
    -- https://github.com/jgm/pandoc/issues/3858
    -- https://github.com/jgm/pandoc/issues/629#issuecomment-8978606
    codeBlockHack :: Block -> Block
    codeBlockHack (CodeBlock (_, attr, _) str) =
        RawBlock "html"
            $ "<pre><code class='language-"
            ++ fromMaybe "null" (listToMaybe attr)
            ++ "'>"
            ++ escapeStringForXML str
            ++ "</code></pre>"
    codeBlockHack block = block


emojify :: Pandoc -> Compiler Pandoc
emojify =
    PW.walkM callTwemoji
  where
    -- much too slow, implement natively in Haskell?
    callTwemoji :: Inline -> Compiler Inline
    callTwemoji (Str str) =
        RawInline "html" <$> unixFilter' "node" ["js/emojify.js"] str
    callTwemoji inline = return inline
