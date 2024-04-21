const std = @import("std");

// graph distance

const MAX_L = 10_000;
const MAX_N = 1_000;
const MAX_H = 1_000;

pub fn main() !void {
    const in = std.io.getStdIn().reader();
    var br = std.io.bufferedReaderSize(1 << 14, in);
    const stdin = br.reader();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const N = try nextInt(usize, stdin);
    const H = try nextInt(usize, stdin);
    const L = try nextInt(usize, stdin);

    std.log.debug("N: {d}, H: {d}, L: {d}", .{ N, H, L });

    var hi_buf: [MAX_N]usize = undefined; // horror_index;
    var hi = hi_buf[0..N];
    initSlice(usize, hi, std.math.maxInt(usize));

    var h_buf: [MAX_H]usize = undefined; // horror_list
    var h = h_buf[0..H];
    for (0..H) |i| {
        h[i] = try nextInt(usize, stdin);
    }

    std.log.debug("h: {any}", .{h});

    var al = AdjLookup{};

    for (0..L) |_| {
        const ai = try nextInt(usize, stdin);
        const bi = try nextInt(usize, stdin);
        al.add(ai, bi);
    }
    al.harden();

    std.log.debug("al: {any}", .{al.links()});

    try fill(h, &al, hi);

    var max: usize = 0;
    var max_id: usize = 0;

    for (hi, 0..) |horror_index, id| {
        if (horror_index > max) {
            max = horror_index;
            max_id = id;
        }
    }

    try std.fmt.format(stdout, "{d}", .{max_id});

    try bw.flush();
}

fn nextInt(comptime T: type, reader: anytype) !T {
    const max_size = 20;
    var buf: [max_size]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);
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

    return try std.fmt.parseInt(T, buf[0..stream.pos], 10);
}

const AdjLookup = struct {
    const Link = struct {
        a: usize,
        b: usize,

        pub fn asc(_: void, a: Link, b: Link) bool {
            if (a.a == b.a) return a.b < b.b;
            return a.a < b.a;
        }

        pub fn search(comptime _: type, a: usize, mid: Link) std.math.Order {
            if (a == mid.a) return .eq;
            if (a < mid.a) return .lt;
            return .gt;
        }
    };

    const max_size = MAX_L * 2;

    buf: [max_size]Link = undefined,
    len: usize = 0,

    inline fn links(self: *@This()) []Link {
        return self.buf[0..self.len];
    }

    pub fn add(self: *@This(), a: usize, b: usize) void {
        self.buf[self.len] = .{ .a = a, .b = b };
        self.buf[self.len + 1] = .{ .a = b, .b = a };
        self.len += 2;
    }

    pub fn harden(self: *@This()) void {
        std.sort.pdq(Link, self.links(), {}, Link.asc);
        self.len = dedupeSortedSlice(Link, self.links());
    }

    pub fn findLinks(self: *@This(), id: usize) ?[]Link {
        const l = self.links();
        const fm = std.sort.binarySearch(Link, id, l, void, Link.search) orelse return null;

        var s: usize = 0;
        var fs = fm;
        while (s < fs) {
            const mi = (fs - s) / 2 + s;
            if (l[mi].a == id) {
                fs = mi;

                if (mi == 0 or l[mi - 1].a != id)
                    break;
            } else {
                s = fs + 1;
            }
        }

        s = fm;
        var fe = l.len;
        while (s < fe) {
            const mi = (fe - s) / 2 + s;
            if (l[mi].a == id) {
                s = mi + 1;
            } else {
                fe = mi;

                if (l[mi - 1].a == id)
                    break;
            }
        }

        return l[fs..fe];
    }
};

// assumes that no more than max_size elements will ever be pushed to it.
fn MaxQueue(comptime T: type, comptime max_size: comptime_int) type {
    return struct {
        q: [max_size]T = undefined,
        s: usize = 0,
        e: usize = 0,

        pub fn push(self: *@This(), t: T) void {
            self.q[self.e] = t;
            self.e += 1;
        }

        pub fn poll(self: *@This()) ?T {
            if (self.s == self.e)
                return null;
            const val = self.q[self.s];
            self.s += 1;
            return val;
        }
    };
}

fn fill(h: []const usize, al: *AdjLookup, hi: []usize) !void {
    const Val = struct {
        i: usize,
        hi: usize,
    };

    var visited: [MAX_N]bool = undefined;
    initSlice(bool, &visited, false);

    var q = MaxQueue(Val, MAX_N){};
    for (h) |id| {
        if (visited[id]) continue;
        visited[id] = true;
        q.push(.{ .i = id, .hi = 0 });
    }

    while (q.poll()) |val| {
        hi[val.i] = val.hi;
        const links = al.findLinks(val.i) orelse continue;
        for (links) |linked| {
            const t = linked.b; // target
            if (visited[t]) continue;
            visited[t] = true;
            q.push(.{ .i = t, .hi = val.hi + 1 });
        }
    }
}

inline fn initSlice(comptime T: type, slice: []T, val: T) void {
    for (0..slice.len) |i|
        slice[i] = val;
}

// returns the new length of the slice
fn dedupeSortedSlice(comptime T: type, slice: []T) usize {
    var i: usize = 0;
    var j: usize = 1;

    const len = slice.len;
    while (j < len) : (j += 1) {
        if (!std.meta.eql(slice[i], slice[j])) {
            i += 1;
            slice[i] = slice[j];
        }
    }

    return i + 1;
}
