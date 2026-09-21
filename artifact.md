# Building and Running

Requires Docker. Everything else comes from the image.

## Build the image

The `wsmoses/598ape` image from the upstream README is arm64-only and fails with
`exec format error` on x86_64 machines, so build it from source instead:

```bash
cd docker && docker build -t neilas3/598ape . && cd ..
```

Without this, `./dockerrun.sh` fails with "Unable to find image 'neilas3/598ape' locally".

## Build the code

```bash
./dockerrun.sh        # opens a shell with the repo mounted at /host
cd /host && make -j
```

## Run

```bash
./main.exe -i inputs/pianoroom.ray --ppm -o output/pianoroom.ppm -H 500 -W 500

./main.exe -i inputs/globe.ray --ppm -a inputs/globe.animate --movie -F 24

./main.exe -i inputs/elephant.ray --ppm -a inputs/elephant.animate --movie \
  -F 24 -W 100 -H 100 -o output/sphere.mp4

./main.exe -i inputs/realelephant.ray --ppm -a inputs/elephant.animate --movie \
  -F 24 -W 100 -H 100 -o output/elephant.mp4
```

Output goes to `output/`. Each run prints `Total time to create images=...`, which is the
number to compare; it covers the main loop only, not parsing or video encoding.

Files created in the container are owned by root, so delete them from inside it.

## Benchmarking an optimization

There are three scripts. `run_all.sh` just runs the three programs back to back.
`compare_baseline.sh` diffs the ppm frames in `output/` against the ones saved in
`baseline/`. `run_and_check.sh` does both, and is the one to actually use:

```bash
./run_and_check.sh
```

It wipes `output/` first so nothing old is left around, runs everything, compares the
frames, and reprints the timings at the end. If anything differs it says so and exits
non-zero, and `output/` is left there so you can look at what changed. `baseline/` is never
touched.

The point is that a faster time only counts if the render didn't change. It's easy to make
this thing faster by accident-breaking it - skipping an intersection test or racing on a
shared write both speed it up and both give you a different picture.

Frames that aren't byte identical get reported with an RMSE number instead of just failing,
since reordering float math can shift the low bits without actually changing the image.
Near zero is fine, anything you can see is a real bug.

Only the ppm frames get compared, not the mp4s - the video encoder doesn't produce identical
bytes run to run so comparing those gives false alarms.

## Making the baseline

`baseline/` isn't in git (it's about 70MB, mostly globe at 1000x1000). Generate it once
before you start optimizing, from inside the container:

```bash
make -j
./run_all.sh
mkdir -p baseline && cp output/*.ppm baseline/
```

Do the copy inside the container, the files are root owned.
