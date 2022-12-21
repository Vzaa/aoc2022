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

const Names = [2]Str;
const Monkes = StringHashMap(Monke);

const Monke = struct {
    name: Str,
    op: Op,

    fn deinit(self: *Monke) void {
        self.items.deinit();
    }

    fn parse(txt: Str) !Monke {
        var monke: Monke = undefined;
        var iter = mem.split(u8, txt, " ");
        var iter2 = mem.tokenize(u8, iter.next().?, ":");
        monke.name = iter2.next().?;
        monke.op = try Op.parse(txt);

        // return to monke
        return monke;
    }
};

const Op = union(enum) {
    Add: Names,
    Mul: Names,
    Div: Names,
    Sub: Names,
    Num: i64,

    fn parse(t: Str) !Op {
        var cnt = mem.count(u8, t, " ");
        var iter = mem.split(u8, t, " ");
        _ = iter.next().?;

        if (cnt == 1) {
            const val = try std.fmt.parseInt(i64, iter.next().?, 10);
            return Op{ .Num = val };
        } else {
            const monke_a = iter.next().?;
            const op = iter.next().?;
            const monke_b = iter.next().?;

            switch (op[0]) {
                '+' => return Op{ .Add = .{ monke_a, monke_b } },
                '-' => return Op{ .Sub = .{ monke_a, monke_b } },
                '*' => return Op{ .Mul = .{ monke_a, monke_b } },
                '/' => return Op{ .Div = .{ monke_a, monke_b } },
                else => unreachable,
            }
        }
    }
};

fn parseMonkes(text: Str) !Monkes {
    var monkes = StringHashMap(Monke).init(gpa);

    var monke_iter = mem.split(u8, text, "\n");
    while (monke_iter.next()) |monke_str| {
        var monke = try Monke.parse(monke_str);
        try monkes.put(monke.name, monke);
    }

    return monkes;
}

fn solve(monkes: *Monkes, name: Str, humn: ?i64) !i64 {
    const part2 = if (humn) |_| true else false;
    const monke = monkes.get(name).?;

    if (part2) {
        if (mem.eql(u8, name, "humn")) {
            return humn.?;
        }

        if (mem.eql(u8, "root", monke.name)) {
            switch (monke.op) {
                Op.Add, Op.Sub, Op.Div, Op.Mul => |*n| {
                    const a = try solve(monkes, n[0], humn);
                    const b = try solve(monkes, n[1], humn);
                    return if (a == b) 1 else 0;
                },
                else => unreachable,
            }
        }
    }

    switch (monke.op) {
        Op.Num => |*n| {
            return n.*;
        },
        Op.Add => |*n| {
            return try solve(monkes, n[0], humn) + try solve(monkes, n[1], humn);
        },
        Op.Sub => |*n| {
            return try solve(monkes, n[0], humn) - try solve(monkes, n[1], humn);
        },
        Op.Mul => |*n| {
            return try solve(monkes, n[0], humn) * try solve(monkes, n[1], humn);
        },
        Op.Div => |*n| {
            return @divFloor(try solve(monkes, n[0], humn), try solve(monkes, n[1], humn));
        },
    }
}

fn p1(text: Str) !i64 {
    var monkes = try parseMonkes(text);
    defer monkes.deinit();

    return try solve(&monkes, "root", null);
}

fn p2(text: Str) !i64 {
    var monkes = try parseMonkes(text);
    defer monkes.deinit();

    // manual binary search lol
    var x: i64 = 3555057450000;
    while (true) : (x += 1) {
        if (try solve(&monkes, "root", x) == 1) {
            return x;
        }
    }

    return 0;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
