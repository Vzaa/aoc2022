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

const Point = [2]i32;
const Map = AutoHashMap(Point, Tile);

const Tile = enum { Wall, Open };
const Dir = enum {
    N,
    S,
    W,
    E,
    fn turn(self: *Dir, lr: LR) Dir {
        switch (lr) {
            LR.L => {
                return switch (self.*) {
                    Dir.N => Dir.W,
                    Dir.S => Dir.E,
                    Dir.W => Dir.S,
                    Dir.E => Dir.N,
                };
            },
            LR.R => {
                return switch (self.*) {
                    Dir.N => Dir.E,
                    Dir.S => Dir.W,
                    Dir.W => Dir.N,
                    Dir.E => Dir.S,
                };
            },
        }
    }

    fn asVec(self: *Dir) Point {
        return switch (self.*) {
            Dir.N => .{ 0, -1 },
            Dir.S => .{ 0, 1 },
            Dir.W => .{ -1, 0 },
            Dir.E => .{ 1, 0 },
        };
    }

    fn num(self: *Dir) i32 {
        return switch (self.*) {
            Dir.N => 3,
            Dir.S => 1,
            Dir.W => 2,
            Dir.E => 0,
        };
    }
};
const LR = enum { L, R };

const Action = union(enum) {
    turn: LR,
    move: i32,

    fn parse(text: Str) !ArrayList(Action) {
        var list = ArrayList(Action).init(gpa);
        var move_iter = mem.tokenize(u8, text, "LR");
        var turn_iter = mem.tokenize(u8, text, "0123456789");

        while (true) {
            if (move_iter.next()) |s| {
                const val = try std.fmt.parseInt(i32, s, 10);
                try list.append(Action{ .move = val });
            } else {
                break;
            }

            if (turn_iter.next()) |s| {
                var turn = if (s[0] == 'L') LR.L else LR.R;
                try list.append(Action{ .turn = turn });
            }
        }

        return list;
    }
};

fn parseMap(text: Str, pos: *Point) !Map {
    var map = Map.init(gpa);

    var line_iter = mem.split(u8, text, "\n");

    var first = true;

    var y: i32 = 0;
    while (line_iter.next()) |line| : (y += 1) {
        var x: i32 = 0;
        for (line) |c| {
            if (c == '.') {
                if (first) {
                    pos.* = .{ x, y };
                    first = false;
                }
                try map.put(.{ x, y }, Tile.Open);
            } else if (c == '#') {
                try map.put(.{ x, y }, Tile.Wall);
            }
            x += 1;
        }
    }
    return map;
}

fn add(a: Point, b: Point) Point {
    return Point{ a[0] + b[0], a[1] + b[1] };
}

fn neg(a: Point) Point {
    return Point{ a[0] * -1, a[1] * -1 };
}

fn move(map: *Map, pos: Point, dir: Point, cnt: i32) Point {
    var cur = pos;
    const rev = neg(dir);

    var i: i32 = 0;
    while (i < cnt) : (i += 1) {
        var next = add(cur, dir);

        if (map.get(next)) |t| {
            if (t == Tile.Wall) return cur;
            if (t == Tile.Open) cur = next;
        } else {
            next = add(cur, rev);
            var wrap: Tile = undefined;
            while (map.get(next)) |t| {
                wrap = t;
                next = add(next, rev);
            }
            if (wrap == Tile.Wall) return cur;
            if (wrap == Tile.Open) cur = next;
        }
    }
    return cur;
}

fn p1(text: Str) !i64 {
    var iter = mem.split(u8, text, "\n\n");

    var pos: Point = undefined;
    var dir = Dir.E;

    var map = try parseMap(iter.next().?, &pos);
    defer map.deinit();

    var actions = try Action.parse(iter.next().?);
    defer actions.deinit();

    for (actions.items) |a| {
        switch (a) {
            Action.turn => |*t| {
                dir = dir.turn(t.*);
            },
            Action.move => |*m| {
                pos = move(&map, pos, dir.asVec(), m.*);
            },
        }
    }

    return dir.num() + (pos[1] + 1) * 1000 + (pos[0] + 1) * 4;
}

fn region(p: Point) i32 {
    const x = p[0];
    const y = p[1];

    const S = 50;

    if (x >= S and x < 2 * S and y >= 0 and y < S) {
        return 1;
    } else if (x >= 2 * S and x < 3 * S and y >= 0 and y < S) {
        return 2;
    } else if (x >= S and x < 2 * S and y >= S and y < 2 * S) {
        return 3;
    } else if (x >= 0 and x < S and y >= 2 * S and y < 3 * S) {
        return 4;
    } else if (x >= S and x < 2 * S and y >= 2 * S and y < 3 * S) {
        return 5;
    } else if (x >= 0 and x < S and y >= 3 * S and y < 4 * S) {
        return 6;
    } else {
        unreachable;
    }
}

