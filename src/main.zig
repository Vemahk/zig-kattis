const std = @import("std");

const MAX_N = 100_000;
const MAX_STRLEN = 10;

const Id = u17;
const MAX_INPUT_SIZE = 7 + ((MAX_STRLEN + 1) << 1) + 10;
const MAX_STRMAP_SIZE = (@sizeOf(Id) + @sizeOf([]const u8)) * MAX_N;

const MAX_MEM_SIZE = MAX_INPUT_SIZE + (MAX_STRMAP_SIZE * 3 / 2);

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var timer = try std.time.Timer.start();
    defer std.log.err("time: {d}ns", .{timer.lap()});

    const alloc = std.heap.page_allocator;

    var heap_mem = try alloc.alloc(u8, MAX_MEM_SIZE);
    defer alloc.free(heap_mem);
    const in_len = try std.io.getStdIn().readAll(heap_mem);

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

    var loves: [MAX_N]Id = undefined;
    var loved: [MAX_N]Id = undefined;
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

        if (loves[b_id] == a_id) { // they luv each other uwu
            taken[a_id] = true;
            taken[b_id] = true;
        }

        loves[a_id] = b_id;
        loved[b_id] += 1;
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
            taken[lover] = true;
            taken[i] = true;
            arrows += 1;

            std.log.debug("{d} now loves {d}", .{ lover, i });

            loved[past_lovers_lover] -= 1;
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
                std.log.debug("{d} is abandoned", .{i});
                break;
            }

            const past_lovers_lover = loves[lover];
            loves[lover] = i;
            loved[i] += 1; // yay!
            taken[lover] = true;
            taken[i] = true;

            std.log.debug("{d} now loves {d}", .{ lover, i });

            loved[past_lovers_lover] -= 1;
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
