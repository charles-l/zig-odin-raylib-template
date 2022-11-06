const std = @import("std");
const rl = @import("common.zig").rl;
const xxhash = @import("smallxxhash.zig").smallxxhash32;
const perlin = @import("perlin.zig");

var cam = rl.Camera3D{
    .position = .{ .x = 10, .y = 10, .z = 10 },
    .target = .{ .x = 0, .y = 0, .z = 0 },
    .up = .{ .x = 0, .y = 1, .z = 0 },
    .fovy = 45,
    .projection = rl.CAMERA_PERSPECTIVE,
};

var scale: f32 = 20;

pub fn update() void {
    rl.BeginDrawing();
    defer rl.EndDrawing();

    rl.UpdateCamera(&cam);

    rl.ClearBackground(rl.RAYWHITE);
    rl.BeginMode3D(cam);
    {
        rl.DrawCube(.{
            .x = perlin.perlin1(@floatCast(f32, rl.GetTime())),
            .y = 0,
            .z = perlin.perlin1(@floatCast(f32, rl.GetTime() + 83)),
        }, 1, 1, 1, rl.RED);
        rl.DrawGrid(10, 1);
    }
    rl.EndMode3D();
}

pub fn init() void {
    rl.InitWindow(800, 800, "test");
    rl.SetTargetFPS(60);
    rl.SetCameraMode(cam, rl.CAMERA_FREE);
}

export fn web_update() callconv(.C) void {
    update();
}

export fn web_init() callconv(.C) void {
    init();
}
