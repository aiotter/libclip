const std = @import("std");
const clip = @import("./main.zig");
const py = @cImport({
    @cDefine("PY_SSIZE_T_CLEAN", "1");
    @cInclude("Python.h");
});

pub export fn paste_as(_: [*]py.PyObject, args: [*]py.PyObject) ?[*]py.PyObject {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var type_name: [*:0]u8 = undefined;
    if (py.PyArg_ParseTuple(args, "s", &type_name) == 0) return null;
    const data = clip.pasteAs(allocator, std.mem.sliceTo(type_name, 0)) catch return null;
    return py.PyBytes_FromStringAndSize(data.ptr, @intCast(isize, data.len));
}
