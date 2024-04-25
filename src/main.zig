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

    var in_i: usize = 0;

    const stdout = std.io.getStdOut().writer();

    var loves: [MAX_N]Id = undefined;

    const N_str = next(heap_mem, &in_i);
    const N = try std.fmt.parseInt(usize, N_str, 10);
    if ((N & 1) == 1)
        return try stdout.writeAll("-1\n");

    for (0..N) |_| {
        const a = next(heap_mem, &in_i);
        const a_id = strs.assign(a);

        const b = next(heap_mem, &in_i);
        const b_id = strs.assign(b);

        loves[a_id] = b_id;
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
