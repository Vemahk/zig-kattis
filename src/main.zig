const std = @import("std");

pub fn main() !void {
    const in = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(in);
    const stdin = br.reader();

    const stdout = std.io.getStdOut().writer();

    var bigbuf: [1 << 20]u8 = undefined;
    const to_print = try readLinesStupid(stdin, &bigbuf);

    _ = try stdout.write(to_print);
}

// A sub-slice of the given buffer that was written to.
fn readLinesStupid(reader: anytype, bigbuf: []u8) ![]const u8 {
    try reader.skipUntilDelimiterOrEof('\n');

    var head = bigbuf.len;

    const max_size = 20;
    var buf: [max_size]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);
    var writer = stream.writer();

    var eos = false;
    while (!eos) {
        stream.reset();
        reader.streamUntilDelimiter(writer, '\n', max_size) catch |err| {
            if (err != error.EndOfStream)
                return err;
            eos = true;
        };

        const len = stream.pos;
        if (len == 0) continue;

        bigbuf[head - 1] = '\n';
        head -= 1;

        @memcpy(bigbuf[(head - len)..head], buf[0..len]);
        head -= len;
    }

    return bigbuf[head..];
}
