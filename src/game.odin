package main
import "core:runtime"
import rl "raylib"
import c "core:c"

@export
_fltused: c.int = 0

camera: rl.Camera3D

@export
init :: proc "c" () {
    context = runtime.default_context()
    // needed to setup some runtime type information in odin
    #force_no_inline runtime._startup_runtime()

    // TODO: figure out how to add hook to call runtime._cleanup_runtime()

    using rl
    camera.position = Vector3{3, 3, 3};
    camera.target = Vector3{};
    camera.up = Vector3{0, 1, 0};
    camera.fovy = 80;
    camera.projection = .PERSPECTIVE;
    InitWindow(600, 600, "test")
    SetTargetFPS(60);
}

@export
update :: proc "c" () {
    using rl
    BeginDrawing();
    defer EndDrawing();

    UpdateCamera(&camera, .ORBITAL);

    ClearBackground(GRAY);
    BeginMode3D(camera);
    {
        DrawCube(Vector3{ 0, 0, 0, }, 1, 1, 1, RED);
        DrawGrid(10, 1);
    }
    EndMode3D();
}


