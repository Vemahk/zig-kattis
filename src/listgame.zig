const std = @import("std");

// prime factorization.

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

    const num = blk: {
        const line = try readLine(a, stdin);
        defer a.free(line);

        break :blk try std.fmt.parseInt(usize, line, 10);
    };

    const count = try countPrimeFactors(a, num);

    try std.fmt.format(stdout, "{d}\n", .{count});
    try bw.flush();
}

fn countPrimeFactors(a: std.mem.Allocator, num: usize) !usize {
    const s = sqrtFloor(num);
    const primes = try getPrimesUpTo(a, s);
    defer a.free(primes);

    var count: usize = 0;
    var x = num;
    for (primes) |prime| {
        while (x % prime == 0) {
            std.log.debug("{d} is a prime factor of {d}.", .{ prime, x });
            x /= prime;
            count += 1;
        }
    }

    std.log.debug("{d} remaining.", .{x});

    if (x > 1) count += 1;

    return count;
}

fn getPrimesUpTo(a: std.mem.Allocator, max: usize) ![]const usize {
    var timer = try std.time.Timer.start();
    if (max < 2) {
        return try a.alloc(usize, 0);
    }

    if (max < 3) {
        var primes = try a.alloc(usize, 1);
        errdefer a.free(primes);
        primes[0] = 2;
        return primes;
    }

    if (max < 5) {
        var primes = try a.alloc(usize, 2);
        errdefer a.free(primes);
        primes[0] = 2;
        primes[1] = 3;
        return primes;
    }

    var list = std.ArrayList(usize).init(a);
    defer list.deinit();
    try list.append(2);

    var sieve = try a.alloc(bool, max + 1);
    defer a.free(sieve);

    for (sieve, 0..) |*b, i| {
        b.* = i == 2 or (i > 2 and (i & 1) == 1);
    }

    var i: usize = 3;
    while (i <= max) : (i += 2) {
        if (!sieve[i]) continue;

        try list.append(i);

        var x: usize = i * i;
        while (x <= max) : (x += i) {
            sieve[x] = false;
        }
    }

    const t1 = timer.lap();
    std.log.debug("Primes to {d} took {d}ns", .{ max, t1 });

    return list.toOwnedSlice();
}

inline fn sqrtFloor(num: usize) usize {
    return @intFromFloat(@floor(@sqrt(@as(f32, @floatFromInt(num)))));
}

fn readLine(a: std.mem.Allocator, reader: anytype) ![]const u8 {
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
