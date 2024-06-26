const std = @import("std");

// reversing text;
// main difficulty is reading & writing quickly.
// minimize syscalls: read once, write once.
// minimize allocations: knowing the limited read size,
//  we can allocate only what we need on the stack.

pub fn main() !void {
    var bigbuf: [2 << 20]u8 = undefined;
    const len = try std.io.getStdIn().readAll(&bigbuf);

    var read = std.io.fixedBufferStream(bigbuf[0..len]);
    var reader = read.reader();

    const to_print = try readLinesStupid(reader, bigbuf[len..]);

    const stdout = std.io.getStdOut().writer();
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
