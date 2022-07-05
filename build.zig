const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const compile_swift = b.addSystemCommand(&[_][]const u8{ "swiftc", "-working-directory", b.cache_root, "-emit-library", "-o", "libpasteboard.a", b.pathFromRoot("src/libpasteboard.swift") });

    const exe = b.addExecutable("clip", "src/main.zig");
    exe.addLibraryPath(b.cache_root);
    exe.linkSystemLibrary("pasteboard");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
    exe.step.dependOn(&compile_swift.step);

    // zig build run
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // zig build test
    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
