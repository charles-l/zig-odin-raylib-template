const std = @import("std");
const rl = @import("common.zig").rl;

extern fn init() callconv(.C) void;
extern fn update() callconv(.C) void;

pub fn main() !void {
    init();

    while (!rl.WindowShouldClose()) {
        update();
    }
}
