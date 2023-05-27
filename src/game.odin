package main
import "core:math/linalg"
import c "core:c"

Vector3 :: linalg.Vector3f32

// Camera projection
CameraProjection :: enum c.int {
	PERSPECTIVE = 0,
	ORTHOGRAPHIC,
}

Camera3D :: struct {
	position: Vector3,            // Camera position
	target:   Vector3,            // Camera target it looks-at
	up:       Vector3,            // Camera up vector (rotation over its axis)
	fovy:     f32,                // Camera field-of-view apperture in Y (degrees) in perspective, used as near plane width in orthographic
	projection: CameraProjection, // Camera projection: CAMERA_PERSPECTIVE or CAMERA_ORTHOGRAPHIC
}

Camera :: Camera3D

CameraMode :: enum c.int {
	CUSTOM = 0,
	FREE,
	ORBITAL,
	FIRST_PERSON,
	THIRD_PERSON,
}

camera: Camera3D

RED        :: Color{ 230, 41, 55, 255 }     // Red
RAYWHITE   :: Color{ 245, 245, 245, 255 }   // My own White (raylib logo)

Color :: struct {
	r: u8,                        // Color red value
	g: u8,                        // Color green value
	b: u8,                        // Color blue value
	a: u8,                        // Color alpha value
}

@(default_calling_convention="c")
foreign {
    // MANY OF THESE BINDINGS HAVE THE WRONG SIGNATURE!!!
    // Odin's C ABI doens't seem to be correct for small structs in WASM,
    // so it passes a pointer when the values should really be inlined.
    InitWindow        :: proc (width, height: c.int, title: cstring) ---  // Initialize window and OpenGL context
    SetTargetFPS      :: proc (fps: c.int) --- // Set target FPS (maximum)
    BeginDrawing      :: proc() ---                           // Setup canvas (framebuffer) to start drawing
    EndDrawing        :: proc() ---                           // End canvas drawing and swap buffers (double buffering)
    UpdateCamera      :: proc(camera: ^Camera, mode: CameraMode) ---                  // Update camera position for selected mode
    ClearBackground   :: proc(color: ^Color) ---               // Set background color (framebuffer clear color)
    BeginMode3D       :: proc(camera: Camera3D) ---           // Initializes 3D mode with custom camera (3D)
    EndMode3D         :: proc() ---                           // Ends 3D mode and returns to default 2D orthographic mode

    DrawCube            :: proc(position: ^Vector3, width, height, length: f32, color: ^Color) ---                                        // Draw cube
    DrawGrid            :: proc(slices: c.int, spacing: f32) ---                                                                        // Draw a grid (centered at (0, 0, 0))
}

@export
init :: proc "c" () {
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
    BeginDrawing();
    defer EndDrawing();

    UpdateCamera(&camera, .ORBITAL);

    red := RED
    white := RAYWHITE
    red.r = 0
    ClearBackground(&white);
    BeginMode3D(camera);
    {
        DrawCube(&Vector3{ 0, 0, 0, }, 1, 1, 1, &red);
        DrawGrid(10, 1);
    }
    EndMode3D();
}


