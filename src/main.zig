const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var a = gpa.allocator();

    const in = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(in);
    const stdin = br.reader();

    const stdout = std.io.getStdOut().writer();

    const size = try readIntLine(stdin);

    const bigbuf = try a.alloc(u8, size * 20);
    defer a.free(bigbuf);

    const to_print = try readLinesStupid(stdin, size, bigbuf);

    _ = try stdout.write(to_print);
}

fn readIntLine(reader: anytype) !usize {
    const max_size = 20;
    var buf: [max_size]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);
    var writer = stream.writer();
    reader.streamUntilDelimiter(writer, '\n', max_size) catch |err| {
        if (err != error.EndOfStream) {
            return err;
        }
    };
    return try std.fmt.parseInt(usize, buf[0..stream.pos], 10);
}

// A sub-slice of the given buffer that was written to.
fn readLinesStupid(reader: anytype, lines: usize, bigbuf: []u8) ![]const u8 {
    var head = bigbuf.len;

    const max_size = 20;
    var buf: [max_size]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);
    var writer = stream.writer();

    var i: usize = 0;
    while (i < lines) : (i += 1) {
        stream.reset();
        try reader.streamUntilDelimiter(writer, '\n', max_size);
        try writer.writeByte('\n');

        const len = stream.pos;
        @memcpy(bigbuf[(head - len)..head], buf[0..len]);
        head -= len;
    }

    return bigbuf[head..];
}
