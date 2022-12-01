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

fn p1(text: Str) !i32 {
    var elf_iter = mem.split(u8, text, "\n\n");
    var list = ArrayList(i32).init(gpa);
    defer list.deinit();

    while (elf_iter.next()) |line| {
        var cal_iter = mem.tokenize(u8, line, "\n");
        var sum: i32 = 0;
        while (cal_iter.next()) |cal| {
            const c = try std.fmt.parseInt(i32, cal, 10);
            sum += c;
        }
        try list.append(sum);
    }

    var m = mem.max(i32, list.items);
    return m;
}

fn p2(text: Str) !i32 {
    var elf_iter = mem.split(u8, text, "\n\n");
    var list = ArrayList(i32).init(gpa);
    defer list.deinit();

    while (elf_iter.next()) |line| {
        var cal_iter = mem.tokenize(u8, line, "\n");
        var sum: i32 = 0;
        while (cal_iter.next()) |cal| {
            const c = try std.fmt.parseInt(i32, cal, 10);
            sum += c;
        }
        try list.append(sum);
    }
    std.sort.sort(i32, list.items, {}, comptime std.sort.desc(i32));
    return list.items[0] + list.items[1] + list.items[2];
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    print("Part 1: {}\n", .{try p1(text)});
    print("Part 2: {}\n", .{try p2(text)});
}
