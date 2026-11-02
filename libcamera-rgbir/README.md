# OV5678 RGB-IR pre-pass

This directory contains a small, standalone conversion used by the optional
libcamera 0.7.2 patch in `patches/0004-libcamera-0.7.2-rgbir.patch`.

The OV5678 CFA is `G I G I / R G B G / G I G I / B G R G`. The converter
averages each 4x4 cell into a half-resolution, ordinary 2x2 Bayer cell. It
supports both unpacked RAW10 (16-bit little-endian samples) and MIPI CSI-2
packed RAW10 (four pixels in five bytes). The output is unpacked 10-bit Bayer
in 16-bit words. The IR coefficient defaults to zero; set `RGBIR_IRSUB` to a
nonnegative coefficient to subtract measured IR from the color samples.

The reference project reports a GBRG phase on its unit, but a capture on this
machine with a real red object and blue bottle showed that GRBG produces the
correct colors here; forcing GBRG swaps them. The patch accepts
`RGBIR_ORDER=GRBG|GBRG` for explicit A/B comparison. The selected profile uses
GRBG, seven inspected Intel CCMs for this sensor module, and saturation 1.5.
The CCM is listed after AWB and before Adjust so libcamera exposes the
saturation control.

Black level 64 is taken from the OV5678 measurements in the [reference
project](https://github.com/githomeserver/latitude-7320-camera/tree/main/libcamera-rgbir).
I reviewed its implementation and re-created the core conversion for this
project rather than copying its source or installer. The conversion does not
install or load kernel modules, read external files, or launch commands.

To apply the patch, use `scripts/patch-libcamera-rgbir.sh` with a clean
libcamera 0.7.2 source tree. The patch is gated by `LIBCAMERA_RGBIR`; with the
variable unset, the existing pipeline follows its original path. Enabling the
pre-pass requires output dimensions no larger than half the raw input size.

The converter source can be compiled on its own with:

```sh
g++ -std=c++17 -Wall -Wextra -Werror -Ilibcamera-rgbir \
  -c libcamera-rgbir/rgbir_to_bayer.cpp -o /tmp/rgbir_to_bayer.o
```

The real camera has now been captured at 2592x1944 input and 1280x720 output.
The red/blue object check selected GRBG, and saturation 1.5 is the chosen
balance between color and chroma noise. IR subtraction remains at zero in this
profile. Grain is visible in dim indoor light; this small sensor's noise can be
reduced later with optional chroma blur or temporal denoising, at some cost to
fine color detail or motion clarity.

Run the local, non-installed capture setup with:

```sh
scripts/capture-rgbir.sh
```

It uses the experimental libcamera build in `/tmp/libcamera-port` and writes
frames under `/tmp`. Pass an output pattern and frame count as optional
arguments.

## Software ISP white-balance limit

The OV5678's red response can require an AWB gain above libcamera 0.7.2's
hard-coded 4.0 ceiling. The companion patch
`patches/0005-libcamera-0.7.2-softisp-awb-gain.patch` raises this ceiling to
8.0. This is separate from the RGB-IR pre-pass and the sensor-specific CCM:
those cannot compensate when AWB itself is capped. The AWB starts each new
camera session at unity gains, so the first few frames can still show a green
cast while its statistics converge.
