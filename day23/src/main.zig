const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
const math = std.math;
const Str = []const u8;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = [2]i32;
const Map = AutoHashMap(Point, i32);

fn parseMap(text: Str) !Map {
    var map = Map.init(gpa);

    var line_iter = mem.split(u8, text, "\n");

    var y: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        var x: i32 = 0;
        for (line) |c| {
            if (c == '#') {
                try map.put(.{ x, y }, 1);
            }
            x += 1;
        }
    }
    return map;
}

const AllCheck = [_]Point{
    .{ -1, -1 },
    .{ -1, 0 },
    .{ -1, 1 },
    .{ 0, -1 },
    .{ 0, 1 },
    .{ 1, -1 },
    .{ 1, 0 },
    .{ 1, 1 },
};

const NCheck = [_]Point{
    .{ -1, -1 },
    .{ 0, -1 },
    .{ 1, -1 },
};

const SCheck = [_]Point{
    .{ -1, 1 },
    .{ 0, 1 },
    .{ 1, 1 },
};

const WCheck = [_]Point{
    .{ -1, -1 },
    .{ -1, 0 },
    .{ -1, 1 },
};

const ECheck = [_]Point{
    .{ 1, -1 },
    .{ 1, 0 },
    .{ 1, 1 },
};

const Check = [_][3]Point{
    NCheck,
    SCheck,
    WCheck,
    ECheck,
};

const Dirs = [_]Point{
    .{ 0, -1 },
    .{ 0, 1 },
    .{ -1, 0 },
    .{ 1, 0 },
};

fn propose(map: *Map, turn: usize, p: Point) Point {
    var c: usize = 0;
    var empty = true;

    for (AllCheck) |d| {
        const np = add(d, p);
        if (map.contains(np)) {
            empty = false;
            break;
        }
    }

    if (empty) return p;

    outer: while (c < 4) : (c += 1) {
        const check = Check[(turn + c) % Check.len];
        for (check) |v| {
            const np = add(v, p);
            if (map.contains(np)) continue :outer;
        }
        const proposed = add(Dirs[(turn + c) % Dirs.len], p);
        return proposed;
    }

    return p;
}

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

fn paint(map: *Map) void {
    var minx: i32 = std.math.maxInt(i32);
    var miny: i32 = std.math.maxInt(i32);
    var maxx: i32 = std.math.minInt(i32);
    var maxy: i32 = std.math.minInt(i32);

    var kiter = map.keyIterator();
    while (kiter.next()) |elf| {
        minx = @min(minx, elf[0]);
        miny = @min(miny, elf[1]);
        maxx = @max(maxx, elf[0]);
        maxy = @max(maxy, elf[1]);
    }

    var y: i32 = miny;
    while (y <= maxy) : (y += 1) {
        var x: i32 = minx;
        while (x <= maxx) : (x += 1) {
            if (map.contains(.{ x, y })) {
                print("#", .{});
            } else {
                print(".", .{});
            }
        }
        print("\n", .{});
    }
}

fn p1(text: Str) !i32 {
    var map = try parseMap(text);
    defer map.deinit();

    var turn: usize = 0;

    while (turn < 10) : (turn += 1) {
        var proposed = Map.init(gpa);
        defer proposed.deinit();

        var kiter = map.keyIterator();
        while (kiter.next()) |elf| {
            var p = propose(&map, turn, elf.*);

            var tgt = try proposed.getOrPut(p);
            if (tgt.found_existing) {
                tgt.value_ptr.* += 1;
            } else {
                tgt.value_ptr.* = 1;
            }
        }

        var next = Map.init(gpa);

        kiter = map.keyIterator();
        while (kiter.next()) |elf| {
            var p = propose(&map, turn, elf.*);
            var cnt = proposed.get(p).?;

            if (cnt == 1) {
                try next.put(p, 1);
            } else {
                try next.put(elf.*, 1);
            }
        }
        map.deinit();
        map = next;
    }

    var minx: i32 = std.math.maxInt(i32);
    var miny: i32 = std.math.maxInt(i32);
    var maxx: i32 = std.math.minInt(i32);
    var maxy: i32 = std.math.minInt(i32);

    var kiter = map.keyIterator();
    while (kiter.next()) |elf| {
        minx = @min(minx, elf[0]);
        miny = @min(miny, elf[1]);
        maxx = @max(maxx, elf[0]);
        maxy = @max(maxy, elf[1]);
    }

    var area = (maxy - miny + 1) * (maxx - minx + 1);

    return area - @intCast(i32, map.count());
}

fn p2(text: Str) !usize {
    var map = try parseMap(text);
    defer map.deinit();

    var turn: usize = 0;

    while (true) : (turn += 1) {
        var proposed = Map.init(gpa);
        defer proposed.deinit();
        var moves: usize = 0;

        var kiter = map.keyIterator();
        while (kiter.next()) |elf| {
            var p = propose(&map, turn, elf.*);

            var tgt = try proposed.getOrPut(p);
            if (tgt.found_existing) {
                tgt.value_ptr.* += 1;
            } else {
                tgt.value_ptr.* = 1;
            }
        }

        var next = Map.init(gpa);

        kiter = map.keyIterator();
        while (kiter.next()) |elf| {
            var p = propose(&map, turn, elf.*);
            var cnt = proposed.get(p).?;

            if (cnt == 1) {
                if (elf[0] != p[0] or elf[1] != p[1]) {
                    moves += 1;
                }
                try next.put(p, 1);
            } else {
                try next.put(elf.*, 1);
            }
        }
        map.deinit();
        map = next;

        if (moves == 0) break;
    }

    return turn + 1;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");

    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
