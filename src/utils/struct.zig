const std = @import("std");

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
