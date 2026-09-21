#!/bin/bash
# check output/ against baseline/ so we know an optimization didn't break the render

baseline=${1:-baseline}
output=${2:-output}

if [ ! -d "$baseline" ]; then
    echo "no $baseline directory - run ./run_all.sh and copy the ppms over first"
    exit 1
fi

n=$(ls "$baseline"/*.ppm 2>/dev/null | wc -l)
if [ "$n" -eq 0 ]; then
    echo "no ppm files in $baseline"
    exit 1
fi

bad=0

for f in "$baseline"/*.ppm; do
    name=$(basename "$f")
    new="$output/$name"

    if [ ! -f "$new" ]; then
        echo "$name is missing from $output"
        bad=1
    elif ! cmp -s "$f" "$new"; then
        rmse=$(compare -metric RMSE "$f" "$new" null: 2>&1 | awk '{print $1}')
        echo "$name differs, rmse $rmse"
        bad=1
    fi
done

if [ $bad -eq 0 ]; then
    echo "all $n frames match"
else
    echo "output does not match the baseline"
fi

exit $bad
