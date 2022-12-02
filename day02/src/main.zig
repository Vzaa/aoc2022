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

const D2Errors = error{
    InvalidChar,
};

const Hand = enum {
    Rock,
    Paper,
    Scissors,

    fn fromChar(c: u8) !Hand {
        return switch (c) {
            'A', 'X' => Hand.Rock,
            'B', 'Y' => Hand.Paper,
            'C', 'Z' => Hand.Scissors,
            else => D2Errors.InvalidChar,
        };
    }

    fn score(self: *const Hand) i32 {
        return switch (self.*) {
            Hand.Rock => 1,
            Hand.Paper => 2,
            Hand.Scissors => 3,
        };
    }

    fn fightScore(self: *const Hand, other: Hand) i32 {
        if (self.* == other) {
            return 3;
        } else if ((self.* == Hand.Rock and other == Hand.Scissors) or
            (self.* == Hand.Paper and other == Hand.Rock) or
            (self.* == Hand.Scissors and other == Hand.Paper))
        {
            return 6;
        } else {
            return 0;
        }
    }

    fn getOther(self: *const Hand, a: Action) Hand {
        return switch (a) {
            Action.Draw => self.*,
            Action.Win => switch (self.*) {
                Hand.Rock => Hand.Paper,
                Hand.Paper => Hand.Scissors,
                Hand.Scissors => Hand.Rock,
            },
            Action.Lose => switch (self.*) {
                Hand.Rock => Hand.Scissors,
                Hand.Paper => Hand.Rock,
                Hand.Scissors => Hand.Paper,
            },
        };
    }
};

const Action = enum {
    Win,
    Lose,
    Draw,

    fn fromChar(c: u8) !Action {
        return switch (c) {
            'X' => Action.Lose,
            'Y' => Action.Draw,
            'Z' => Action.Win,
            else => D2Errors.InvalidChar,
        };
    }
};

fn p1(text: Str) !i32 {
    var line_iter = mem.tokenize(u8, text, "\n");
    var score: i32 = 0;

    while (line_iter.next()) |line| {
        var sp_iter = mem.split(u8, line, " ");
        const first_str = sp_iter.next().?;
        const second_str = sp_iter.next().?;
        const first = try Hand.fromChar(first_str[0]);
        const second = try Hand.fromChar(second_str[0]);
        score += second.score();
        score += second.fightScore(first);
    }
    return score;
}

fn p2(text: Str) !i32 {
    var line_iter = mem.tokenize(u8, text, "\n");
    var score: i32 = 0;

    while (line_iter.next()) |line| {
        var sp_iter = mem.split(u8, line, " ");
        const first_str = sp_iter.next().?;
        const second_str = sp_iter.next().?;
        const first = try Hand.fromChar(first_str[0]);
        const action = try Action.fromChar(second_str[0]);
        const second = first.getOther(action);
        score += second.score();
        score += second.fightScore(first);
    }
    return score;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    print("Part 1: {}\n", .{try p1(text)});
    print("Part 2: {}\n", .{try p2(text)});
}
