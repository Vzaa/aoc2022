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

const Point = [2]i64;

// yolo abs
fn abs(a: i64) i64 {
    return std.math.absInt(a) catch 0;
}

const Sensor = struct {
    pos: Point,
    closest: Point,
    range: i64,

    fn parse(text: Str) !Sensor {
        var s: Sensor = undefined;
        var iter = mem.split(u8, text, " ");
        _ = iter.next().?;
        _ = iter.next().?;
        var x_str = mem.tokenize(u8, iter.next().?, "xy=,:");
        var y_str = mem.tokenize(u8, iter.next().?, "xy=,:");
        _ = iter.next().?;
        _ = iter.next().?;
        _ = iter.next().?;
        _ = iter.next().?;
        var xc_str = mem.tokenize(u8, iter.next().?, "xy=,:");
        var yc_str = mem.tokenize(u8, iter.next().?, "xy=,:");

        s.pos[0] = try std.fmt.parseInt(i64, x_str.next().?, 10);
        s.pos[1] = try std.fmt.parseInt(i64, y_str.next().?, 10);
        s.closest[0] = try std.fmt.parseInt(i64, xc_str.next().?, 10);
        s.closest[1] = try std.fmt.parseInt(i64, yc_str.next().?, 10);
        s.range = mDist(s.pos, s.closest);

        return s;
    }

    fn inRange(self: *Sensor, p: Point) bool {
        const d = mDist(self.pos, p);
        return d <= self.range;
    }
};

fn mDist(a: Point, b: Point) i64 {
    const x = abs(a[0] - b[0]);
    const y = abs(a[1] - b[1]);
    return x + y;
}

fn p1(text: Str) !usize {
    var line_iter = mem.split(u8, text, "\n");
    var list = ArrayList(Sensor).init(gpa);
    defer list.deinit();

    var bpos = AutoHashMap(Point, void).init(gpa);
    defer bpos.deinit();

    var max_range: i64 = 0;
    var min_x: i64 = std.math.maxInt(i64);
    var max_x: i64 = std.math.minInt(i64);
    while (line_iter.next()) |line| {
        const s = try Sensor.parse(line);
        try list.append(s);
        try bpos.put(s.closest, {});
        max_range = @max(max_range, s.range);
        min_x = @min(min_x, s.pos[0]);
        max_x = @max(max_x, s.pos[0]);
    }

    var set = AutoHashMap(Point, void).init(gpa);
    defer set.deinit();

    const y_tgt: i64 = 2000000;

    for (list.items) |*s| {
        var x = min_x - max_range - 1;
        while (x <= max_x + max_range + 1) : (x += 1) {
            const c = Point{ x, y_tgt };
            if (s.inRange(c) and !bpos.contains(c)) {
                try set.put(c, {});
            }
        }
    }

    return set.count();
}

fn p2(text: Str) !i64 {
    var line_iter = mem.split(u8, text, "\n");
    var list = ArrayList(Sensor).init(gpa);
    defer list.deinit();

    while (line_iter.next()) |line| {
        const s = try Sensor.parse(line);
        try list.append(s);
    }

    const lim: i64 = 4000000;

    var y: i64 = 0;
    while (y <= lim) : (y += 1) {
        var x: i64 = 0;
        outer: while (x <= lim) : (x += 1) {
            const c = Point{ x, y };
            for (list.items) |*s| {
                if (s.inRange(c)) {
                    const ydist = abs(y - s.pos[1]);
                    x = s.pos[0] + (s.range - ydist);
                    continue :outer;
                }
            }

            return (x * 4000000) + y;
        }
    }
    unreachable;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
