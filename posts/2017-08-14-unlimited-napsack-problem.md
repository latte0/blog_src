---
title: "個数制限なしナップサック問題"
date: "2017-08-14"
katex: true
---

最近[AOJ-ICPC](http://aoj-icpc.ichyo.jp/)の問題を１日１ACしています。
そこで、ハマってしんどかったので忘れないようにメモしておきます。

# 問題概要

$i(0 \le i \lt N)$番目の物の重さが$w[i]$、価値が$v[i]$の時、重さが$W$以下になるように選んだ
場合の価値の合計の最大値を求めよ。

# 解法

$i$番目までの物を重さが$j$以下になるように選んだ時の価値の最大値を$dp[i][j]$と
します。すると、次の漸化式が成り立ちます。

$$
\begin{aligned}
dp[i+1][j]
&= \max_{k \ge 0} \{ dp[i][j-k*w[i+1]]+k*v[i+1] \} \\
&= max(dp[i][j], \max_{l \ge 1} \{ dp[i][j-l*w[i+1]]+l*v[i+1] \}) \\
\end{aligned}
$$

同様にしてこちらも成り立ちます。

$$
\begin{aligned}
dp[i+1][j-w[i+1]]
&= \max_{k \ge 0} \{ dp[i][j-w[i+1]-k*w[i+1]]+k*v[i+1] \} \\
&= \max_{l \ge 1} \{ dp[i][j-l*w[i+1]]+(l-1)*v[i+1] \} \\
\end{aligned}
$$

両辺に$v[i+1]$を足すと次のようになります。

$$
\begin{aligned}
dp[i+1][j-w[i+1]] + v[i+1]
&= \max_{l \ge 1} \{ dp[i][j-l*w[i+1]]+l*v[i+1] \} \\
\end{aligned}
$$

最初に式にこれを代入して終わりです。

$$
\begin{aligned}
dp[i+1][j]
&= \max_{k \ge 0} \{ dp[i][j-k*w[i+1]]+k*v[i+1] \} \\
&= max(dp[i][j], dp[i+1][j-w[i+1]] + v[i+1]) \\
\end{aligned}
$$

$\forall i.dp[i][0] = 0$で初期化し、DPを回すと$dp[N-1][W]$が答えになります。

しんどい。

## 問題

- [AOJ 2607 Invest Master](http://judge.u-aizu.ac.jp/onlinejudge/description.jsp?id=2607&lang=jp)

## 参考

- [ナップサック問題　個数制限なし　自分用メモ](https://ameblo.jp/leopapoke/entry-12057911186.html)

## 追記 (2017-08-18)

$dp[i][j]$は$dp[i-1][j]$にしか依存しないため、$dp$の行を使いまわすことによって
大幅にメモリを節約できるという指摘が [@\_izryt](https://twitter.com/_izryt)
からありました。ありがとうございます。

