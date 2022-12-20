const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const TailQueue = std.TailQueue;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
const math = std.math;
const Str = []const u8;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const TQ = TailQueue(i64);

fn parse(txt: Str) !ArrayList(TQ.Node) {
    var list = ArrayList(TQ.Node).init(gpa);

    var line_iter = mem.split(u8, txt, "\n");
    while (line_iter.next()) |line| {
        const val = try std.fmt.parseInt(i64, line, 10);
        try list.append(TQ.Node{ .data = val });
    }
    return list;
}

fn nth(tq: *TQ, item: *TQ.Node, n: usize) *TQ.Node {
    var c: usize = 0;
    var cur = item;
    while (c < n) : (c += 1) {
        cur = if (cur.next) |x| x else tq.first.?;
    }
    return cur;
}

fn solve(text: Str, mix: usize, key: i64) !i64 {
    var list = try parse(text);
    defer list.deinit();

    var tq = TQ{};

    var idx_zero: usize = 0;

    for (list.items) |*item, idx| {
        tq.append(item);
        item.data *= key;
        if (item.data == 0) idx_zero = idx;
    }

    var m: usize = 0;
    while (m < mix) : (m += 1) {
        for (list.items) |*item| {
            var cur = item;
            const cnt = @mod(item.data, @intCast(i64, list.items.len - 1));

            if (cnt > 0) {
                cur = if (item.next) |n| n else tq.first.?;
                tq.remove(item);
                cur = nth(&tq, cur, @intCast(usize, cnt - 1));

                if (cur == tq.last) {
                    tq.insertBefore(tq.first.?, item);
                } else {
                    assert(cur != item);
                    tq.insertAfter(cur, item);
                }
            }
        }
    }

    var sum: i64 = 0;
    sum += nth(&tq, &list.items[idx_zero], 1000).data;
    sum += nth(&tq, &list.items[idx_zero], 2000).data;
    sum += nth(&tq, &list.items[idx_zero], 3000).data;

    return sum;
}

fn p1(text: Str) !i64 {
    return solve(text, 1, 1);
}

fn p2(text: Str) !i64 {
    return solve(text, 10, 811589153);
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");

    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
