# Artifact

All of our work is on the optimizations branch. You will need to ssh into the course VM and clone this repo there to start.

## Setup

You just need docker. The wsmoses/598ape image in the README only works on arm64 (we got "exec format error" on the course VM), so build the image from our Dockerfile instead:

```
cd docker && docker build -t neilas3/598ape . && cd ..
```

We added gperftools/pprof/graphviz (for profiling) and valgrind to the end of the Dockerfile. Everything else is the same as the course one.

Then to build:

```
./dockerrun.sh
cd /host && make -j
```

We ran everything on the course VM (Intel Xeon Silver 4216, 4 cores, 22MB L3) with g++ 13.3.0 from the image. The program is single threaded.

## Running

```
./main.exe -i inputs/pianoroom.ray --ppm -o output/pianoroom.ppm -H 500 -W 500
./main.exe -i inputs/globe.ray --ppm -a inputs/globe.animate --movie -F 24
./main.exe -i inputs/elephant.ray --ppm -a inputs/elephant.animate --movie -F 24 -W 100 -H 100 -o output/sphere.mp4
./main.exe -i inputs/realelephant.ray --ppm -a inputs/elephant.animate --movie -F 24 -W 100 -H 100 -o output/elephant.mp4
```

run_all.sh runs the first three. realelephant.ray is the real 111,748 triangle elephant (elephant.ray with the sphere mesh line commented out and the elephant one uncommented, like the README says).

The time we report is the "Total time to create images" line that each run prints. We ran each thing 2-5 times and took the median. The VM is shared so there's around 3% noise, so we didn't count anything smaller than that.

Files made in the container are owned by root so delete them from inside the container.

## Checking the output didn't change

Every optimization has to give the exact same frames as the original code, otherwise the speedup doesn't count. run_and_check.sh clears output/, runs all three programs, and compares every ppm frame to baseline/ using compare_baseline.sh. If a frame is different it prints which one and an RMSE, and exits with an error. We don't compare the mp4s since ffmpeg doesn't give the same bytes every time.

baseline/ isn't in git (it's around 70MB) so you have to make it from the original code. Commit 439366d is the original code with our scripts and the profiler but none of the optimizations. Do the git commands outside the container (git inside it complains the repo belongs to another user) and the rest inside:

```
git checkout 439366d                             (outside container)
make clean && make -j && ./run_all.sh            (inside)
mkdir -p baseline && cp output/*.ppm baseline/   (inside)
git checkout optimizations                       (outside container)
make clean && make -j && ./run_and_check.sh      (inside)
```

The baseline run takes over an hour since the elephant/sphere was really slow originally (~74 min). At the end it should say "all 49 frames match".

## Profiling

Every run writes my_profile.prof (the ProfilerStart/ProfilerStop calls in main.cpp are around the timed loop). We checked and the profiler only adds about 1-2%.

```
/root/go/bin/pprof -top ./main.exe my_profile.prof
/root/go/bin/pprof -http "0.0.0.0:8000" ./main.exe my_profile.prof
```

The second one is the flamegraph. Port 8000 is already mapped in dockerrun.sh, so do ssh -L 8000:localhost:8000 to the VM and open localhost:8000 in your browser. perf didn't work on the VM (kernel version mismatch and perf_event_paranoid is 4) so we used pprof instead.

For valgrind we ran valgrind --leak-check=full --track-origins=yes on a copy of the code with the profiler taken out, since the profiler gives a few fake errors.

## Optimizations

To check any of these, checkout the commit before it and the commit itself, rebuild both, and time the same command.

1. 8c34d93 -O0 to -O3. src/Makefile was building all the shape/vector files at -O0. Pianoroom went from about 2.2s to 1.09s.

2. b88babf -flto. Added link time optimization to all 3 Makefiles so the Vector functions can get inlined across files. Pianoroom 1.09s to 0.90s. With this and the last one globe went from 145.66s to 78.11s.

3. 811ebda fix() uses floor. fix() in src/Textures/texture.cpp was using fmod for every texture lookup, a - floor(a) does the same thing way cheaper. Globe 78.11s to 67.11s, pianoroom 0.90s to 0.87s. Globe gets more out of it since it uses a lot of textures.

4. 34858c3 min search. calcColor in src/shape.cpp was making an array of every hit for every ray (malloc/copy/free for each one), sorting it, and then only using the first one. Now it just keeps track of the closest hit. Pianoroom 0.87s to 0.67s, globe 67.11s to 50.78s. This also fixed a memory leak. 4ca1888 deleted the insertion sort that wasn't used anymore.

5. bed93d2 skip texture fetch for opaque spheres. The other shapes already returned early in getLightIntersection if they were opaque but Sphere didn't. We added a fullyOpaque flag to Texture (turned off for masked textures like the clouds). Globe 50.78s to 49.26s. ca14cec fixed the flag not getting set right for inline images.

6. 2aa1489 reuse getNormal. calcColor was calling getNormal twice for the same point, and the compiler can't get rid of that since it's a virtual function. The sea has a normal map so it's actually expensive. Globe 49.36s to 45.67s.

7. 0231485 bounding sphere for meshes. The mesh gets loaded as thousands of separate triangles so every ray was checking every triangle. Now we put a sphere around the mesh when loading it and skip the whole mesh if the ray misses the sphere. Elephant/sphere (2 frames) went from 2.96s to 0.12s, about 24x. Globe got about 2% slower since it doesn't have a mesh and just does the extra check.

fc9968d added valgrind, 97136ed fixed the memory leaks it found, and ca14cec fixed a double free from that (all the triangles in a mesh share one texture). These don't change the speed.

## Final times

pianoroom 2.20s to 0.68s (3.2x), globe 146.28s to 45.62s (3.2x), elephant/sphere 4435.68s to 1.49s (about 2970x). All three together went from about 76 minutes to 47.8s. The real elephant takes 127.84s but we never ran it on the original code since it would have taken forever, so there's no speedup for it. All 49 frames match the original.

## Stuff that didn't work

-march=native was slower on pianoroom and a bit faster on globe, but changed the output. -ffast-math and -Ofast made globe 3.5x slower and broke the picture because the code uses infinity to mean the ray missed. Changing /255. to *(1./255.) didn't speed anything up and changed the output. Skipping shadow rays for surfaces facing away from the light was 1.2% slower because the light is basically at the camera so it never skipped anything.

## Bugs we left in

These were already in the original code, and fixing them changes the output so we left them. getLight in src/light.cpp uses lightColor[0] for all 3 colors. Sphere::getLightIntersection has a parenthesis in a different spot than Sphere::getColor. The Shape constructor never sets mapX, mapY, mapOffX and mapOffY but the normal map code uses them (valgrind found this on globe). When we tried setting them the picture changed and globe got about 28% slower. Because of this the baseline frames depend on leftover memory, but it's the same every time with the same docker image.
