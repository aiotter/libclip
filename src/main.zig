const std = @import("std");
pub const PasteboardError = error{SizeMismatch};

const swift = struct {
    extern "clip" fn pasteAs(dataTypeName: [*:0]const u8, buffer: [*]u8) u64;
    extern "clip" fn getPasteSize(dataTypeName: [*:0]const u8) u64;
    extern "clip" fn getTypes(buffer: [*]u8) u32;
    extern "clip" fn getTypesBufferSize() u32;
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const data = try pasteAs(allocator, "public.utf8-plain-text");
    std.debug.print("=== string expression ===\n{s}\n", .{data});
    allocator.free(data);

    std.debug.print("\n=== available types ===\n", .{});
    var types = try getAvailableTypes(allocator);
    while (types.next()) |typeName| {
        std.debug.print("{s}\n", .{typeName});
    }
    types.free();
}

/// Fetch current pasteboard data.
/// allocator.free(return_value) must be called afterwards.
pub fn pasteAs(allocator: std.mem.Allocator, type_name: [:0]const u8) ![]u8 {
    const size = swift.getPasteSize(type_name.ptr);
    var buffer = try allocator.alloc(u8, size);
    const count = swift.pasteAs(type_name, buffer.ptr);
    if (size != count) return PasteboardError.SizeMismatch;
    return buffer;
}

/// Get all the available type names for the current pasteboard.
/// iterator.free() must be called afterwards.
pub fn getAvailableTypes(allocator: std.mem.Allocator) !TypeNameIterator {
    const size = swift.getTypesBufferSize();
    var buffer = try allocator.alloc(u8, size + 1); // +1 for null-terminated byte
    buffer[size] = 0;
    const count = swift.getTypes(buffer.ptr);
    if (size != count) return PasteboardError.SizeMismatch;
    return TypeNameIterator{ .allocator = allocator, .buffer = buffer[0..size :0] };
}

pub const TypeNameIterator = struct {
    allocator: std.mem.Allocator,
    buffer: [:0]const u8,
    index: usize = 0,

    pub fn next(self: *TypeNameIterator) ?[:0]const u8 {
        if (self.index >= self.buffer.len - 1) return null;
        const slice = std.mem.sliceTo(self.buffer[self.index..], 0);
        self.index += slice.len + 1;
        return slice;
    }

    pub fn free(self: *TypeNameIterator) void {
        self.allocator.free(self.buffer);
    }
};

test "Fetch current pasteboard data for all the available types" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var types = try getAvailableTypes(allocator);
    defer allocator.free(types.buffer);
    while (types.next()) |typeName| {
        const data = try pasteAs(allocator, typeName);
        allocator.free(data);
    }
}
