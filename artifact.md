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
