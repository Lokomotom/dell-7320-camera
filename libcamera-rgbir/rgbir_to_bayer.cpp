/* SPDX-License-Identifier: MIT */

#include "rgbir_to_bayer.h"

#include <algorithm>
#include <cerrno>
#include <cstddef>

namespace libcamera {
namespace {

uint16_t readRaw10(const uint8_t *row, unsigned int x, bool packed)
{
	if (packed) {
		const unsigned int group = x / 4;
		const unsigned int lane = x % 4;
		const uint8_t *p = row + group * 5;
		return static_cast<uint16_t>((p[lane] << 2) |
					     ((p[4] >> (lane * 2)) & 0x03));
	}

	const uint8_t *p = row + x * 2;
	return static_cast<uint16_t>((p[0] | (p[1] << 8)) & 0x03ff);
}

uint16_t average(const uint16_t *raw, const unsigned int *positions,
		 unsigned int count, float ir, float irSubtract)
{
	unsigned int sum = 0;
	for (unsigned int i = 0; i < count; ++i)
		sum += raw[positions[i]];
	const float blackRelative = static_cast<float>(sum) / count - 64.0f;
	const float corrected = std::max(0.0f, blackRelative - ir * irSubtract) + 64.0f;
	return static_cast<uint16_t>(std::min(1023.0f, corrected));
}

} /* namespace */

int RgbIrToBayer::convert(const uint8_t *src, unsigned int width,
			  unsigned int height, unsigned int srcStride,
			  bool csi2Packed, uint16_t *dst,
			  unsigned int dstStride, Order order,
			  float irSubtract) const
{
	if (!src || !dst || width % 4 || height % 4 || irSubtract < 0.0f ||
	    dstStride < width)
		return -EINVAL;

	if (srcStride < (csi2Packed ? width * 5 / 4 : width * 2))
		return -EINVAL;

	/* Positions from Intel's OV5678 RGB-IR CFA description. */
	static constexpr unsigned int infrared[4] = { 1, 3, 9, 11 };
	static constexpr unsigned int red[2] = { 4, 14 };
	static constexpr unsigned int blue[2] = { 6, 12 };

	for (unsigned int cy = 0; cy < height / 4; ++cy) {
		uint16_t *out0 = reinterpret_cast<uint16_t *>(
			reinterpret_cast<uint8_t *>(dst) + (cy * 2) * dstStride);
		uint16_t *out1 = reinterpret_cast<uint16_t *>(
			reinterpret_cast<uint8_t *>(dst) + (cy * 2 + 1) * dstStride);
		for (unsigned int cx = 0; cx < width / 4; ++cx) {
			uint16_t cell[16];
			for (unsigned int y = 0; y < 4; ++y) {
				const uint8_t *row = src + (cy * 4 + y) * srcStride;
				for (unsigned int x = 0; x < 4; ++x)
					cell[y * 4 + x] = readRaw10(row, cx * 4 + x,
								      csi2Packed);
			}

			const uint16_t ir = average(cell, infrared, 4, 0.0f, 0.0f);
			const uint16_t r = average(cell, red, 2, ir - 64.0f, irSubtract);
			const uint16_t b = average(cell, blue, 2, ir - 64.0f, irSubtract);
			/* One green mean for each 2x2 quadrant preserves the two green
			 * sites needed by the output Bayer cell while retaining luma detail.
			 */
			static constexpr unsigned int quadrantGreen[4][2] = {
				{ 0, 5 }, { 2, 7 }, { 8, 13 }, { 10, 15 },
			};
			const float irRelative = ir - 64.0f;
			const uint16_t g00 = average(cell, quadrantGreen[0], 2, irRelative, irSubtract);
			const uint16_t g01 = average(cell, quadrantGreen[1], 2, irRelative, irSubtract);
			const uint16_t g10 = average(cell, quadrantGreen[2], 2, irRelative, irSubtract);
			const uint16_t g11 = average(cell, quadrantGreen[3], 2, irRelative, irSubtract);

			switch (order) {
			case Order::GRBG:
				out0[cx * 2] = g00; out0[cx * 2 + 1] = r;
				out1[cx * 2] = b;  out1[cx * 2 + 1] = g11;
				break;
			case Order::GBRG:
				out0[cx * 2] = g00; out0[cx * 2 + 1] = b;
				out1[cx * 2] = r;  out1[cx * 2 + 1] = g11;
				break;
			case Order::BGGR:
				out0[cx * 2] = b;  out0[cx * 2 + 1] = g01;
				out1[cx * 2] = g10; out1[cx * 2 + 1] = r;
				break;
			case Order::RGGB:
				out0[cx * 2] = r;  out0[cx * 2 + 1] = g01;
				out1[cx * 2] = g10; out1[cx * 2 + 1] = b;
				break;
			}
		}
	}

	return 0;
}

} /* namespace libcamera */
