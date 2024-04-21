const std = @import("std");
const builtin = @import("builtin");

const File = std.fs.File;
const fd_t = std.os.fd_t;

pub fn main() !void {
    var old_stdout: ?std.os.fd_t = null;

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

        // keep a copy of old stdout, just in case.
        old_stdout = try std.os.dup(std.os.STDOUT_FILENO);

        // redirect stdin and stdout to the parent.
        stdin = .{ .handle = c_pipes[0] };
        stdout = .{ .handle = p_pipes[1] };
        std.os.close(c_pipes[1]);
        std.os.close(p_pipes[0]);
    }

    guess(stdin, stdout) catch |err| {
        const out = old_stdout orelse stdout.handle;
        _ = try std.os.write(out, "Child crashed!");

        return err;
    };
}

fn guess(stdin: File, stdout: File) !void {
    const query_fmt = "? {d} {d} {d} {d}\n";
    _ = query_fmt;
    const ans_fmt = "! {d}\n";
    _ = ans_fmt;

    const in = stdin.reader();
    var br = std.io.bufferedReader(in);
    const reader = br.reader();
    var buf: [20]u8 = undefined;
    const len = try next(reader, &buf);

    const out = stdout.writer();
    try std.fmt.format(out, "We read {s}!\n", .{buf[0..len]});
}

fn judge(in: File, out: File) !void {
    _ = try out.write("ASLKJF\n");
    var buf: [100]u8 = undefined;
    var b_stream = std.io.fixedBufferStream(&buf);
    var b_writer = b_stream.writer();
    try in.reader().streamUntilDelimiter(b_writer, '\n', null);

    var stdout = std.io.getStdOut().writer();
    try std.fmt.format(stdout, "Received '{s}' from the child.", .{buf[0..b_stream.pos]});
}

fn next(reader: anytype, buf: []u8) !usize {
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

    return stream.pos;
}
