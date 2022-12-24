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

const Point = [2]i16;
const Map = AutoHashMap(Point, void);
const Dir = enum {
    Up,
    Down,
    Left,
    Right,

    fn fromChar(c: u8) ?Dir {
        return switch (c) {
            '^' => Dir.Up,
            'v' => Dir.Down,
            '<' => Dir.Left,
            '>' => Dir.Right,
            else => null,
        };
    }

    fn asVec(self: *Dir) Point {
        return switch (self.*) {
            Dir.Up => .{ 0, -1 },
            Dir.Down => .{ 0, 1 },
            Dir.Left => .{ -1, 0 },
            Dir.Right => .{ 1, 0 },
        };
    }
};

const Blizzard = struct {
    pos: Point,
    dir: Dir,
};

const Valley = struct {
    w: i16,
    h: i16,
    blizzards: ArrayList(Blizzard),
    turn: usize = 0,

    fn parseMap(text: Str) !Valley {
        var ret: Valley = undefined;
        ret.blizzards = ArrayList(Blizzard).init(gpa);

        ret.h = @intCast(i16, mem.count(u8, text, "\n")) + 1;
        var line_iter = mem.split(u8, text, "\n");

        var y: i16 = 0;
        while (line_iter.next()) |line| : (y += 1) {
            ret.w = @intCast(i16, line.len);
            var x: i16 = 0;
            for (line) |c| {
                if (Dir.fromChar(c)) |d| {
                    try ret.blizzards.append(Blizzard{ .pos = .{ x, y }, .dir = d });
                }
                x += 1;
            }
        }
        return ret;
    }

    fn deinit(self: *Valley) void {
        self.blizzards.deinit();
    }

    fn moveBlizzards(self: *Valley) void {
        for (self.blizzards.items) |*b| {
            var pos = add(b.pos, b.dir.asVec());
            if (pos[0] == 0) pos[0] = self.w - 2;
            if (pos[1] == 0) pos[1] = self.h - 2;
            if (pos[0] == self.w - 1) pos[0] = 1;
            if (pos[1] == self.h - 1) pos[1] = 1;
            b.pos = pos;
        }
    }

    fn isReachable(self: *Valley, map: *Map, pos: Point) bool {
        if (pos[0] == 1 and pos[1] == 0) {
            return true;
        } else if (pos[0] == self.w - 2 and pos[1] == self.h - 1) {
            return true;
        } else if (pos[0] <= 0) {
            return false;
        } else if (pos[1] <= 0) {
            return false;
        } else if (pos[0] >= self.w - 1) {
            return false;
        } else if (pos[1] >= self.h - 1) {
            return false;
        }

        return !map.contains(pos);
    }

    fn paint(self: *Valley, map: *Map) void {
        var y: i16 = 0;
        while (y < self.h) : (y += 1) {
            var x: i16 = 0;
            while (x < self.w) : (x += 1) {
                if (map.contains(.{ x, y })) {
                    print("X", .{});
                } else {
                    print(".", .{});
                }
            }
            print("\n", .{});
        }
        print("\n", .{});
    }

    fn end(self: *Valley) Point {
        return .{ self.w - 2, self.h - 1 };
    }

    fn start(_: *Valley) Point {
        return .{ 1, 0 };
    }
};

const PC = struct {
    p: Point,
    c: usize,
};

fn abs(a: i16) i16 {
    return std.math.absInt(a) catch 0;
}

fn mDist(a: Point, b: Point) i16 {
    const x = abs(a[0] - b[0]);
    const y = abs(a[1] - b[1]);
    return x + y;
}

fn compPc(valley: *Valley, a: PC, b: PC) std.math.Order {
    const cmp = std.math.order(mDist(valley.end(), a.p), mDist(valley.end(), b.p));
    if (cmp == std.math.Order.eq) {
        return std.math.order(a.c, b.c);
    }
    return cmp;
}

fn getNeighbors(p: Point) [5]Point {
    const x = p[0];
    const y = p[1];

    const neighbors = [_]Point{
        .{ x, y },
        .{ x - 1, y },
        .{ x + 1, y },
        .{ x, y - 1 },
        .{ x, y + 1 },
    };

    return neighbors;
}

fn getBlizzardMap(list: []const Blizzard) !Map {
    var map = Map.init(gpa);
    for (list) |b| {
        try map.put(b.pos, {});
    }
    return map;
}

