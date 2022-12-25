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

fn p1(text: Str) !void {
    var iter = mem.split(u8, text, "\n");
    var sum: i64 = 0;
    while (iter.next()) |line| {
        sum += try parse(line);
    }
    var val = try gpa.dupe(u8, "22222222222222222222");
    defer gpa.free(val);

    var digit: usize = 0;
    while (digit < val.len) : (digit += 1) {
        if (try parse(val) == sum) break;
        if (try parse(val) > sum) {
            val[digit] = '1';
        }

        if (try parse(val) == sum) break;
        if (try parse(val) > sum) {
            val[digit] = '0';
        } else {
            val[digit] = '2';
            continue;
        }

        if (try parse(val) == sum) break;
        if (try parse(val) > sum) {
            val[digit] = '-';
        } else {
            val[digit] = '1';
            continue;
        }

        if (try parse(val) == sum) break;
        if (try parse(val) > sum) {
            val[digit] = '=';
        } else {
            val[digit] = '0';
            continue;
        }

        if (try parse(val) == sum) break;
        if (try parse(val) < sum) {
            val[digit] = '-';
            continue;
        }
    }
    const x = try parse(val);
    assert(x == sum);
    print("Part 1: {s}\n", .{val});
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");

    try p1(trimmed);
}
