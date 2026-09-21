#!/bin/bash
# runs all three programs and then checks the output against the baseline
# if everything matches the timings are good to use and output/ gets cleared out
# if something doesn't match output/ is left alone so you can look at it

log=$(mktemp)

./run_all.sh 2>&1 | tee "$log"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "a run failed, exitting"
    rm -f "$log"
    exit 1
fi

echo
./compare_baseline.sh
ok=$?

echo
grep -E "^===|Total time" "$log"
rm -f "$log"

if [ $ok -ne 0 ]; then
    echo
    echo "comparison failed so the times above don't count -> output/ left in place"
    exit 1
fi

echo
echo "output matches the baseline, times above are good"
find output -type f ! -name placeholder -delete
