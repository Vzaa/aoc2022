const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
const math = std.math;
const Str = []const u8;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = [2]i32;
const ForestMap = AutoHashMap(Point, i32);

fn visibleDir(forest: *const ForestMap, tgt: Point, v: Point) bool {
    const height = forest.get(tgt).?;
    var cur = Point{ tgt[0] + v[0], tgt[1] + v[1] };

    while (forest.get(cur)) |h| {
        if (height <= h) {
            return false;
        }
        cur[0] += v[0];
        cur[1] += v[1];
    }

    return true;
}

fn visibleAll(forest: *const ForestMap, tgt: Point) bool {
    const dirs = [_]Point{
        .{ 0, -1 },
        .{ 0, 1 },
        .{ 1, 0 },
        .{ -1, 0 },
    };

    for (dirs) |dir| {
        if (visibleDir(forest, tgt, dir)) {
            return true;
        }
    }

    return false;
}

fn visibleDirCnt(forest: *const ForestMap, tgt: Point, v: Point) usize {
    const height = forest.get(tgt).?;
    var cur = Point{ tgt[0] + v[0], tgt[1] + v[1] };

    var cnt: usize = 0;

    while (forest.get(cur)) |h| {
        cnt += 1;
        if (height <= h) {
            break;
        }
        cur[0] += v[0];
        cur[1] += v[1];
    }

    return cnt;
}

fn visibleAllMult(forest: *const ForestMap, tgt: Point) usize {
    const dirs = [_]Point{
        .{ 0, -1 },
        .{ 0, 1 },
        .{ 1, 0 },
        .{ -1, 0 },
    };

    var cnt: usize = 1;
    for (dirs) |dir| {
        cnt *= visibleDirCnt(forest, tgt, dir);
    }

    return cnt;
}

fn parseForest(text: Str) !ForestMap {
    var line_iter = mem.tokenize(u8, text, "\n");

    var forest = ForestMap.init(gpa);

    var y: i32 = 0;
    var x: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        x = 0;
        for (line) |c| {
            const v = try std.fmt.charToDigit(c, 10);

            try forest.put(.{ x, y }, v);
            x += 1;
        }
    }

    return forest;
}

fn p1(text: Str) !usize {
    var forest = try parseForest(text);
    defer forest.deinit();

    var cnt: usize = 0;
    var key_iter = forest.keyIterator();
    while (key_iter.next()) |p| {
        if (visibleAll(&forest, p.*)) {
            cnt += 1;
        }
    }

    return cnt;
}

fn p2(text: Str) !usize {
    var forest = try parseForest(text);
    defer forest.deinit();

    var m: usize = 0;
    var key_iter = forest.keyIterator();
    while (key_iter.next()) |p| {
        m = @max(visibleAllMult(&forest, p.*), m);
    }

    return m;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    print("Part 1: {}\n", .{try p1(text)});
    print("Part 2: {}\n", .{try p2(text)});
}
