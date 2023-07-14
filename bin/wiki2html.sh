#!/bin/zsh

# reference: https://gist.github.com/maikeldotuk/54a91c21ed9623705fdce7bab2989742

INPUT=$1
OUTPUT=$2
TEMPLATE=$3
DEPTH=$4

HAS_MATH=$(grep -o "\$.\+\$" "$INPUT")
if [ -n "$HAS_MATH" ]; then
    MATH="--mathjax=https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"
else
    MATH=""
fi

# [test](test.md) -> <link href="test.html">
# [test](test) -> <link href="test.html">
tempfile=$(mktemp)
sed -r 's/(\[.+\])\((.+)\.md\)/\1(\2.html)/g' < $INPUT |
    pandoc $MATH --template=$TEMPLATE -f markdown -t html --toc |
    sed 's/\.\.\/docs/\./g' > $tempfile
# change relative path to css
if [[ $DEPTH -gt 0 ]]; then
    replace_to="$(printf "..\/%0.s" {1..$(($DEPTH))})css"
    echo $replace_to
    replace_cmd="s/\.\/css/${replace_to}/"
    sed -i $replace_cmd $tempfile
fi
cp $tempfile $OUTPUT
rm $tempfile
