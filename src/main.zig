const std = @import("std");
pub const PasteboardError = error{ SizeMismatch, CopyFailed, SetDataFailed };

const swift = struct {
    pub const PasteboardItem = opaque {};

    extern "clip" fn pasteAs(dataTypeName: [*:0]const u8, buffer: [*]u8) u64;
    extern "clip" fn getPasteSize(dataTypeName: [*:0]const u8) u64;
    extern "clip" fn getTypes(buffer: [*]u8) u32;
    extern "clip" fn getTypesBufferSize() u32;
    extern "clip" fn clearBoard() void;
    extern "clip" fn createItem() *swift.PasteboardItem;
    extern "clip" fn setData(itemPointer: *swift.PasteboardItem, dataTypeName: [*:0]const u8, buffer: [*]const u8, size: u32) u8;
    extern "clip" fn copy(itemsPointer: [*]*swift.PasteboardItem, count: u8) u8;
    extern "clip" fn setAs(dataTypeName: [*:0]const u8, buffer: [*]u8, size: u32) u8;
    extern "clip" fn destroyItem(pointer: ?*swift.PasteboardItem) void;
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var iter = try std.process.argsWithAllocator(allocator);
    defer iter.deinit();

    // Program name
    _ = iter.next() orelse unreachable;

    var i: u8 = 0;
    while (iter.next()) |path| {
        // There are arguments with file names
        const real_path = try std.fs.realpathAlloc(allocator, path);
        const url = try std.fmt.allocPrint(allocator, "file://{s}", .{real_path});
        var name_splitter = std.mem.splitBackwards(u8, real_path, "/");
        const file_name = name_splitter.first();

        const item = Item.init();
        defer item.destroy();

        try item.setData("public.utf8-plain-text", file_name);
        try item.setData("public.file-url", url);

        clearBoard();
        const items: []Item = @ptrCast([*]Item, &item)[0..1];
        try copyToBoard(allocator, items);
        i += 1;
    } else {
        std.debug.print("Copied {d} file(s) to pasteboard!\n", .{i});
        return;
    }

    // No extra arguments; print out pasteboard
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
    var buffer = try allocator.alloc(u8, size + 1); // +1 for terminating null byte
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

pub fn clearBoard() void {
    swift.clearBoard();
}

pub fn copyToBoard(allocator: std.mem.Allocator, items: []Item) !void {
    var pointers = try allocator.alloc(*swift.PasteboardItem, items.len);
    defer allocator.free(pointers);
    for (items) |item, index| {
        pointers[index] = item.item;
    }
    const result = swift.copy(pointers.ptr, @intCast(u8, pointers.len));
    if (result != 0) return PasteboardError.CopyFailed;
}

pub const Item = struct {
    item: *swift.PasteboardItem,

    pub fn init() Item {
        return .{ .item = swift.createItem() };
    }

    pub fn setData(self: Item, dataTypeName: [*:0]const u8, data: []const u8) !void {
        const result = swift.setData(self.item, dataTypeName, data.ptr, @intCast(u32, data.len));
        if (result != 0) return PasteboardError.SetDataFailed;
    }

    pub fn destroy(self: Item) void {
        swift.destroyItem(self.item);
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
