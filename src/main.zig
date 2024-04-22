const std = @import("std");
const builtin = @import("builtin");

const File = std.fs.File;
const fd_t = std.os.fd_t;

const MAX_N = 20_000;

pub fn main() !void {
    var stdin = std.io.getStdIn();
    var stdout = std.io.getStdOut();

    if (builtin.mode == .Debug) {
        {
            var args = std.process.args();
            _ = args.skip();
            if (args.next()) |a| {
                if (std.mem.eql(u8, a, "judgeonly"))
                    return try judge(stdin, stdout);
            }
        }

        const c_pipes = try std.os.pipe();
        const p_pipes = try std.os.pipe();
        const pid = try std.os.fork();

        if (pid != 0) {
            std.os.close(p_pipes[1]);
            std.os.close(c_pipes[0]);
            const in = File{ .handle = p_pipes[0] };
            const out = File{ .handle = c_pipes[1] };

            return judge(in, out);
        }

        // redirect stdin and stdout to the parent.
        stdin = .{ .handle = c_pipes[0] };
        stdout = .{ .handle = p_pipes[1] };
        std.os.close(c_pipes[1]);
        std.os.close(p_pipes[0]);
    }

    const player = Player{
        .in = stdin.reader(),
        .out = stdout.writer(),
    };
    player.play() catch |err| {
        std.log.err("Child crashed!", .{});
        return err;
    };
}

const Weight = enum(u2) {
    Left,
    Center,
    Right,
};

const Player = struct {
    in: File.Reader,
    out: File.Writer,

    pub fn play(self: @This()) !void {
        const n = try nextInt(usize, self.in);
        const answer = try self.numOnes(0, n);
        try std.fmt.format(self.out, "! {d}\n", .{answer});
    }

    fn numOnes(self: @This(), s: usize, e: usize) !usize {
        const diff = e - s;

        if (diff == 0) return 0;
        if (diff == 1) return switch (try self.query(s, s, s, e)) {
            .Right => 1,
            .Center => 0,
            else => unreachable,
        };

        var ms = s;
        var me = e;
        while (true) {
            const breadth = me - ms;
            const m: usize = ms + breadth / 2;
            const q = try self.query(s, m, m, e);

            switch (q) {
                .Center => {},
                .Left => {
                    if (breadth > 2) {
                        me = m;
                        continue;
                    }
                },
                .Right => {
                    if (breadth > 2) {
                        ms = m;
                        continue;
                    }
                },
            }

            const small_left = m - s < e - m;
            const ns = if (small_left) s else m;
            const ne = if (small_left) m else e;
            var result = try self.numOnes(ns, ne) * 2;
            if (q != .Center) {
                if ((q == .Left) == small_left) {
                    result -= 1;
                } else result += 1;
            }
            return result;
        }
    }

    fn query(self: @This(), a: usize, b: usize, c: usize, d: usize) !Weight {
        try std.fmt.format(self.out, "? {d} {d} {d} {d}\n", .{ a, b, c, d });
        return switch (try nextInt(i2, self.in)) {
            -1 => .Left,
            0 => .Center,
            1 => .Right,
            else => unreachable,
        };
    }
};

fn judge(from_child: File, to_child: File) !void {
    const Cmd = enum(u1) {
        Query,
        Ans,
    };

    const ts: u64 = @intCast(std.time.milliTimestamp());
    var prng = std.rand.DefaultPrng.init(ts);
    var rand = prng.random();
    const size = rand.intRangeAtMost(usize, 1, MAX_N);
    const answer = rand.uintAtMost(usize, size);

    var board_buf: [MAX_N]bool = undefined;
    var board = board_buf[0..size];
    for (0..size) |i| board[i] = i < answer;
    rand.shuffle(bool, board);

    const closure = struct {
        board: []bool,
        pub fn numTrue(self: @This(), a: usize, b: usize) usize {
            if (a == b) return 0;
            return std.mem.count(bool, self.board[a..b], &[_]bool{true});
        }
    }{ .board = board };

    const out_fmt = "{d}\n";
    const stdout = std.io.getStdOut().writer();
    const reader = from_child.reader();
    const writer = to_child.writer();
    try std.fmt.format(writer, out_fmt, .{size});

    var query_count: usize = 0;

    while (true) {
        const cmd: Cmd = switch (try reader.readByte()) {
            '!' => .Ans,
            '?' => .Query,
            else => return error.UnknownChildCommand,
        };

        const space = try reader.readByte();
        if (space != ' ') @panic("bad input format - a space should follow a command.");

        switch (cmd) {
            .Ans => {
                const guess_val = try nextInt(usize, reader);

                if (guess_val == answer) {
                    try std.fmt.format(stdout, "Correct! The answer is {d}! Took {d} queries.\n", .{ answer, query_count });
                } else {
                    try std.fmt.format(stdout, "Incorrect! The answer is {d}! Took {d} queries.\n", .{ answer, query_count });
                }
                return;
            },
            .Query => {
                query_count += 1;
                var ints: [4]usize = undefined;
                try nextInts(usize, reader, &ints);

                const ac = closure.numTrue(ints[0], ints[1]);
                const bc = closure.numTrue(ints[2], ints[3]);

                const order = std.math.order(ac, bc);

                try to_child.writeAll(switch (order) {
                    .eq => "0\n",
                    .lt => "1\n",
                    .gt => "-1\n",
                });
            },
        }
    }
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

fn nextInts(comptime T: type, reader: anytype, out: []T) !void {
    const max_size = 20;
    var buf: [max_size]u8 = undefined;
    for (out) |*o| {
        const str = try next(reader, &buf);
        o.* = try std.fmt.parseInt(T, str, 10);
    }
}
