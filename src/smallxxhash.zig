const std = @import("std");

const prime1: u32 = 2654435761;
const prime2: u32 = 2246822519;
const prime3: u32 = 3266489917;
const prime4: u32 = 668265263;
const prime5: u32 = 374761393;

pub const smallxxhash32 = struct {
    acc: u32,

    const Self = @This();

    pub fn hash(seed: u32, value: u32) u32 {
        var r = init(seed);
        r.update(value);
        return r.get();
    }

    pub fn init(seed: u32) Self {
        return Self{ .acc = seed +% prime5 };
    }

    pub fn update(self: *Self, i: u32) void {
        self.acc = std.math.rotl(u32, self.acc +% i *% prime3, 17) *% prime4;
    }

    pub fn get(self: *Self) u32 {
        var avalanche = self.acc;
        avalanche ^= avalanche >> 15;
        avalanche *%= prime2;
        avalanche ^= avalanche >> 13;
        avalanche *%= prime3;
        avalanche ^= avalanche >> 16;
        return avalanche;
    }
};

test "smallxxhash32" {
    var h = smallxxhash32.init(4);
    h.update(13);
    h.update(12);
    std.debug.print("{}\n", .{h.get()});
}
