const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const PriorityQueue = std.PriorityQueue;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
const math = std.math;
const Str = []const u8;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = [2]i32;
const Map = AutoHashMap(Point, u8);

const HillMap = struct {
    map: Map,
    start: Point,
    end: Point,

    fn parse(text: Str) !HillMap {
        var map = Map.init(gpa);
        var start: Point = undefined;
        var end: Point = undefined;

        var line_iter = mem.split(u8, text, "\n");

        var y: i32 = 0;
        while (line_iter.next()) |line| : (y += 1) {
            var x: i32 = 0;
            for (line) |c| {
                if (c == 'S') {
                    start = Point{ x, y };
                    try map.put(.{ x, y }, 'a');
                } else if (c == 'E') {
                    end = Point{ x, y };
                    try map.put(.{ x, y }, 'z');
                } else {
                    try map.put(.{ x, y }, c);
                }
                x += 1;
            }
        }
        return HillMap{ .start = start, .end = end, .map = map };
    }

    fn deinit(self: *HillMap) void {
        self.map.deinit();
    }
};

const PC = struct {
    p: Point,
    c: i32,
};

fn getNeighbors(p: Point) [4]Point {
    const x = p[0];
    const y = p[1];

    const neighbors = [_]Point{
        .{ x - 1, y },
        .{ x + 1, y },
        .{ x, y - 1 },
        .{ x, y + 1 },
    };

    return neighbors;
}

fn isReachable(map: *Map, cur: Point, next: Point) bool {
    if (map.get(next)) |n| {
        const c = map.get(cur) orelse unreachable;
        return c + 1 >= n;
    } else {
        return false;
    }
}

fn compPc(_: void, a: PC, b: PC) std.math.Order {
    return std.math.order(a.c, b.c);
}

// from last year
fn ucs(map: *Map, start: Point, tgt: Point) !?i32 {
    var frontier = PriorityQueue(PC, void, compPc).init(gpa, {});
    defer frontier.deinit();

    var visited = AutoHashMap(Point, i32).init(gpa);
    defer visited.deinit();

    try frontier.add(PC{ .p = start, .c = 0 });

    while (frontier.removeOrNull()) |cur| {
        var cur_cost = cur.c;

        try visited.put(cur.p, cur.c);

        if (mem.eql(i32, cur.p[0..], tgt[0..])) {
            return cur.c;
        }

        const neighbors = getNeighbors(cur.p);

        for (neighbors) |np| {
            if (!isReachable(map, cur.p, np)) {
                continue;
            }

            var cost = cur_cost + 1;
            if (visited.get(np)) |old_c| {
                if (old_c > cost) {
                    try frontier.add(PC{ .p = np, .c = cost });
                    try visited.put(np, cost);
                }
            } else {
                try frontier.add(PC{ .p = np, .c = cost });
                try visited.put(np, cost);
            }
        }
    }

    return null;
}

fn p1(text: Str) !i32 {
    var hill_map = try HillMap.parse(text);
    defer hill_map.deinit();

    var c = try ucs(&hill_map.map, hill_map.start, hill_map.end);

    return c.?;
}

fn p2(text: Str) !i32 {
    var hill_map = try HillMap.parse(text);
    defer hill_map.deinit();

    var m: i32 = std.math.maxInt(i32);
    var kv_iter = hill_map.map.iterator();
    while (kv_iter.next()) |kv| {
        if (kv.value_ptr.* == 'a') {
            if (try ucs(&hill_map.map, kv.key_ptr.*, hill_map.end)) |c| {
                m = @min(m, c);
            }
        }
    }

    return m;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
