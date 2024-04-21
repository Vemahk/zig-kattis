const std = @import("std");

pub fn main() !void {
    const in = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(in);
    const stdin = br.reader();

    const h = try nextInt(usize, stdin);
    const P = try nextInt(usize, stdin);

    var day: usize = 0;
    var inc_lamp = Lamp(60, 1000, 5){};
    var le_lam = Lamp(11, 8000, 60){};

    while (inc_lamp.cost <= le_lam.cost) {
        day += 1;
        inc_lamp.tick(h, P);
        le_lam.tick(h, P);
    }

    const stdout = std.io.getStdOut().writer();

    try std.fmt.format(stdout, "{d}", .{day});
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

fn Lamp(
    comptime Power: comptime_int,
    comptime Life: comptime_int,
    comptime Price: comptime_int,
) type {
    return struct {
        const Self = @This();

        age: usize = Life,
        cost: f64 = 0,

        pub fn tick(self: *Self, hours: usize, e_price: usize) void {
            self.age += hours;
            if (self.age > Life) {
                self.cost += Price;
                self.age -= Life;
            }

            self.cost += @as(f64, @floatFromInt(Power * hours * e_price)) / 100_000;
        }
    };
}
