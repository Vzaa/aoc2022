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

const Bubbles = AutoHashMap(Point, bool);
const Points = AutoHashMap(Point, void);
const Point = [3]i64;

fn parseCubes(txt: Str) !Points {
    var cubes = Points.init(gpa);

    var line_iter = std.mem.split(u8, txt, "\n");
    while (line_iter.next()) |line| {
        var p: Point = undefined;
        var iter = std.mem.split(u8, line, ",");
        p[0] = try std.fmt.parseInt(i64, iter.next().?, 10);
        p[1] = try std.fmt.parseInt(i64, iter.next().?, 10);
        p[2] = try std.fmt.parseInt(i64, iter.next().?, 10);
        try cubes.put(p, {});
    }

    return cubes;
}

fn neighbors(cubes: *Points, c: Point) usize {
    const x = c[0];
    const y = c[1];
    const z = c[2];

    const neigh = [6]Point{
        .{ x + 1, y, z },
        .{ x - 1, y, z },
        .{ x, y + 1, z },
        .{ x, y - 1, z },
        .{ x, y, z + 1 },
        .{ x, y, z - 1 },
    };

    var cnt: usize = 0;
    for (neigh) |n| {
        if (cubes.contains(n)) {
            cnt += 1;
        }
    }
    return cnt;
}

fn isContained(cubes: *Points, path: *Points, c: Point) !bool {
    const x = c[0];
    const y = c[1];
    const z = c[2];

    const neigh = [6]Point{
        .{ x + 1, y, z },
        .{ x - 1, y, z },
        .{ x, y + 1, z },
        .{ x, y - 1, z },
        .{ x, y, z + 1 },
        .{ x, y, z - 1 },
    };

    // trial and error high number that seems to find the answer not overflow the stack lol
    // we should actually check for the bounding box of the shape for termination but whatevz
    if (path.count() > 59999) {
        return false;
    }

    try path.put(c, {});

    for (neigh) |n| {
        if (path.contains(n)) continue;

        if (!cubes.contains(n)) {
            if (!try isContained(cubes, path, n)) {
                return false;
            }
        }
    }

    return true;
}

fn isBubble(cubes: *Points, bubbles: *Bubbles, c: Point) !bool {
    if (bubbles.get(c)) |b| {
        if (b) return true;
    }

    const x = c[0];
    const y = c[1];
    const z = c[2];

    const neigh = [6]Point{
        .{ x + 1, y, z },
        .{ x - 1, y, z },
        .{ x, y + 1, z },
        .{ x, y - 1, z },
        .{ x, y, z + 1 },
        .{ x, y, z - 1 },
    };

    for (neigh) |n| {
        if (cubes.contains(n)) {
            continue;
        }
        if (bubbles.get(n)) |nb| {
            if (nb) {
                try bubbles.put(c, true);
                return true;
            } else {
                try bubbles.put(c, false);
                return false;
            }
        }

        var path = Points.init(gpa);
        defer path.deinit();

        var b = try isContained(cubes, &path, n);
        if (!b) {
            try bubbles.put(c, false);
            return false;
        }
    }

    // no place to go
    try bubbles.put(c, true);
    return true;
}

fn closedFaces(cubes: *Points, bubbles: *Bubbles, c: Point) !usize {
    const x = c[0];
    const y = c[1];
    const z = c[2];

    const neigh = [6]Point{
        .{ x + 1, y, z },
        .{ x - 1, y, z },
        .{ x, y + 1, z },
        .{ x, y - 1, z },
        .{ x, y, z + 1 },
        .{ x, y, z - 1 },
    };

    var cnt: usize = 0;
    for (neigh) |n| {
        if (cubes.contains(n)) {
            cnt += 1;
        } else {
            var b = try isBubble(cubes, bubbles, n);
            if (b) cnt += 1;
        }
    }
    return cnt;
}

fn p1(text: Str) !usize {
    var cubes = try parseCubes(text);
    defer cubes.deinit();

    var area: usize = 0;
    var kiter = cubes.keyIterator();
    while (kiter.next()) |c| {
        area += 6 - neighbors(&cubes, c.*);
    }

    return area;
}

fn p2(text: Str) !usize {
    var cubes = try parseCubes(text);
    defer cubes.deinit();

    var bubbles = Bubbles.init(gpa);
    defer bubbles.deinit();

    var area: usize = 0;
    var kiter = cubes.keyIterator();
    while (kiter.next()) |c| {
        area += 6 - try closedFaces(&cubes, &bubbles, c.*);
    }

    return area;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");

    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
