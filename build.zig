const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    // build raylib
    var libraylib = b.addStaticLibrary("raylib", null);
    const is_web_target = target.cpu_arch != null and target.cpu_arch.? == .wasm32;

    libraylib.addCSourceFile("raylib/src/rcore.c", &.{"-fno-sanitize=undefined"});
    libraylib.addCSourceFile("raylib/src/rshapes.c", &.{"-fno-sanitize=undefined"});
    libraylib.addCSourceFile("raylib/src/rtextures.c", &.{"-fno-sanitize=undefined"});
    libraylib.addCSourceFile("raylib/src/rtext.c", &.{"-fno-sanitize=undefined"});
    libraylib.addCSourceFile("raylib/src/rmodels.c", &.{"-fno-sanitize=undefined"});
    libraylib.addCSourceFile("raylib/src/utils.c", &.{"-fno-sanitize=undefined"});
    libraylib.addCSourceFile("raylib/src/raudio.c", &.{"-fno-sanitize=undefined"});
    libraylib.addIncludePath("raylib/src");

    libraylib.setTarget(target);
    libraylib.setBuildMode(mode);

    const libgame = b.addStaticLibrary("game", "src/game.zig");
    libgame.setBuildMode(mode);
    libgame.setTarget(target);
    libgame.addIncludePath("raylib/src");

    if (is_web_target) { // web
        if (b.sysroot == null) {
            @panic("need an emscripten --sysroot (e.g. --sysroot emsdk/upstream/emscripten) when building for web");
        }

        const emcc_path = try std.fs.path.join(b.allocator, &.{ b.sysroot.?, "emcc" });
        defer b.allocator.free(emcc_path);

        const em_include_path = try std.fs.path.join(b.allocator, &.{ b.sysroot.?, "cache/sysroot/include" });
        defer b.allocator.free(em_include_path);

        libraylib.defineCMacro("PLATFORM_WEB", "1");
        libraylib.addIncludePath(em_include_path);
        libraylib.defineCMacro("GRAPHICS_API_OPENGL_ES2", "1");

        // `source ~/src/emsdk/emsdk_env.sh` first
        const emcc = b.addSystemCommand(&.{
            emcc_path,
            "entry.c",
            "-g",
            "-ogame.html",
            "-Lzig-out/lib/",
            "-lgame",
            "-lraylib",
            "-sNO_FILESYSTEM=1",
            "-sLLD_REPORT_UNDEFINED=1",
            "-sFULL_ES3=1",
            "-sMALLOC='emmalloc'",
            "-sASSERTIONS=0",
            "-sUSE_GLFW=3",
            "-sSTANDALONE_WASM",
            "-sEXPORTED_FUNCTIONS=['_malloc','_free','_main']",
        });

        libraylib.install();
        libgame.install();

        emcc.step.dependOn(&libraylib.install_step.?.step);
        emcc.step.dependOn(&libgame.install_step.?.step);

        b.getInstallStep().dependOn(&emcc.step);
    } else { // desktop
        libraylib.defineCMacro("PLATFORM_DESKTOP", "1");
        libraylib.addCSourceFile("raylib/src/rglfw.c", &.{"-fno-sanitize=undefined"});
        if (target.isWindows()) {
            libraylib.linkSystemLibrary("opengl32");
            libraylib.linkSystemLibrary("gdi32");
            libraylib.linkSystemLibrary("winmm");
        } else if (target.isLinux()) {
            libraylib.linkSystemLibrary("pthread");
        }

        libraylib.install();
        libgame.install();

        const exe = b.addExecutable("game", "src/main.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.addIncludePath("raylib/src");
        exe.linkLibrary(libraylib);

        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    { // unit tests
        const tests = b.addTest("src/main.zig");
        tests.setTarget(target);
        tests.setBuildMode(mode);

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&tests.step);
    }
}