fn regionPos(r: i32, x: i32, y: i32) Point {
    const S: i32 = 50;

    return switch (r) {
        1 => .{ S + x, y },
        2 => .{ 2 * S + x, y },
        3 => .{ S + x, S + y },
        4 => .{ x, 2 * S + y },
        5 => .{ S + x, 2 * S + y },
        6 => .{ x, 3 * S + y },
        else => unreachable,
    };
}

fn wrapp(pos: *Point, dirp: *Dir) void {
    const reg = region(pos.*);
    const dir = dirp.*;

    const S: i32 = 50;

    const relx = @mod(pos.*[0], S);
    const rely = @mod(pos.*[1], S);

    if (reg == 1) {
        assert(dir == Dir.N or dir == Dir.W);

        switch (dir) {
            Dir.N => {
                dirp.* = Dir.E;
                pos.* = regionPos(6, 0, relx);
                assert(region(pos.*) == 6);
            },
            Dir.W => {
                dirp.* = Dir.E;
                pos.* = regionPos(4, 0, S - 1 - rely);
                assert(region(pos.*) == 4);
            },
            else => unreachable,
        }
    } else if (reg == 2) {
        assert(dir == Dir.N or dir == Dir.E or dir == Dir.S);
        switch (dir) {
            Dir.N => {
                dirp.* = Dir.N;
                pos.* = regionPos(6, relx, S - 1);
                assert(region(pos.*) == 6);
            },
            Dir.E => {
                dirp.* = Dir.W;
                pos.* = regionPos(5, S - 1, S - rely - 1);
                assert(region(pos.*) == 5);
            },
            Dir.S => {
                dirp.* = Dir.W;
                pos.* = regionPos(3, S - 1, relx);
                assert(region(pos.*) == 3);
            },
            else => unreachable,
        }
    } else if (reg == 3) {
        assert(dir == Dir.E or dir == Dir.W);
        switch (dir) {
            Dir.W => {
                dirp.* = Dir.S;
                pos.* = regionPos(4, rely, 0);
                assert(region(pos.*) == 4);
            },
            Dir.E => {
                dirp.* = Dir.N;
                pos.* = regionPos(2, rely, S - 1);
                assert(region(pos.*) == 2);
            },
            else => unreachable,
        }
    } else if (reg == 4) {
        assert(dir == Dir.N or dir == Dir.W);
        switch (dir) {
            Dir.N => {
                dirp.* = Dir.E;
                pos.* = regionPos(3, 0, relx);
                assert(region(pos.*) == 3);
            },
            Dir.W => {
                dirp.* = Dir.E;
                pos.* = regionPos(1, 0, S - 1 - rely);
                assert(region(pos.*) == 1);
            },
            else => unreachable,
        }
    } else if (reg == 5) {
        assert(dir == Dir.E or dir == Dir.S);
        switch (dir) {
            Dir.S => {
                dirp.* = Dir.W;
                pos.* = regionPos(6, S - 1, relx);
                assert(region(pos.*) == 6);
            },
            Dir.E => {
                dirp.* = Dir.W;
                pos.* = regionPos(2, S - 1, S - 1 - rely);
                assert(region(pos.*) == 2);
            },
            else => unreachable,
        }
    } else if (reg == 6) {
        assert(dir == Dir.W or dir == Dir.E or dir == Dir.S);
        switch (dir) {
            Dir.S => {
                dirp.* = Dir.S;
                pos.* = regionPos(2, relx, 0);
                assert(region(pos.*) == 2);
            },
            Dir.E => {
                dirp.* = Dir.N;
                pos.* = regionPos(5, rely, S - 1);
                assert(region(pos.*) == 5);
            },
            Dir.W => {
                dirp.* = Dir.S;
                pos.* = regionPos(1, rely, 0);
                assert(region(pos.*) == 1);
            },
            else => unreachable,
        }
    }
}

fn move2(map: *Map, pos: *Point, dir: *Dir, cnt: i32) void {
    var i: i32 = 0;
    while (i < cnt) : (i += 1) {
        var next = add(pos.*, dir.asVec());

        if (map.get(next)) |t| {
            if (t == Tile.Wall) return;
            if (t == Tile.Open) pos.* = next;
        } else {
            next = pos.*;
            var tmp_dir = dir.*;
            wrapp(&next, &tmp_dir);
            const t = map.get(next).?;
            if (t == Tile.Wall) return;
            if (t == Tile.Open) {
                pos.* = next;
                dir.* = tmp_dir;
            }
        }
    }
}

fn p2(text: Str) !i64 {
    var iter = mem.split(u8, text, "\n\n");

    var pos: Point = undefined;
    var dir = Dir.E;

    var map = try parseMap(iter.next().?, &pos);
    defer map.deinit();

    var actions = try Action.parse(iter.next().?);
    defer actions.deinit();

    for (actions.items) |a| {
        switch (a) {
            Action.turn => |*t| {
                dir = dir.turn(t.*);
            },
            Action.move => |*m| {
                move2(&map, &pos, &dir, m.*);
            },
        }
    }

    return dir.num() + (pos[1] + 1) * 1000 + (pos[0] + 1) * 4;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");

    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
