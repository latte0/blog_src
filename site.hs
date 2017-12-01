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
import Control.Monad
import qualified Data.Set as S
import qualified Data.ByteString.Lazy.Char8 as LBS
import qualified Data.Text as T

main :: IO ()
main = do
    E.setLocaleEncoding E.utf8
    hakyll $ do
        match "images/*" $ do
            route   idRoute
            compile copyFileCompiler

        match "js/service-worker.js" $ do
            route idRoute
            compile copyFileCompiler

        match "css/sanitize.css" $ do
            compile compressCssCompiler

        match "css/main.css" $ do
            compile compressCssCompiler

        match "css/*.css" $ do
            route idRoute
            compile compressCssCompiler

        match "css/**" $ do
            route idRoute
            compile copyFileCompiler

        match "about.md" $ do
            route   $ setExtension "html"
            compile $ do
                customCtx <- buildCustomCtx
                customCompiler
                    >>= loadAndApplyTemplate "templates/default.html" customCtx
                    >>= relativizeUrls

        match "posts/*" $ do
            route $ setExtension "html"
            compile $ do
                postCtx <- buildPostCtx
                customCompiler
                    >>= loadAndApplyTemplate "templates/post.html"    postCtx
                    >>= loadAndApplyTemplate "templates/default.html" postCtx
                    >>= relativizeUrls

        create ["archive.html"] $ do
            route idRoute
            compile $ do
                postCtx <- buildPostCtx
                customCtx <- buildCustomCtx
                posts <- recentFirst =<< loadAll "posts/*"
                let archiveCtx =
                        listField "posts" postCtx (return posts) <>
                        constField "title" "Archives"            <>
                        customCtx

                makeItem ""
                    >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                    >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                    >>= relativizeUrls


        match "index.html" $ do
            route idRoute
            compile $ do
                postCtx <- buildPostCtx
                customCtx <- buildCustomCtx
                posts <- recentFirst =<< loadAll "posts/*"
                let indexCtx =
                        listField "posts" postCtx (return posts) <>
                        customCtx


                getResourceBody
                    >>= applyAsTemplate indexCtx
                    >>= loadAndApplyTemplate "templates/default.html" indexCtx
                    >>= relativizeUrls

        match "templates/*" $ compile templateBodyCompiler

buildCustomCtx :: Compiler (Context String)
buildCustomCtx = do
  sanitizecss <- loadBody "css/sanitize.css"
  maincss <- loadBody "css/main.css"
  return
      $ defaultContext
      <> constField "blogname" "mt_caret.log"
      <> constField "sanitizecss" sanitizecss
      <> constField "maincss" maincss

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
--    f = prerenderKaTeX >=> pygmentize >=> emojify -- TODO: investigate
    f = prerenderKaTeX' >=> pygmentize

unixFilter' :: String -> [String] -> String -> Compiler String
unixFilter' name args input =
    LBS.unpack <$> unixFilterLBS name args (LBS.pack input)

-- TODO: respect display style (i.e. inline/block)
callKaTeX :: Inline -> IO Inline
callKaTeX (Math _ input)
    = RawInline "html" <$> readCreateProcess (shell "node js/render.js") input
callKaTeX x = return x

callKaTeX' :: Inline -> Compiler Inline
callKaTeX' (Math _ input)
    = RawInline "html" <$> unixFilter' "node" ["js/render.js"] input
callKaTeX' x = return x

prerenderKaTeX :: Pandoc -> Compiler Pandoc
prerenderKaTeX = unsafeCompiler . PW.walkM callKaTeX

prerenderKaTeX' :: Pandoc -> Compiler Pandoc
prerenderKaTeX' = PW.walkM callKaTeX'

-- https://github.com/jgm/pandoc/issues/3858
-- https://github.com/jgm/pandoc/issues/629#issuecomment-8978606
codeBlockHack :: Block -> Block
codeBlockHack (CodeBlock attr str) =
    RawBlock "html"
        $ "<pre><code "
        ++ convAttr attr
        ++ ">"
        ++ escapeStringForXML str
        ++ "</code></pre>"
  where
    convAttr (_, code:_, _) = "class='language-" ++ code ++ "'"
codeBlockHack block = block

fixCodeBlocks :: Pandoc -> Pandoc
fixCodeBlocks = PW.walk codeBlockHack

pygmentize :: Pandoc -> Compiler Pandoc
pygmentize = unsafeCompiler . PW.walkM callPygments

callPygments :: Block -> IO Block
callPygments (CodeBlock (_, lang:_, _) str) =
    RawBlock "html" . wrap <$> readCreateProcess (shell cmd) str
  where
    wrap html
        = "<pre><code class='language-"
        ++ lang
        ++ "'>"
        ++ html
        ++ "</code></pre>"
    cmd = "pygmentize -f html -O " ++ options ++ " -l " ++ lang
    options = "noclasses"
callPygments block = return block

emojify :: Pandoc -> Compiler Pandoc
emojify = unsafeCompiler . PW.walkM callTwemoji

callTwemoji :: Inline -> IO Inline
callTwemoji (Str str) = do
    res <- readCreateProcess (shell "node js/emojify.js") str
    doc <- readHTML defaultHakyllReaderOptions $ T.pack res
    return $ RawInline "html" res
callTwemoji inline = return inline
