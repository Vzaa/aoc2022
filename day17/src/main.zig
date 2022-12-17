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

const Points = AutoHashMap(Point, void);

const Point = [2]i64;

const Shape = struct {
    points: Points,
    height: i64,
    width: i64,

    fn parse(txt: Str) !Shape {
        const height = mem.count(u8, txt, "\n") + 1;
        var points = Points.init(gpa);

        var line_iter = mem.split(u8, txt, "\n");
        var width: i64 = 0;

        var y: i64 = @intCast(i64, height - 1);
        while (y >= 0) : (y -= 1) {
            const line = line_iter.next().?;
            for (line) |c, x| {
                if (c == '#') {
                    width = @max(width, @intCast(i64, x) + 1);
                    try points.put(Point{ @intCast(i64, x), @intCast(i64, y) }, {});
                }
            }
        }

        return Shape{ .points = points, .height = @intCast(i64, height), .width = width };
    }

    fn isFreePos(self: *Shape, map: *Points, p: Point) bool {
        if (self.width + p[0] > 7) return false;
        if (p[0] < 0) return false;
        if (p[1] < 0) return false;

        var kiter = self.points.keyIterator();
        while (kiter.next()) |k| {
            var pos = add(k.*, p);
            if (map.contains(pos)) return false;
        }
        return true;
    }

    fn paint(self: *Shape, map: *Points, p: Point) !void {
        var kiter = self.points.keyIterator();
        while (kiter.next()) |k| {
            var pos = add(k.*, p);
            try map.put(pos, {});
        }
    }

    fn deinit(self: *Shape) void {
        self.points.deinit();
    }
};

fn parseShapes() !ArrayList(Shape) {
    const text = @embedFile("shapes");
    const trimmed = std.mem.trim(u8, text, "\n");

    var list = ArrayList(Shape).init(gpa);
    var shape_iter = std.mem.split(u8, trimmed, "\n\n");

    while (shape_iter.next()) |txt| {
        const s = try Shape.parse(txt);
        try list.append(s);
    }

    return list;
}

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

fn p1(text: Str) !i64 {
    const shapes = try parseShapes();
    defer shapes.deinit();
    defer for (shapes.items) |*s| s.deinit();

    var map = Points.init(gpa);
    defer map.deinit();

    var jet_idx: usize = 0;
    var cnt: usize = 0;
    var top: i64 = 0;

    while (cnt < 2022) : (cnt += 1) {
        var shape = shapes.items[cnt % shapes.items.len];
        var pos = Point{ 2, top + 3 };

        while (true) {
            const jet = if (text[jet_idx % text.len] == '>') Point{ 1, 0 } else Point{ -1, 0 };
            jet_idx += 1;

            const jet_pos = add(pos, jet);
            if (shape.isFreePos(&map, jet_pos)) {
                pos = jet_pos;
            }

            const fall_pos = add(pos, Point{ 0, -1 });
            if (shape.isFreePos(&map, fall_pos)) {
                pos = fall_pos;
            } else {
                try shape.paint(&map, pos);
                top = 0;
                var kiter = map.keyIterator();
                while (kiter.next()) |k| {
                    top = @max(k[1], top);
                }
                top += 1;
                break;
            }
        }
    }

    var kiter = map.keyIterator();
    while (kiter.next()) |k| {
        top = @max(k[1], top);
    }

    return top;
}

fn paint(map: *Points) void {
    var top: i64 = 0;
    var kiter = map.keyIterator();
    while (kiter.next()) |k| {
        top = @max(k[1], top);
    }

    var y = top;
    while (y >= 0) : (y -= 1) {
        var x: i64 = 0;
        while (x < 7) : (x += 1) {
            if (map.contains(Point{ x, y })) {
                print("#", .{});
            } else {
                print(".", .{});
            }
        }
        print("\n", .{});
    }
}

fn p2(text: Str) !i64 {
    const shapes = try parseShapes();
    defer shapes.deinit();
    defer for (shapes.items) |*s| s.deinit();

    var map = Points.init(gpa);
    defer map.deinit();

    var jet_idx: usize = 0;
    var cnt: usize = 0;
    var last_top: i64 = 0;
    var top: i64 = 0;

    const lim: usize = 1000000000000;

    var list = ArrayList(i64).init(gpa);
    defer list.deinit();

    while (cnt < 5000) : (cnt += 1) {
        var shape = shapes.items[cnt % shapes.items.len];
        var pos = Point{ 2, top + 3 };
        try list.append(top - last_top);
        last_top = top;

        while (true) {
            const jet = if (text[jet_idx % text.len] == '>') Point{ 1, 0 } else Point{ -1, 0 };
            jet_idx += 1;

            const jet_pos = add(pos, jet);
            if (shape.isFreePos(&map, jet_pos)) {
                pos = jet_pos;
            }

            const fall_pos = add(pos, Point{ 0, -1 });
            if (shape.isFreePos(&map, fall_pos)) {
                pos = fall_pos;
            } else {
                try shape.paint(&map, pos);
                top = 0;
                var kiter = map.keyIterator();
                while (kiter.next()) |k| {
                    top = @max(k[1], top);
                }
                top += 1;
                break;
            }
        }
    }

    var pattern: []i64 = undefined;
    var found = false;
    {
        const l = list.items.len;
        var s: usize = l;

        while (s > 10) : (s -= 1) {
            const start = l - s;
            const sl = list.items[start..];
            const c = mem.count(i64, list.items, sl);

            if (c > 1) {
                var first = mem.indexOfPosLinear(i64, list.items, 0, sl).?;
                var second = mem.indexOfPosLinear(i64, list.items, first + 1, sl).?;
                if (second - first == sl.len) {
                    pattern = sl;
                    found = true;
                    break;
                }
            }
        }
    }

    assert(found);

    var sum: i64 = 0;
    for (pattern) |v| {
        sum += v;
    }

    var cursor: usize = 0;
    while (cnt < lim) {
        if (lim - cnt > pattern.len) {
            cnt += pattern.len;
            top += sum;
        } else {
            var next = pattern[cursor % pattern.len];
            cnt += 1;
            top += next;
            cursor += 1;
        }
    }

    return top;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");

    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
