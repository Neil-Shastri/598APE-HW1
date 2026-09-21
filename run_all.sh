#!/bin/bash
set -e

echo "=== pianoroom ==="
./main.exe -i inputs/pianoroom.ray --ppm -o output/pianoroom.ppm -H 500 -W 500

echo "=== globe ==="
./main.exe -i inputs/globe.ray --ppm -a inputs/globe.animate --movie -F 24

echo "=== elephant mesh (sphere) ==="
./main.exe -i inputs/elephant.ray --ppm -a inputs/elephant.animate --movie -F 24 -W 100 -H 100 -o output/sphere.mp4
