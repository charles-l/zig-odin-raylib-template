const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const is_web_target = target.cpu_arch != null and target.cpu_arch.? == .wasm32;

    const libraylib = b.addStaticLibrary(.{
        .name = "raylib",
        .target = target,
        .optimize = optimize,
    });

    libraylib.addCSourceFile("raylib/src/rcore.c", &.{"-fno-sanitize=undefined"});
    libraylib.addCSourceFile("raylib/src/rshapes.c", &.{"-fno-sanitize=undefined"});
    libraylib.addCSourceFile("raylib/src/rtextures.c", &.{"-fno-sanitize=undefined"});
    libraylib.addCSourceFile("raylib/src/rtext.c", &.{"-fno-sanitize=undefined"});
    libraylib.addCSourceFile("raylib/src/rmodels.c", &.{"-fno-sanitize=undefined"});
    libraylib.addCSourceFile("raylib/src/utils.c", &.{"-fno-sanitize=undefined"});
    libraylib.addCSourceFile("raylib/src/raudio.c", &.{"-fno-sanitize=undefined"});

    libraylib.linkLibC();
    libraylib.addIncludePath("raylib/src");
    libraylib.addIncludePath("raylib/src/external/glfw/include/");

    if (is_web_target) {
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
        libraylib.stack_protector = false;
        b.installArtifact(libraylib);

        const libgame = b.addStaticLibrary(.{
            .name = "game",
            .root_source_file = .{ .path = "src/game.zig" },
            .target = target,
            .optimize = optimize,
        });
        libgame.addIncludePath("raylib/src");
        b.installArtifact(libgame);

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

        emcc.step.dependOn(&libraylib.step);
        emcc.step.dependOn(&libgame.step);

        b.getInstallStep().dependOn(&emcc.step);
    } else {
        libraylib.defineCMacro("PLATFORM_DESKTOP", "1");
        libraylib.addCSourceFile("raylib/src/rglfw.c", &.{ "-fno-sanitize=undefined", "-D_GNU_SOURCE" });

        if (target.isWindows()) {
            libraylib.linkSystemLibrary("opengl32");
            libraylib.linkSystemLibrary("gdi32");
            libraylib.linkSystemLibrary("winmm");
        } else if (target.isLinux()) {
            libraylib.linkSystemLibrary("pthread");
        }

        b.installArtifact(libraylib);

        const exe = b.addExecutable(.{
            .name = "game",
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });

        exe.addIncludePath("raylib/src");

        exe.linkLibrary(libraylib);

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);

        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
