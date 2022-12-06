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

fn p1(text: Str) !usize {
    const LEN: usize = 4;
    var end: usize = LEN;
    outer: while (end <= text.len) : (end += 1) {
        var memo = [_]bool{false} ** 256;
        const sl = text[(end - LEN)..end];

        for (sl) |c| {
            if (memo[c]) {
                continue :outer;
            }
            memo[c] = true;
        }
        return end;
    }
    return 0;
}

fn p2(text: Str) !usize {
    const LEN: usize = 14;
    var end: usize = LEN;
    outer: while (end <= text.len) : (end += 1) {
        var memo = [_]bool{false} ** 256;
        const sl = text[(end - LEN)..end];

        for (sl) |c| {
            if (memo[c]) {
                continue :outer;
            }
            memo[c] = true;
        }
        return end;
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
