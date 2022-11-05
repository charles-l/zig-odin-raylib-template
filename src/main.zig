const std = @import("std");
const rl = @import("common.zig").rl;
const game = @import("game.zig");

pub fn main() !void {
    game.init();

    while (!rl.WindowShouldClose()) {
        game.update();
    }
}
