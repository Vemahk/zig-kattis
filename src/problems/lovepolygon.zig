const std = @import("std");

const MAX_N = 100_000;
const MAX_STRLEN = 10;

const Id = u17;
const MAX_INPUT_SIZE = 7 + ((MAX_STRLEN + 1) << 1) + 10;
const MAX_STRMAP_SIZE = (@sizeOf(Id) + @sizeOf([]const u8)) * MAX_N;

const MAX_MEM_SIZE = MAX_INPUT_SIZE + (MAX_STRMAP_SIZE * 3 / 2);

pub fn main() !void {
    var timer = try std.time.Timer.start();
    defer std.log.debug("time: {d}", .{timer.lap()});

    const alloc = std.heap.page_allocator;

    var heap_mem = try alloc.alloc(u8, MAX_MEM_SIZE);
    defer alloc.free(heap_mem);
    const in_len = try std.io.getStdIn().readAll(heap_mem);

    var ba = std.heap.FixedBufferAllocator.init(heap_mem[in_len..]);
    const map_alloc = ba.allocator();
    var strmap = std.StringHashMap(Id).init(map_alloc);
    try strmap.ensureTotalCapacity(MAX_N);

    var in_i: usize = 0;

    const stdout = std.io.getStdOut().writer();

    const N_str = next(heap_mem, &in_i);
    const N = try std.fmt.parseInt(usize, N_str, 10);
    if ((N & 1) == 1)
        return try stdout.writeAll("-1\n");

    var next_id: Id = 0;
    _ = next_id;
    for (0..N) |_| {
        const a = next(heap_mem, &in_i);
        _ = a;
        const b = next(heap_mem, &in_i);
        _ = b;
    }
}

fn next(buf: []u8, start: *usize) []const u8 {
    var i = start.*;
    while (true) : (i += 1) {
        const b = buf[i];
        if (b == ' ' or b == '\n')
            continue;
        break;
    }

    const s = i;
    while (true) : (i += 1) {
        const b = buf[i];
        if (b == ' ' or b == '\n')
            break;
    }

    start.* = i;
    return buf[s..i];
}
