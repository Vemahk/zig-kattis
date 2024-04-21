const std = @import("std");

pub fn main() !void {
    const in = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(in);
    const stdin = br.reader();

    const N = try nextInt(usize, stdin); // rooms
    const M = try nextInt(usize, stdin); // teams

    var list = MaxList(u8, 1000){};

    const min = M / N;
    const num_max = M % N;

    for (0..N) |n| {
        for (0..min) |_|
            list.add('*');

        if (n < num_max)
            list.add('*');

        list.add('\n');
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.writeAll(list.slice());
}

fn nextInt(comptime T: type, reader: anytype) !T {
    const max_size = 20;
    var buf: [max_size]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);
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

    return try std.fmt.parseInt(T, buf[0..stream.pos], 10);
}

pub fn MaxList(comptime T: type, comptime max_size: comptime_int) type {
    return struct {
        const Self = @This();

        buf: [max_size]T = undefined,
        len: usize = 0,

        pub fn add(self: *Self, t: T) void {
            if (self.len >= max_size) unreachable;
            self.buf[self.len] = t;
            self.len += 1;
        }

        pub inline fn slice(self: *Self) []T {
            return self.buf[0..self.len];
        }
    };
}
