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
const Map = AutoHashMap(Point, Tile);

const Tile = enum { Wall, Sand };

fn drawLine(map: *Map, a: Point, b: Point) !void {
    if (a[0] == b[0]) {
        var y = @min(a[1], b[1]);
        while (y <= @max(a[1], b[1])) : (y += 1) {
            try map.put(Point{ a[0], y }, Tile.Wall);
        }
    } else if (a[1] == b[1]) {
        var x = @min(a[0], b[0]);
        while (x <= @max(a[0], b[0])) : (x += 1) {
            try map.put(Point{ x, a[1] }, Tile.Wall);
        }
    } else {
        unreachable;
    }
}

fn parseLines(map: *Map, line: Str) !void {
    var point_iter = mem.split(u8, line, " -> ");

    var last_point: ?Point = null;

    while (point_iter.next()) |pstr| {
        var cor_iter = mem.split(u8, pstr, ",");
        var point: Point = undefined;
        point[0] = try std.fmt.parseInt(i32, cor_iter.next().?, 10);
        point[1] = try std.fmt.parseInt(i32, cor_iter.next().?, 10);

        if (last_point) |lp| {
            try drawLine(map, lp, point);
        }

        last_point = point;
    }
}

fn parse(text: Str) !Map {
    var map = Map.init(gpa);
    var line_iter = mem.split(u8, text, "\n");

    while (line_iter.next()) |line| {
        try parseLines(&map, line);
    }

    return map;
}

fn dropSand(map: *Map, maxy: i32) !bool {
    var point = Point{ 500, 0 };

    while (point[1] <= maxy) {
        var down = Point{ point[0], point[1] + 1 };
        var leftd = Point{ point[0] - 1, point[1] + 1 };
        var rightd = Point{ point[0] + 1, point[1] + 1 };

        if (!map.contains(down)) {
            point = down;
        } else if (!map.contains(leftd)) {
            point = leftd;
        } else if (!map.contains(rightd)) {
            point = rightd;
        } else {
            try map.put(point, Tile.Sand);
            return true;
        }
    }

    return false;
}

fn dropSand2(map: *Map, maxy: i32) !bool {
    var point = Point{ 500, 0 };

    while (true) {
        var down = Point{ point[0], point[1] + 1 };
        var leftd = Point{ point[0] - 1, point[1] + 1 };
        var rightd = Point{ point[0] + 1, point[1] + 1 };

        if (point[1] == maxy - 1) {
            try map.put(point, Tile.Sand);
            return true;
        } else if (!map.contains(down)) {
            point = down;
        } else if (!map.contains(leftd)) {
            point = leftd;
        } else if (!map.contains(rightd)) {
            point = rightd;
        } else {
            try map.put(point, Tile.Sand);
            return point[1] != 0;
        }
    }
    unreachable;
}

fn p1(text: Str) !usize {
    var map = try parse(text);
    defer map.deinit();

    var maxy: i32 = 0;

    var kiter = map.keyIterator();
    while (kiter.next()) |k| {
        maxy = @max(k[1], maxy);
    }

    while (try dropSand(&map, maxy)) {}

    var cnt: usize = 0;
    var viter = map.valueIterator();
    while (viter.next()) |k| {
        if (k.* == Tile.Sand) {
            cnt += 1;
        }
    }

    return cnt;
}

fn p2(text: Str) !usize {
    var map = try parse(text);
    defer map.deinit();

    var maxy: i32 = 0;

    var kiter = map.keyIterator();
    while (kiter.next()) |k| {
        maxy = @max(k[1], maxy);
    }

    while (try dropSand2(&map, maxy + 2)) {}

    var cnt: usize = 0;
    var viter = map.valueIterator();
    while (viter.next()) |k| {
        if (k.* == Tile.Sand) {
            cnt += 1;
        }
    }

    return cnt;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
