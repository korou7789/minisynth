const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "minisynth",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    const miniaudio = b.dependency("miniaudio", .{});

    const translate = b.addTranslateC(.{
        .root_source_file = miniaudio.path("miniaudio.h"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("ma", translate.createModule());

    exe.root_module.addIncludePath(miniaudio.path(""));
    exe.root_module.addCSourceFile(.{
        .file = miniaudio.path("miniaudio.c"),
        .flags = &.{},
    });
    exe.root_module.link_libc = true;

    exe.root_module.linkSystemLibrary("pthread", .{});
    exe.root_module.linkSystemLibrary("m", .{});
    exe.root_module.linkSystemLibrary("dl", .{});


    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    run_cmd.addPassthruArgs();

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
