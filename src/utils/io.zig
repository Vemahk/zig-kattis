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

fn next(reader: anytype, buf: []u8) ![]const u8 {
    var stream = std.io.fixedBufferStream(buf);
    var writer = stream.writer();

    while (true) {
        const b = reader.readByte() catch |err| {
            if (err != error.EndOfStream)
                return err;
            break;
        };

        if (b == ' ' or b == '\n')
            break;

        try writer.writeByte(b);
    }

    return buf[0..stream.pos];
}

fn nextInt(comptime T: type, reader: anytype) !T {
    const max_size = 20;
    var buf: [max_size]u8 = undefined;
    const str = try next(reader, &buf);
    return try std.fmt.parseInt(T, str, 10);
}
