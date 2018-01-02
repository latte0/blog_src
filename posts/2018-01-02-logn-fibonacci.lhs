---
title: nth Fibonacci number in O(logn)
katex: true
---

The other day I was helping a friend practice for a coding interview and I
chose calculating the nth Fibonacci number as a FizzBuzz-type practice question.
While he went through the usual "implement naively then memoize" approach,
I suddenly remembered that you could apply the
[repeated squares method](https://en.wikipedia.org/wiki/Exponentiation_by_squaring)
to this problem. So to add some challenge to the problem, I asked him how he'll
implement calculating the $n$th Fibonacci number if $n$ was fairly large
(i.e. $10^{10}$[^1]). I gave him a few minutes but he couldn't solve it;
which was fairly surprising, because I originally came across the approach in
a competitive programming book[^2] and he's much better at me in competitive
programming and certainly well-versed in the literature.

Here's a $O( \log n )$ solution in Haskell.

>{-# LANGUAGE InstanceSigs #-}
>module Fib where
>
>import Data.Bits
>import Data.Monoid ((<>))
>import Criterion.Main

But first, a naive recursive implementation and an $O(n)$ tail recursive
implementation for reference.

>naiveFib :: Integral a => Int -> a
>naiveFib 0 = 0
>naiveFib 1 = 1
>naiveFib n = naiveFib (n - 1) + naiveFib (n - 2)

>tailRecFib :: Integral a => Int -> a
>tailRecFib n = go n 0 1
>  where
>    go 0 a _ = a
>    go n a b = go (n - 1) b (a + b)

I always love clever solutions that abuse infinite lists and lazy evaluation.

>coolFib :: Integral a => Int -> a
>coolFib n =
>    fibs !! n
>  where
>    fibs = 0 : 1 : zipWith (+) fibs (tail fibs)

The Fibonacci numbers are defined so:

$$
\begin{aligned}
F(0) &= 0 \\
F(1) &= 1 \\
F(n) &= F(n - 1) + F(n - 2)
\end{aligned}
$$

You can express $F(n)$ in terms of matrix multiplication like so:

$$
\begin{bmatrix}
F(n) \\
F(n-1) \\
\end{bmatrix}
=
\begin{bmatrix}
1 & 1 \\
1 & 0 \\
\end{bmatrix}
\begin{bmatrix}
F(n-1) \\
F(n-2) \\
\end{bmatrix}
$$

Which then becomes:

$$
\begin{bmatrix}
F(n) \\
F(n-1) \\
\end{bmatrix}
=
\begin{bmatrix}
1 & 1 \\
1 & 0 \\
\end{bmatrix}^{n-1}
\begin{bmatrix}
1 \\
0 \\
\end{bmatrix}
$$

We'll express 2x2 matrices with the type `Mat a`.

>data Mat a = Mat a a a a deriving Show

Then, we'll define a `Monoid` instance for it with `mappend` as multiplication
because that'll be all we need. `mempty` then becomes the identity matrix.

>instance Num a => Monoid (Mat a) where
>  mempty :: Mat a
>  mempty = Mat 1 0 0 1
>
>  mappend :: Mat a -> Mat a -> Mat a
>  mappend (Mat a1 b1 c1 d1) (Mat a2 b2 c2 d2) =
>      Mat (a1*a2+b1*c2) (a1*b2+b1*d2) (c1*a2+d1*c2) (c1*b2+d1*d2)

Assuming multiplication is a constant time operation, exponentiation can be
done in $O( \log n )$ time by decomposing the exponent into the sum of powers
of 2 (ex. $x^{13} = x^8 \times x^4 \times x^1$). This is possible because
raising $x$ to the $2^k$th power is a $O(k)$ operation since $x^{2^k}$ can be
calculated in $O(1)$ by squaring $x^{2^{k-1}}$.

We'll first create an infinite list where the $i$th element will be raised to
the $2^i$th power.

>sqs :: Num a => Mat a -> [Mat a]
>sqs = iterate (\x -> x <> x)

We also need to decompose $N$ into the sum of powers of 2. This is actually
just decomposition into bits.

>tobits :: (Bits a, Integral a) => a -> [Bool]
>tobits n =
>    testBit n <$> [0..(digits n) - 1]
>  where
>    digits = (+1) . floor . logBase 2 . fromIntegral

Finally, putting it all together:

>sel :: [Bool] -> [a] -> [a]
>sel bs as = fmap snd . filter fst $ zip bs as
>
>fib :: Integral a => Int -> a
>fib n =
>    ext . mconcat . sel (tobits (n-1)) $ sqs (Mat 1 1 1 0)
>  where
>    ext (Mat x _ _ _) = x

Let's run a few benchmarks to see how well each implementation does.

>main = defaultMain
>    [ bgroup "naiveFib" $ gen naiveFib <$> [1..20]
>    , bgroup "tailRecFib" $ expGen tailRecFib  <$> [1..4]
>    , bgroup "coolFib" $ expGen coolFib <$> [1..4]
>    , bgroup "fib" $ expGen fib <$> [1..6]
>    ]
>  where
>    gen f n = bench (show n) $ whnf f n
>    expGen f n = gen f (10^n)

Runinng
`stack runghc posts/2018-01-02-logn-fibonacci.lhs -- --ouput res.html` gives us
a nicely formatted performance report with a graph included below.

![performance graph (X axis in milliseconds)](/images/2018-01-02-fib_perf.png)

`coolFib` outperforms `tailRecFib`, which was something I didn't expect.

While it's hard to discern, `fib` is roughly $O( \log n )$ until around
$N = 10^4$ where performance starts to degrade into something more like $O(n)$.
I think this is due to bignum calculations slowing things down (the $10^4$th
Fibonacci number is over 2000 digits!). Anyhow, the $10^6$th Fibonacci number
in under $25$ milliseconds is not bad at all.

Framing the problem as matrix exponentiation often brings dramatic speedups
making this is a pretty useful technique to remember.

== Pages Referenced

- [The Fibonacci sequence - HaskellWiki](https://wiki.haskell.org/The_Fibonacci_sequence)

[^1]: In retrospect, the $n \le 10^{10}$ constraint wasn't fair because
if N gets large enough bignum calculations become too costly to consider
constant and even $O( \log n )$ will be nowhere near close to realistic.
[WolframAlpha tells us](https://www.wolframalpha.com/input/?i=fibonacci+10%5E10)
that the $10^{10}$th Fibonacci number is approximately $1.41 \times 10^{2089876402}$.
AFAIK complexity of bignum multiplication is at least $O( \log n )$ AFAIK,
so there's no way that we'll get a result in a meaningful amount of time!
(On a related note, I'm curious as to where WolframAlpha got that approximation.)

[^2]: Both ["Competitive Programming 3"](https://cpbook.net/) and
[「プログラミングコンテストチャレンジブック」](https://www.amazon.co.jp/dp/4839931992)
(Japanese) mention this technique, but I'm not sure which one I read about it
first in.

