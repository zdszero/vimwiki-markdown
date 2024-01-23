#!/bin/bash

# reference: https://gist.github.com/maikeldotuk/54a91c21ed9623705fdce7bab2989742

INPUT=$1
OUTPUT=$2
TEMPLATE=$3
CSS_THEME=$4
TOC=$5
HIGHLIGHT=$6

has_math=$(grep -o "\$.\+\$" "$INPUT")
if [ -n "$has_math" ]; then
    math="--mathjax=https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"
else
    math=""
fi

css="--css=/WikiTheme/theme/$CSS_THEME"

if [ $TOC -eq 1 ]; then
    toc="--toc"
else
    toc=""
fi

if [ $HIGHLIGHT -eq 0 ]; then
    highlight="--no-highlight"
else
    highlight=""
fi

# [test](test.md) -> <link href="test.html">
# [test](test) -> <link href="test.html">
sed -r 's/(\[.+\])\((.+)\.md\)/\1(\2.html)/g' < $INPUT |
    pandoc $math $css --template=$TEMPLATE -f markdown -t html $toc $highlight |
    sed 's/\.\.\/docs/\./g' > $OUTPUT


echo "sed -r 's/(\[.+\])\((.+)\.md\)/\1(\2.html)/g' < $INPUT |
    pandoc $math $css --template=$TEMPLATE -f markdown -t html $toc $highlight |
    sed 's/\.\.\/docs/\./g' > $OUTPUT"