fn ucs(valley: *Valley, start: Point, tgt: Point) !usize {
    var frontier = PriorityQueue(PC, *Valley, compPc).init(gpa, valley);
    defer frontier.deinit();

    var maps = ArrayList(Map).init(gpa);
    defer maps.deinit();
    defer for (maps.items) |*m| m.deinit();

    try maps.append(try getBlizzardMap(valley.blizzards.items));

    var visited = AutoHashMap(PC, void).init(gpa);
    defer visited.deinit();

    try frontier.add(PC{ .p = start, .c = 0 });

    var best: usize = 9999;

    while (frontier.removeOrNull()) |cur| {
        var cur_cost = cur.c;

        if (maps.items.len <= cur.c + 1) {
            valley.moveBlizzards();
            try maps.append(try getBlizzardMap(valley.blizzards.items));
        }

        const dist = mDist(cur.p, tgt);

        if (@intCast(usize, dist) + cur.c >= best) {
            continue;
        }

        if (visited.contains(cur)) {
            continue;
        }
        try visited.put(cur, {});

        const map = &maps.items[cur.c + 1];

        if (mem.eql(i16, cur.p[0..], tgt[0..])) {
            if (cur.c < best) {
                best = cur.c;
            }
        }

        const neighbors = getNeighbors(cur.p);

        for (neighbors) |np| {
            if (!valley.isReachable(map, np)) {
                continue;
            }
            var cost = cur_cost + 1;
            try frontier.add(PC{ .p = np, .c = cost });
        }
    }

    return best;
}

fn ucs2(valley: *Valley, start: Point, tgt: Point) !usize {
    var frontier = PriorityQueue(PC, *Valley, compPc).init(gpa, valley);
    defer frontier.deinit();

    var maps = ArrayList(Map).init(gpa);
    defer maps.deinit();
    defer for (maps.items) |*m| m.deinit();

    try maps.append(try getBlizzardMap(valley.blizzards.items));

    var visited = AutoHashMap(PC, void).init(gpa);
    defer visited.deinit();

    try frontier.add(PC{ .p = start, .c = 0 });

    var best: usize = 9999;

    while (frontier.removeOrNull()) |cur| {
        var cur_cost = cur.c;

        if (maps.items.len <= cur.c + 1) {
            valley.moveBlizzards();
            try maps.append(try getBlizzardMap(valley.blizzards.items));
        }

        const dist = mDist(cur.p, valley.end());

        if (@intCast(usize, dist) + cur.c >= best) {
            continue;
        }

        if (visited.contains(cur)) {
            continue;
        }
        try visited.put(cur, {});

        const map = &maps.items[cur.c + 1];

        if (mem.eql(i16, cur.p[0..], tgt[0..])) {
            if (cur.c < best) {
                best = cur.c;
            }
        }

        const neighbors = getNeighbors(cur.p);

        for (neighbors) |np| {
            if (!valley.isReachable(map, np)) {
                continue;
            }
            var cost = cur_cost + 1;
            try frontier.add(PC{ .p = np, .c = cost });
        }
    }

    const c1 = best;

    try frontier.add(PC{ .p = tgt, .c = best });
    visited.clearAndFree();

    best = 9999;
    while (frontier.removeOrNull()) |cur| {
        var cur_cost = cur.c;

        if (maps.items.len <= cur.c + 1) {
            valley.moveBlizzards();
            try maps.append(try getBlizzardMap(valley.blizzards.items));
        }

        const dist = mDist(cur.p, start);

        if (@intCast(usize, dist) + cur.c >= best) {
            continue;
        }

        if (visited.contains(cur)) {
            continue;
        }
        try visited.put(cur, {});

        const map = &maps.items[cur.c + 1];

        if (mem.eql(i16, cur.p[0..], start[0..])) {
            if (cur.c < best) {
                best = cur.c;
            }
        }

        const neighbors = getNeighbors(cur.p);

        for (neighbors) |np| {
            if (!valley.isReachable(map, np)) {
                continue;
            }
            var cost = cur_cost + 1;
            try frontier.add(PC{ .p = np, .c = cost });
        }
    }
    const c2 = best - c1;

    try frontier.add(PC{ .p = start, .c = best });
    visited.clearAndFree();

    best = 9999;
    while (frontier.removeOrNull()) |cur| {
        var cur_cost = cur.c;

        if (maps.items.len <= cur.c + 1) {
            valley.moveBlizzards();
            try maps.append(try getBlizzardMap(valley.blizzards.items));
        }

        const dist = mDist(cur.p, tgt);

        if (@intCast(usize, dist) + cur.c >= best) {
            continue;
        }

        if (visited.contains(cur)) {
            continue;
        }
        try visited.put(cur, {});

        const map = &maps.items[cur.c + 1];

        if (mem.eql(i16, cur.p[0..], tgt[0..])) {
            if (cur.c < best) {
                best = cur.c;
            }
        }

        const neighbors = getNeighbors(cur.p);

        for (neighbors) |np| {
            if (!valley.isReachable(map, np)) {
                continue;
            }
            var cost = cur_cost + 1;
            try frontier.add(PC{ .p = np, .c = cost });
        }
    }
    const c3 = best - c2 - c1;

    return c1 + c2 + c3;
}

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

fn p1(text: Str) !usize {
    var valley = try Valley.parseMap(text);
    defer valley.deinit();

    return try ucs(&valley, .{ 1, 0 }, .{ valley.w - 2, valley.h - 1 });
}

fn p2(text: Str) !usize {
    var valley = try Valley.parseMap(text);
    defer valley.deinit();

    return try ucs2(&valley, .{ 1, 0 }, .{ valley.w - 2, valley.h - 1 });
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");

    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
