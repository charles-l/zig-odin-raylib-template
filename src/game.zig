const std = @import("std");
const rl = @import("common.zig").rl;

var cam = rl.Camera3D{
    .position = .{ .x = 10, .y = 10, .z = 10 },
    .target = .{ .x = 0, .y = 0, .z = 0 },
    .up = .{ .x = 0, .y = 1, .z = 0 },
    .fovy = 45,
    .projection = rl.CAMERA_PERSPECTIVE,
};

pub fn update() void {
    rl.BeginDrawing();
    defer rl.EndDrawing();

    rl.UpdateCamera(&cam);

    rl.ClearBackground(rl.RAYWHITE);
    rl.BeginMode3D(cam);
    {
        rl.DrawCube(.{ .x = 0, .y = 0, .z = 0 }, 1, 1, 1, rl.RED);
        rl.DrawGrid(10, 1);
    }
    rl.EndMode3D();

    rl.DrawText("YOO", 10, 10, 20, rl.LIGHTGRAY);
}

pub fn init() void {
    rl.InitWindow(800, 400, "test");
    rl.SetTargetFPS(60);
    rl.SetCameraMode(cam, rl.CAMERA_FREE);
}

export fn web_update() callconv(.C) void {
    update();
}

export fn web_init() callconv(.C) void {
    init();
}
