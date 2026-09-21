#!/bin/bash
# clears out output/ then runs all three programs and checks the frames against baseline/
# baseline/ is never touched, it's the reference we keep comparing against

if [ ! -d baseline ]; then
    echo "no baseline directory - make one before using this"
    exit 1
fi

log=$(mktemp)

find output -type f ! -name placeholder -delete

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
