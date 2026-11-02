/* SPDX-License-Identifier: MIT */
#pragma once

#include <cstdint>

namespace libcamera {

/* Convert OV5678's fixed 4x4 RGB-IR mosaic into a half-size 16-bit Bayer
 * buffer. The input may be unpacked little-endian 10-bit samples or MIPI
 * CSI-2 RAW10 (four pixels in five bytes). Output samples remain in 10-bit
 * range inside 16-bit words, as required by DebayerCpu's unpacked path.
 */
class RgbIrToBayer
{
public:
	enum class Order { BGGR, GBRG, GRBG, RGGB };

	int convert(const uint8_t *src, unsigned int width, unsigned int height,
		    unsigned int srcStride, bool csi2Packed,
		    uint16_t *dst, unsigned int dstStride,
		    Order order, float irSubtract = 0.0f) const;
};

} /* namespace libcamera */
