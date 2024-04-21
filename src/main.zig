const std = @import("std");
const builtin = @import("builtin");

const File = std.fs.File;
const fd_t = std.os.fd_t;

const MAX_N = 20_000;

pub fn main() !void {
    var stdin = std.io.getStdIn();
    var stdout = std.io.getStdOut();

    if (builtin.mode == .Debug) {
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

    guess(stdin, stdout) catch |err| {
        _ = try std.io.getStdOut().write("Child crashed!");
        return err;
    };
}

fn guess(stdin: File, stdout: File) !void {
    const query_fmt = "? {d} {d} {d} {d}\n";
    _ = query_fmt;
    const ans_fmt = "! {d}\n";

    const in = stdin.reader();
    var br = std.io.bufferedReader(in);
    const reader = br.reader();
    var buf: [20]u8 = undefined;
    const len = try next(reader, &buf);
    _ = len;

    const out = stdout.writer();
    try std.fmt.format(out, ans_fmt, .{0});
}

fn judge(from_child: File, to_child: File) !void {
    const Cmd = enum(u1) {
        Query,
        Ans,
    };

    const ts: u64 = @intCast(std.time.milliTimestamp());
    var prng = std.rand.DefaultPrng.init(ts);
    var rand = prng.random();
    const size = rand.intRangeAtMost(usize, 1, MAX_N);

    var board_buf: [MAX_N]bool = undefined;
    var board = board_buf[0..size];
    for (0..size) |i| board[i] = rand.boolean();

    const closure = struct {
        board: []bool,
        pub fn numTrue(self: @This(), a: usize, b: usize) usize {
            if (a == b) return 0;
            return std.mem.count(bool, self.board[a..b], &[_]bool{true});
        }
    }{ .board = board };

    const answer = closure.numTrue(0, size);

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
