const std = @import("std");

// coin change? kinda
// greedy take highest
// if overdraw of one more transaction is more than the next coin, prefer taking the next coin.

pub fn main() !void {
    const in = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(in);
    const stdin = br.reader();

    const coins = [_]usize{ 500, 200, 100 };

    var count_coins: usize = 0;
    var debt = try nextInt(usize, stdin);

    const m = debt % 100;
    if (m > 0) debt += 100 - m;

    for (coins) |coin| {
        if (debt >= coin) {
            const c = @divFloor(debt, coin);
            count_coins += c;
            debt -= c * coin;
            std.log.debug("{d} of {d}, {d} remaining", .{ c, coin, debt });
        }
    }

    const stdout = std.io.getStdOut().writer();

    try std.fmt.format(stdout, "{d}", .{count_coins});
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
