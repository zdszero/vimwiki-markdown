#!/bin/bash

# reference: https://gist.github.com/maikeldotuk/54a91c21ed9623705fdce7bab2989742

SED_COMMAND=sed
os_name=$(uname -s)

if [[ "$os_name" = "Linux" ]]; then
    SED_COMMAND=sed
elif [[ "$os_name" = "Darwin" ]]; then
    SED_COMMAND=gsed
else
    echo "Unknown operating system: $os_name"
fi

INPUT=$1
OUTPUT=$2
TEMPLATE=$3
CSS_THEME=$4
TOC=$5
HIGHLIGHT=$6
DEPTH=$7

math="--mathjax=https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"

relative_to_root=""
escaped_relative_to_root=""
for ((i=1; i<=$DEPTH; i++)); do
    relative_to_root="${relative_to_root}../"
    escaped_relative_to_root="${escaped_relative_to_root}\.\.\/"
done

if [ $DEPTH -gt 0 ]; then
    css="--css=${relative_to_root}WikiTheme/theme/$CSS_THEME"
else
    css="--css=./WikiTheme/theme/$CSS_THEME"
fi

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

$SED_COMMAND -r 's/(\[.+\])\((.+)\.md(.*)\)/\1(\2.html\3)/g' < $INPUT |
    pandoc $math $css --template=$TEMPLATE -f markdown -t html $toc $highlight |
    $SED_COMMAND -r "/<body>/,/<\/body>/ {
        s/\.\.\/docs/\./g
        s/(href=\")(\/)/\1${escaped_relative_to_root}/g
    }" > $OUTPUT

if [ $DEPTH -gt 0 ]; then
    $SED_COMMAND -ri "/<head>/,/<\/head>/ s/((src|href)=\")(\.\/)/\1${escaped_relative_to_root}/g" $OUTPUT
fi
