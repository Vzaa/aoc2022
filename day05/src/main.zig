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

fn boxFromStr(t: Str) ?u8 {
    if (t[0] == '[') {
        return t[1];
    } else {
        return null;
    }
}

const Order = struct {
    from: usize,
    to: usize,
    cnt: usize,

    fn fromStr(t: Str) !Order {
        var iter = mem.split(u8, t, " ");
        var ret: Order = undefined;
        _ = iter.next().?;
        ret.cnt = try std.fmt.parseInt(usize, iter.next().?, 10);
        _ = iter.next().?;
        ret.from = try std.fmt.parseInt(usize, iter.next().?, 10) - 1;
        _ = iter.next().?;
        ret.to = try std.fmt.parseInt(usize, iter.next().?, 10) - 1;
        return ret;
    }
};

fn p1(text: Str) !void {
    var list = ArrayList(ArrayList(u8)).init(gpa);
    defer list.deinit();
    defer for (list.items) |l| l.deinit();

    var tmp = mem.split(u8, text, "\n");
    var stacks = (tmp.next().?.len + 1) / 4;

    var i: usize = 0;
    while (i < stacks) : (i += 1) try list.append(ArrayList(u8).init(gpa));

    var line_iter = mem.split(u8, text, "\n");
    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var idx: usize = 0;
        while (idx < stacks) : (idx += 1) {
            const start = idx * 4;
            const sl = line[start..(start + 3)];
            const box = boxFromStr(sl);
            if (box != null) {
                try list.items[idx].append(box.?);
            }
        }
    }

    for (list.items) |l| mem.reverse(u8, l.items);

    while (line_iter.next()) |line| {
        const o = try Order.fromStr(line);
        var act: usize = 0;
        while (act < o.cnt) : (act += 1) {
            const b = list.items[o.from].popOrNull().?;
            try list.items[o.to].append(b);
        }
    }

    print("Part 1: ", .{});
    for (list.items) |*l| {
        const b = l.popOrNull().?;
        print("{c}", .{b});
    }
    print("\n", .{});
}

fn p2(text: Str) !void {
    var list = ArrayList(ArrayList(u8)).init(gpa);
    defer list.deinit();
    defer for (list.items) |l| l.deinit();

    var tmp = mem.split(u8, text, "\n");
    var stacks = (tmp.next().?.len + 1) / 4;

    var i: usize = 0;
    while (i < stacks) : (i += 1) try list.append(ArrayList(u8).init(gpa));

    var line_iter = mem.split(u8, text, "\n");
    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var idx: usize = 0;
        while (idx < stacks) : (idx += 1) {
            const start = idx * 4;
            const sl = line[start..(start + 3)];
            const box = boxFromStr(sl);
            if (box != null) {
                try list.items[idx].append(box.?);
            }
        }
    }

    for (list.items) |l| mem.reverse(u8, l.items);

    while (line_iter.next()) |line| {
        const o = try Order.fromStr(line);
        var act: usize = 0;
        while (act < o.cnt) : (act += 1) {
            const b = list.items[o.from].popOrNull().?;
            try list.items[o.to].append(b);
        }
        // Reverse what was pushed
        const l = list.items[o.to].items.len;
        mem.reverse(u8, list.items[o.to].items[(l - o.cnt)..l]);
    }

    print("Part 2: ", .{});
    for (list.items) |*l| {
        const b = l.popOrNull().?;
        print("{c}", .{b});
    }
    print("\n", .{});
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    try p1(trimmed);
    try p2(trimmed);
}
