const std = @import("std");
const xxhash = @import("smallxxhash.zig").smallxxhash32;

pub fn perlin1(position: f32) f32 {
    const x0 = std.math.floor(position);
    const x1 = x0 + 1;

    const t = position - x0;
    const x0d = @intToFloat(f32, xxhash.hash(13, @bitCast(u32, x0)) & 0xFFFF) / 0xFFFF;
    const x1d = @intToFloat(f32, xxhash.hash(13, @bitCast(u32, x1)) & 0xFFFF) / 0xFFFF;

    const x0p = x0d * t;
    const x1p = -x1d * (1 - t);

    const u = t * t * (3 - 2 * t);
    return x0p * (1 - u) + (x1p * u);
}
