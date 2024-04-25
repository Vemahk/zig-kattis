const std = @import("std");
const builtin = @import("builtin");

const MAX_N = 100_000;
const MAX_STRLEN = 10;

const Id = u17;
const MAX_INPUT_SIZE = 7 + ((MAX_STRLEN + 1) << 1) + 10;
// const MAX_STRMAP_SIZE = (@sizeOf(Id) + @sizeOf([]const u8)) * MAX_N;
const MAX_STRMAP_SIZE = 4 << 20;

const MAX_MEM_SIZE = MAX_INPUT_SIZE + (MAX_STRMAP_SIZE * 2);

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const alloc = std.heap.page_allocator;

    var heap_mem = try alloc.alloc(u8, MAX_MEM_SIZE);
    defer alloc.free(heap_mem);

    const in_len = blk: {
        if (builtin.mode == .Debug) {
            break :blk try fuzz(heap_mem);
        } else {
            break :blk try std.io.getStdIn().readAll(heap_mem);
        }
    };

    // var timer = try std.time.Timer.start();
    // defer std.log.err("time: {d}", .{timer.lap()});

    var in_i: usize = 0;
    const N_str = next(heap_mem, &in_i);
    const N = try std.fmt.parseInt(usize, N_str, 10);
    if ((N & 1) == 1)
        return try stdout.writeAll("-1\n");

    var ba = std.heap.FixedBufferAllocator.init(heap_mem[in_len..]);

    var strs = struct {
        map: std.StringHashMapUnmanaged(Id) = .{},
        next_id: Id = 0,

        pub fn assign(self: *@This(), str: []const u8) Id {
            var result = self.map.getOrPutAssumeCapacity(str);
            if (result.found_existing)
                return result.value_ptr.*;

            var id = self.next_id;
            result.value_ptr.* = id;
            self.next_id += 1;
            return id;
        }
    }{};

    try strs.map.ensureTotalCapacity(ba.allocator(), MAX_N);
    // std.log.err("curiosity {d}", .{ba.end_index});

    var loves: [MAX_N]Id = undefined;
    var loved: [MAX_N]usize = undefined;
    var taken: [MAX_N]bool = undefined;

    for (0..N) |i| {
        loves[i] = MAX_N;
        loved[i] = 0;
        taken[i] = false;
    }

    for (0..N) |_| {
        const a = next(heap_mem, &in_i);
        const a_id = strs.assign(a);

        const b = next(heap_mem, &in_i);
        const b_id = strs.assign(b);

        // std.log.err("{s}({d}) {s}({d})", .{ a, a_id, b, b_id });

        loves[a_id] = b_id;
        loved[b_id] += 1;

        if (a_id != b_id and loves[b_id] == a_id) { // they luv each other uwu
            taken[a_id] = true;
            taken[b_id] = true;
        }
    }

    var arrows: usize = 0;

    // prune unloved; leaves abandoned and cycles
    for (0..N) |t| {
        if (taken[t]) continue;

        var i: Id = @intCast(t);
        while (loved[i] == 0) { // same
            const lover = loves[i];
            if (taken[lover]) break; // his heart, amirite?

            const past_lovers_lover = loves[lover];
            loves[lover] = i;
            loved[i] += 1; // yay!
            loved[past_lovers_lover] -= 1;
            taken[lover] = true;
            taken[i] = true;
            arrows += 1;

            // std.log.debug("{d} now loves {d}", .{ lover, i });

            i = past_lovers_lover;
        }
    }

    for (0..N) |t| {
        if (taken[t]) continue;

        var i: Id = @intCast(t);
        while (true) {
            arrows += 1;

            const lover = loves[i];
            if (i == lover or taken[lover]) {
                // std.log.debug("{d} is abandoned", .{i});
                break;
            }

            const past_lovers_lover = loves[lover];
            loves[lover] = i;
            loved[i] += 1; // yay!
            loved[past_lovers_lover] -= 1;
            taken[lover] = true;
            taken[i] = true;

            // std.log.debug("{d} now loves {d}", .{ lover, i });

            i = past_lovers_lover;
        }
    }

    try std.fmt.format(stdout, "{d}\n", .{arrows});
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

fn fuzz(buf: []u8) !usize {
    const ts: u64 = @intCast(std.time.milliTimestamp());
    std.log.err("seed {d}", .{ts});

    var prng = std.rand.DefaultPrng.init(ts);
    var rand = prng.random();

    var stream = std.io.fixedBufferStream(buf);
    var writer = stream.writer();

    //const N = rand.intRangeAtMost(usize, 2, MAX_N);
    const N = MAX_N;

    try std.fmt.format(writer, "{d}\n", .{N});

    var loves: [MAX_N]usize = undefined;
    for (0..N) |i| loves[i] = i;
    rand.shuffle(usize, loves[0..N]);

    var out_order: [MAX_N]usize = undefined;
    for (0..N) |i| out_order[i] = i;
    rand.shuffle(usize, out_order[0..N]);

    for (out_order[0..N]) |lover| {
        const l = loves[lover];
        try std.fmt.format(writer, "{d:0>10} {d:0>10}\n", .{ lover, l });
    }

    return stream.pos;
}
