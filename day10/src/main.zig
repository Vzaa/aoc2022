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

const Op = union(enum) {
    Add: i32,
    Noop,

    fn parse(t: Str) !Op {
        var iter = mem.split(u8, t, " ");
        const name = iter.next().?;

        if (mem.eql(u8, name, "noop")) {
            return Op.Noop;
        } else if (mem.eql(u8, name, "addx")) {
            const val = try std.fmt.parseInt(i32, iter.next().?, 10);
            return Op{ .Add = val };
        } else {
            unreachable;
        }
    }
};

const Tick = struct {
    clk: i32,
    x: i32,
};

fn parseSim(text: Str) !ArrayList(Tick) {
    var line_iter = mem.tokenize(u8, text, "\n");
    var ops = ArrayList(Op).init(gpa);
    defer ops.deinit();

    var ticks = ArrayList(Tick).init(gpa);

    while (line_iter.next()) |line| {
        const o = try Op.parse(line);
        try ops.append(o);
    }

    var x: i32 = 1;
    var clk: i32 = 0;

    for (ops.items) |o| {
        switch (o) {
            Op.Noop => {
                clk += 1;
                try ticks.append(Tick{ .clk = clk, .x = x });
            },
            Op.Add => |*v| {
                var cnt: i32 = 0;

                while (cnt < 1) : (cnt += 1) {
                    clk += 1;
                    try ticks.append(Tick{ .clk = clk, .x = x });
                }

                clk += 1;
                try ticks.append(Tick{ .clk = clk, .x = x });
                x += v.*;
            },
        }
    }
    clk += 1;
    try ticks.append(Tick{ .clk = clk, .x = x });

    return ticks;
}

fn p1(text: Str) !i32 {
    var ticks = try parseSim(text);
    defer ticks.deinit();

    var tgt = [_]usize{ 20, 60, 100, 140, 180, 220 };

    var sum: i32 = 0;
    for (tgt) |t| {
        const tick = &ticks.items[t - 1];
        sum += (tick.clk * tick.x);
    }

    return sum;
}

fn p2(text: Str) !void {
    var ticks = try parseSim(text);
    defer ticks.deinit();

    print("Part 2:\n", .{});

    var y: usize = 0;
    var clk: usize = 0;
    while (y < 6) : (y += 1) {
        var x: usize = 0;
        while (x < 40) : (x += 1) {
            const tick = &ticks.items[clk];
            const lit = x >= tick.x - 1 and x <= tick.x + 1;
            const c: u8 = if (lit) '#' else '.';
            print("{c}", .{c});
            clk += 1;
        }
        print("\n", .{});
    }
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    print("Part 1: {}\n", .{try p1(text)});
    try p2(text);
}
