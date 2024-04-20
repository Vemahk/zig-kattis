const std = @import("std");

pub fn main() !void {
    const in = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(in);
    const stdin = br.reader();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    while (true) {
        stdin.streamUntilDelimiter(stdout, '\n', null) catch |err| {
            if (err != error.EndOfStream) {
                return err;
            }

            break;
        };

        try stdout.writeByte('\n');
        try bw.flush();
    }

    try bw.flush();
}
