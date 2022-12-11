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

const Monke = struct {
    items: ArrayList(i64),
    test_div: i64,
    op: Op,
    monke_true: usize,
    monke_false: usize,
    inspect: usize,

    fn deinit(self: *Monke) void {
        self.items.deinit();
    }

    fn parse(txt: Str) !Monke {
        var monke: Monke = undefined;
        monke.items = ArrayList(i64).init(gpa);
        monke.inspect = 0;

        var line_iter = mem.split(u8, txt, "\n");
        _ = line_iter.next().?;
        const item_line = line_iter.next().?;

        var item_iter = mem.tokenize(u8, item_line[17..], " ,");
        while (item_iter.next()) |item| {
            try monke.items.append(try std.fmt.parseInt(i64, item, 10));
        }

        const op_line = line_iter.next().?;
        monke.op = try Op.parse(op_line);

        const div_line = line_iter.next().?;
        var iter = mem.tokenize(u8, div_line, " ");
        _ = iter.next().?;
        _ = iter.next().?;
        _ = iter.next().?;
        monke.test_div = try std.fmt.parseInt(i64, iter.next().?, 10);

        const t_line = line_iter.next().?;
        iter = mem.tokenize(u8, t_line, " ");
        _ = iter.next().?;
        _ = iter.next().?;
        _ = iter.next().?;
        _ = iter.next().?;
        _ = iter.next().?;
        monke.monke_true = try std.fmt.parseInt(usize, iter.next().?, 10);

        const f_line = line_iter.next().?;
        iter = mem.tokenize(u8, f_line, " ");
        _ = iter.next().?;
        _ = iter.next().?;
        _ = iter.next().?;
        _ = iter.next().?;
        _ = iter.next().?;
        monke.monke_false = try std.fmt.parseInt(usize, iter.next().?, 10);

        // return to monke
        return monke;
    }

    fn round(self: *Monke, monkes: []Monke) !void {
        while (self.items.popOrNull()) |cval| {
            self.inspect += 1;
            var item = cval;
            item = self.op.apply(item);
            item = @divFloor(item, 3);
            if (@rem(item, self.test_div) == 0) {
                try monkes[self.monke_true].items.append(item);
            } else {
                try monkes[self.monke_false].items.append(item);
            }
        }
    }

    fn round2(self: *Monke, monkes: []Monke, lcm: i64) !void {
        while (self.items.popOrNull()) |cval| {
            self.inspect += 1;
            var item = cval;
            item = self.op.apply(item);
            item = @rem(item, lcm);
            if (@rem(item, self.test_div) == 0) {
                try monkes[self.monke_true].items.append(item);
            } else {
                try monkes[self.monke_false].items.append(item);
            }
        }
    }
};

const Op = union(enum) {
    Add: i64,
    Mul: i64,
    Sq,

    fn parse(t: Str) !Op {
        var iter = mem.split(u8, t, " = ");
        _ = iter.next().?;
        const oper = iter.next().?;

        if (mem.eql(u8, oper, "old * old")) {
            return Op.Sq;
        } else if (oper[4] == '+') {
            const val = try std.fmt.parseInt(i64, oper[6..], 10);
            return Op{ .Add = val };
        } else if (oper[4] == '*') {
            const val = try std.fmt.parseInt(i64, oper[6..], 10);
            return Op{ .Mul = val };
        } else {
            unreachable;
        }
    }

    fn apply(self: *Op, val: i64) i64 {
        switch (self.*) {
            Op.Sq => {
                return val * val;
            },
            Op.Add => |*v| {
                return v.* + val;
            },
            Op.Mul => |*v| {
                return v.* * val;
            },
        }
    }
};

fn parseMonkes(text: Str) !ArrayList(Monke) {
    var monkes = ArrayList(Monke).init(gpa);

    var monke_iter = mem.split(u8, text, "\n\n");
    while (monke_iter.next()) |monke_str| {
        try monkes.append(try Monke.parse(monke_str));
    }

    return monkes;
}

fn monkeInspectCmp(_: void, a: Monke, b: Monke) bool {
    return a.inspect > b.inspect;
}

fn p1(text: Str) !usize {
    var monkes = try parseMonkes(text);
    defer monkes.deinit();
    defer for (monkes.items) |*m| m.deinit();

    var round: usize = 0;

    while (round < 20) : (round += 1) {
        for (monkes.items) |*monke| {
            try monke.round(monkes.items);
        }
    }

    std.sort.sort(Monke, monkes.items, {}, monkeInspectCmp);

    return monkes.items[0].inspect * monkes.items[1].inspect;
}

fn p2(text: Str) !usize {
    var monkes = try parseMonkes(text);
    defer monkes.deinit();
    defer for (monkes.items) |*m| m.deinit();

    var round: usize = 0;

    var lcm: i64 = 1;
    for (monkes.items) |*monke| {
        lcm *= monke.test_div;
    }

    while (round < 10000) : (round += 1) {
        for (monkes.items) |*monke| {
            try monke.round2(monkes.items, lcm);
        }
    }

    std.sort.sort(Monke, monkes.items, {}, monkeInspectCmp);

    return monkes.items[0].inspect * monkes.items[1].inspect;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
