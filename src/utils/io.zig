const std = @import("std");

fn readLineAlloc(a: std.mem.Allocator, reader: anytype) ![]const u8 {
    var list = std.ArrayList(u8).init(a);
    defer list.deinit();
    var writer = list.writer();

    reader.streamUntilDelimiter(writer, '\n', null) catch |err| {
        if (err != error.EndOfStream) {
            return err;
        }
    };

    return try list.toOwnedSlice();
}
