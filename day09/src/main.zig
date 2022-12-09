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

const Vec2 = [2]i32;
const Moves = ArrayList(Move);

const Move = struct { cnt: usize, dir: Vec2 };

fn parseMoves(text: Str) !Moves {
    const dirs = [_]Vec2{
        .{ 0, -1 }, // L
        .{ 0, 1 }, // R
        .{ 1, 0 }, // U
        .{ -1, 0 }, // D
    };
    var line_iter = mem.tokenize(u8, text, "\n");

    var moves = Moves.init(gpa);

    while (line_iter.next()) |line| {
        var splitter = mem.split(u8, line, " ");

        const dir_str = splitter.next().?;
        const dir = switch (dir_str[0]) {
            'L' => dirs[0],
            'R' => dirs[1],
            'U' => dirs[2],
            'D' => dirs[3],
            else => unreachable,
        };
        const cnt = try std.fmt.parseInt(usize, splitter.next().?, 10);

        try moves.append(Move{ .cnt = cnt, .dir = dir });
    }

    return moves;
}

fn add(a: Vec2, b: Vec2) Vec2 {
    return Vec2{ a[0] + b[0], a[1] + b[1] };
}

fn sub(a: Vec2, b: Vec2) Vec2 {
    return Vec2{ a[0] - b[0], a[1] - b[1] };
}

// yolo version
fn abs(v: i32) i32 {
    return std.math.absInt(v) catch 0;
}

fn moveTail(tail: Vec2, head: Vec2) Vec2 {
    const dif = sub(head, tail);

    if (abs(dif[1]) == 1 and abs(dif[0]) == 1) {
        return tail;
    } else if (abs(dif[0]) + abs(dif[1]) >= 2) {
        var x = if (dif[0] == 0) 0 else @divTrunc(dif[0], abs(dif[0]));
        var y = if (dif[1] == 0) 0 else @divTrunc(dif[1], abs(dif[1]));
        return add(tail, Vec2{ x, y });
    } else {
        return tail;
    }
}

fn p1(text: Str) !usize {
    var moves = try parseMoves(text);
    defer moves.deinit();

    var tail_past = AutoHashMap(Vec2, void).init(gpa);
    defer tail_past.deinit();

    var head = Vec2{ 0, 0 };
    var tail = Vec2{ 0, 0 };

    for (moves.items) |move| {
        var c: usize = 0;
        while (c < move.cnt) : (c += 1) {
            head = add(head, move.dir);
            tail = moveTail(tail, head);
            try tail_past.put(tail, {});
        }
    }

    return tail_past.count();
}

fn p2(text: Str) !usize {
    var moves = try parseMoves(text);
    defer moves.deinit();

    var tail_past = AutoHashMap(Vec2, void).init(gpa);
    defer tail_past.deinit();

    // there's probably a better way to init
    var knots = [_]Vec2{ Vec2{ 0, 0 }, Vec2{ 0, 0 }, Vec2{ 0, 0 }, Vec2{ 0, 0 }, Vec2{ 0, 0 }, Vec2{ 0, 0 }, Vec2{ 0, 0 }, Vec2{ 0, 0 }, Vec2{ 0, 0 }, Vec2{ 0, 0 } };

    for (moves.items) |move| {
        var c: usize = 0;
        while (c < move.cnt) : (c += 1) {
            knots[0] = add(knots[0], move.dir);
            var i: usize = 1;
            while (i < knots.len) : (i += 1) {
                knots[i] = moveTail(knots[i], knots[i - 1]);
            }
            try tail_past.put(knots[9], {});
        }
    }

    return tail_past.count();
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    print("Part 1: {}\n", .{try p1(text)});
    print("Part 2: {}\n", .{try p2(text)});
}
