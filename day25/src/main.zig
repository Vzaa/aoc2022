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

fn parse(txt: Str) !i64 {
    var rev = try gpa.dupe(u8, txt);
    defer gpa.free(rev);
    mem.reverse(u8, rev);

    var val: i64 = 0;

    for (rev) |c, idx| {
        const digit: i64 = switch (c) {
            '0'...'2' => try std.fmt.charToDigit(c, 10),
            '-' => -1,
            '=' => -2,
            else => unreachable,
        };
        val += digit * std.math.pow(i64, 5, @intCast(i64, idx));
    }

    return val;
}

fn p1(text: Str) !i64 {
    var iter = mem.split(u8, text, "\n");
    var sum: i64 = 0;
    while (iter.next()) |line| {
        sum += try parse(line);
    }
    // by hand lol
    const x = try parse("2011-=2=-1020-1===-1");
    assert(x == sum);
    return x;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");

    print("Part 1: {}\n", .{try p1(trimmed)});
}
