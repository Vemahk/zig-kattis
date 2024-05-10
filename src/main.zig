const std = @import("std");

const MAX_N = 4101;
const MAX_M = 4101;
const MAX_MEM_SIZE: usize = 20 + (MAX_N + 1) * MAX_M;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const alloc = std.heap.page_allocator;

    var heap_mem = try alloc.alloc(u8, MAX_MEM_SIZE);
    defer alloc.free(heap_mem);

    const in_len = try std.io.getStdIn().readAll(heap_mem);
    _ = in_len;

    var in_i: usize = 0;

    const N = try std.fmt.parseInt(usize, next(heap_mem, &in_i), 10);
    const M = try std.fmt.parseInt(usize, next(heap_mem, &in_i), 10);
    _ = M;
    const K = try std.fmt.parseInt(usize, next(heap_mem, &in_i), 10);

    const Candidate = struct {
        str: []const u8,
        pos: usize,
    };

    var candidate = MaxList(Candidate, MAX_N){};
    var forsaken = MaxList([]const u8, MAX_N){};

    outer: for (0..N) |n| {
        const nstr = next(heap_mem, &in_i);

        var failed: bool = false;

        for (candidate.slice(), 0..) |c, i| {
            if (compare(c.str, nstr) != K) {
                forsaken.add(c.str);
                candidate.removeQuick(i);
                failed = true;
            }
        }

        if (failed) {
            forsaken.add(nstr);
            continue;
        }

        for (forsaken.slice()) |f| {
            if (compare(f, nstr) != K) {
                forsaken.add(nstr);
                continue :outer;
            }
        }

        candidate.add(.{
            .str = nstr,
            .pos = n,
        });
    }

    try std.fmt.format(stdout, "{d}", .{candidate.at(0).pos + 1});
}

fn compare(a: []const u8, b: []const u8) usize {
    var diff: usize = 0;

    for (a, b) |i, j| {
        if (i != j) diff += 1;
    }

    return diff;
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

        pub fn at(self: *Self, i: usize) T {
            return self.slice()[i];
        }

        pub fn removeQuick(self: *Self, i: usize) void {
            var s = self.slice();

            self.len -= 1;
            s[i] = s[self.len];
        }
    };
}

fn next(buf: []u8, start: *usize) []const u8 {
    const len = buf.len;
    var i = start.*;
    while (i < len) : (i += 1) {
        const b = buf[i];
        if (b == ' ' or b == '\n')
            continue;
        break;
    }

    const s = i;
    while (i < len) : (i += 1) {
        const b = buf[i];
        if (b == ' ' or b == '\n')
            break;
    }

    start.* = i;
    return buf[s..i];
}
