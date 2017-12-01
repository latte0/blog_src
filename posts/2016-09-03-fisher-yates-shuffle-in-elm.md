---
title: Fisher-Yates shuffleのElm実装
date: '2016-09-03'
---

友人に頼まれてjQueryとUnderscore.jsで昔実装した
[東方キャラ選び](https://mt-caret.github.io/th/)を勉強がてらElmで組みなおして
みようと思い立ったものの、`_.sample`に相当するものが存在しなかったため、
`_.sample`に必要な`_.shuffle`をElmで実装してみました。

``` haskell
import CollectionsNg.Array as Array exposing (Array)
import Random exposing (Generator)
import String


switch : (Int, Int) -> Array a -> Array a
switch t array =
  let
    ( i, j ) = t
  in
    case Array.get i array of
      Nothing ->
        array
      Just i_val ->
        case Array.get j array of
          Nothing ->
            array
          Just j_val ->
            Array.set j i_val array |> Array.set i j_val


random_switch : (Int, Int) -> Generator(Array a) -> Generator (Array a)
random_switch range array =
  let
    ( i, n ) = range
    switch_tuple =
      Random.map ((,) i) (Random.int i n)
  in
    Random.map2 switch switch_tuple array


constant : a -> Generator a
constant value =
  Random.map (\a -> value) Random.bool


shuffle : Array a -> Generator (Array a)
shuffle array =
  let
    n = Array.length array
    zip : List a -> List b -> List (a, b)
    zip = List.map2 (,)
    ta = List.repeat (n - 1) (n - 1) |> zip [0..n-2] |> Array.fromList
  in
    Array.foldr random_switch (constant array) ta
```


これで色々遊んでいたらランタイムエラーが出ない事が売りのElmでこんなものが
でました。

![ランタイムエラー](/images/elm-runtime-error.png)

[coreのArray実装に問題があるようです。](https://github.com/elm-lang/core/issues/649)

