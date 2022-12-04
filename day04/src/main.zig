const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
const math = std.math;
const Str = []const u8;

const Range = [2]i32;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

// Some code from last year's Day 22
fn rangeFromStr(txt: Str) !Range {
    var num_iter = mem.split(u8, txt, "-");
    const a = try std.fmt.parseInt(i32, num_iter.next().?, 10);
    const b = try std.fmt.parseInt(i32, num_iter.next().?, 10);
    return Range{ a, b };
}

fn rangeContains(a: Range, b: Range) bool {
    return a[0] >= b[0] and a[1] <= b[1];
}

fn checkPoint(r: Range, p: i32) bool {
    return (p >= r[0] and p <= r[1]);
}

fn rangeOverlap(a: Range, b: Range) bool {
    return checkPoint(a, b[0]) or checkPoint(a, b[1]) or checkPoint(b, a[0]) or checkPoint(b, a[1]);
}

fn p1(text: Str) !i32 {
    var line_iter = mem.tokenize(u8, text, "\n\n");
    var cnt: i32 = 0;
    while (line_iter.next()) |line| {
        var elf_iter = mem.split(u8, line, ",");
        const elf_a = elf_iter.next().?;
        const elf_b = elf_iter.next().?;
        const range_a = try rangeFromStr(elf_a);
        const range_b = try rangeFromStr(elf_b);
        if (rangeContains(range_a, range_b) or rangeContains(range_b, range_a)) {
            cnt += 1;
        }
    }

    return cnt;
}

fn p2(text: Str) !i32 {
    var line_iter = mem.tokenize(u8, text, "\n\n");
    var cnt: i32 = 0;
    while (line_iter.next()) |line| {
        var elf_iter = mem.split(u8, line, ",");
        const elf_a = elf_iter.next().?;
        const elf_b = elf_iter.next().?;
        const range_a = try rangeFromStr(elf_a);
        const range_b = try rangeFromStr(elf_b);
        if (rangeOverlap(range_a, range_b)) {
            cnt += 1;
        }
    }

    return cnt;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    print("Part 1: {}\n", .{try p1(text)});
    print("Part 2: {}\n", .{try p2(text)});
}
