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
    var sack_iter = mem.tokenize(u8, text, "\n");

    var sum: i32 = 0;
    while (sack_iter.next()) |items| {
        var memo = [_]bool{false} ** 256;
        const com_a = items[0..(items.len / 2)];
        const com_b = items[(items.len / 2)..];

        for (com_a) |i| {
            memo[i] = true;
        }

        for (com_b) |i| {
            if (memo[i]) {
                if (std.ascii.isLower(i)) {
                    sum += (i - 'a') + 1;
                } else {
                    sum += (i - 'A') + 27;
                }
                break;
            }
        }
    }
    return sum;
}

fn p2(text: Str) !i32 {
    var sack_iter = mem.tokenize(u8, text, "\n");

    var sum: i32 = 0;
    while (true) {
        var memo_a = [_]bool{false} ** 256;
        var memo_b = [_]bool{false} ** 256;
        const com_a = sack_iter.next() orelse break;
        const com_b = sack_iter.next().?;
        const com_c = sack_iter.next().?;

        for (com_a) |i| {
            memo_a[i] = true;
        }

        for (com_b) |i| {
            if (memo_a[i]) {
                memo_b[i] = true;
            }
        }

        for (com_c) |i| {
            if (memo_b[i]) {
                if (std.ascii.isLower(i)) {
                    sum += (i - 'a') + 1;
                } else {
                    sum += (i - 'A') + 27;
                }
                break;
            }
        }
    }
    return sum;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    print("Part 1: {}\n", .{try p1(text)});
    print("Part 2: {}\n", .{try p2(text)});
}
