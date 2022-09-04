const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const compile_swift = b.addSystemCommand(&[_][]const u8{
        "swiftc",
        "-working-directory",
        b.cache_root,
        "-emit-library",
        "-o",
        "libclip.a",
        b.pathFromRoot("src/libclip.swift"),
    });
    const compile_swift_needed = buildNeeded("src/libclip.swift", b.pathJoin(&.{ b.cache_root, "libclip.a" }));

    const exe = b.addExecutable("clip", "src/main.zig");
    if (compile_swift_needed) exe.step.dependOn(&compile_swift.step);
    exe.addLibraryPath(b.cache_root);
    exe.linkSystemLibrary("clip");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    // zig build python-lib
    const python_includes = try std.ChildProcess.exec(.{ .allocator = b.allocator, .argv = &.{ "python3", "-c", "import sysconfig; print(sysconfig.get_config_var('INCLUDEPY'));" } });
    const python_includes_dir = std.mem.sliceTo(python_includes.stdout, '\n');

    const python_lib = try std.ChildProcess.exec(.{ .allocator = b.allocator, .argv = &.{ "python3", "-c", "import sysconfig; print(sysconfig.get_config_var('LIBRARY'));" } });
    const python_lib_name = getLibName(std.mem.sliceTo(python_lib.stdout, '\n'));

    const python_lib_dir = try std.ChildProcess.exec(.{ .allocator = b.allocator, .argv = &.{ "python3", "-c", "import sysconfig; print(sysconfig.get_config_var('LIBDIR'));" } });
    const python_lib_dir_path = std.mem.sliceTo(python_lib_dir.stdout, '\n');

    const lib = b.addSharedLibrary("pyclip", "src/pyclip.zig", .unversioned);
    lib.addCSourceFile("src/pyclip.c", &.{ "-Wall", "-fPIC", "-c", "-D__sched_priority=0", "-DNDEBUG" });
    lib.addIncludeDir(python_includes_dir);
    if (compile_swift_needed) lib.step.dependOn(&compile_swift.step);
    lib.addLibraryPath(b.cache_root);
    lib.linkSystemLibrary("clip");
    lib.addLibraryPath(python_lib_dir_path);
    lib.linkSystemLibrary(python_lib_name);
    lib.setTarget(target);
    lib.setBuildMode(mode);
    // lib.install();
    const install_python_lib = b.addInstallArtifact(lib);

    const install_python_lib_step = b.step("python-lib", "Install python library");
    install_python_lib_step.dependOn(&install_python_lib.step);

    // const rename_lib = b.addSystemCommand(&.{ "mv", b.pathJoin(&.{ b.lib_dir, lib.out_filename }), b.pathJoin(&.{ b.lib_dir, "clip.so" }) });
    // rename_lib.step.dependOn(b.getInstallStep());
    // rename_lib.step.dependOn(&lib.step);

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
    if (compile_swift_needed) exe_tests.step.dependOn(&compile_swift.step);
    exe_tests.addLibraryPath(b.cache_root);
    exe_tests.linkSystemLibrary("clip");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

fn buildNeeded(source: []const u8, built: []const u8) bool {
    const sourceFile = std.fs.cwd().openFile(source, .{}) catch unreachable;
    defer sourceFile.close();
    const builtFile = std.fs.cwd().openFile(built, .{}) catch return true;
    defer builtFile.close();

    const sourceFileModified = (sourceFile.metadata() catch return true).modified();
    const builtFileCreated = (builtFile.metadata() catch return true).created().?;
    return sourceFileModified > builtFileCreated;
}

fn getLibName(file_name: []const u8) []const u8 {
    var name = std.mem.trimLeft(u8, file_name, "lib");
    inline for (.{ ".a", ".dylib", ".so" }) |ext| {
        name = std.mem.trimRight(u8, name, ext);
    }
    return name;
}
