const std = @import("std");

extern "pasteboard" fn pasteAs(dataTypeName: [*:0]const u8, buffer: [*]const u8) u64;
extern "pasteboard" fn getPasteSize(dataTypeName: [*:0]const u8) u64;
extern "pasteboard" fn getTypes(buffer: [*]const u8) u32;
extern "pasteboard" fn getTypesBufferSize() u32;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    {
        const type_name: [*:0]const u8 = "public.utf8-plain-text";
        const size = getPasteSize(type_name);
        const buffer = try allocator.alloc(u8, size);
        const count = pasteAs(type_name, buffer.ptr);
        std.debug.assert(size == count);
        std.debug.print("size: {d}\n", .{size});
        std.debug.print("string expression: {s}\n", .{buffer});
    }

    {
        const size = getTypesBufferSize();
        const buffer = try allocator.alloc(u8, size);
        const count = getTypes(buffer.ptr);
        std.debug.print("\navailable types:\n", .{});
        std.debug.print("{s}", .{buffer[0..count]});
    }
}
