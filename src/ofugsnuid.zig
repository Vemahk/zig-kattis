const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var a = gpa.allocator();

    const in = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(in);
    const stdin = br.reader();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const size = try readIntLine(a, stdin);

    var list = try a.alloc(usize, size);
    defer a.free(list);

    for (0..size) |i| {
        list[size - i - 1] = try readIntLine(a, stdin);
    }

    for (list) |l| {
        try std.fmt.format(stdout, "{d}\n", .{l});
    }

    try bw.flush();
}

fn readIntLine(a: std.mem.Allocator, reader: anytype) !usize {
    const line = try readLineAlloc(a, reader);
    defer a.free(line);
    return try std.fmt.parseInt(usize, line, 10);
}

fn readLineAlloc(a: std.mem.Allocator, reader: anytype) ![]const u8 {
    var list = std.ArrayList(u8).init(a);
    defer list.deinit();
    var writer = list.writer();

    reader.streamUntilDelimiter(writer, '\n', null) catch |err| {
        if (err != error.EndOfStream) {
            return err;
        }
    };

    return try list.toOwnedSlice();
}
