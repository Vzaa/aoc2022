const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const PQ = std.PriorityQueue;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
const math = std.math;
const Str = []const u8;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

fn nth(iter: *std.mem.SplitIterator(u8), n: usize) !Str {
    var c: usize = 0;
    while (c < n) : (c += 1) _ = iter.next().?;
    return iter.next().?;
}

const Robot = struct {
    ore_cost: u8,
    clay_cost: u8,
    obs_cost: u8,

    fn enough(self: *const Robot, ore: i32, clay: i32, obs: i32) bool {
        return ore >= self.ore_cost and clay >= self.clay_cost and obs >= self.obs_cost;
    }
};

const Blueprint = struct {
    id: usize,
    ore_rob: Robot,
    clay_rob: Robot,
    obs_rob: Robot,
    geo_rob: Robot,

    fn parse(txt: Str) !Blueprint {
        var bp: Blueprint = undefined;

        var lol = mem.split(u8, txt, " ");
        _ = lol.next().?;
        var id_iter = mem.tokenize(u8, lol.next().?, ":");
        bp.id = try std.fmt.parseInt(usize, id_iter.next().?, 10);

        var iter = mem.split(u8, txt, " ");

        bp.ore_rob.ore_cost = try std.fmt.parseInt(u8, try nth(&iter, 6), 10);
        bp.ore_rob.clay_cost = 0;
        bp.ore_rob.obs_cost = 0;

        bp.clay_rob.ore_cost = try std.fmt.parseInt(u8, try nth(&iter, 5), 10);
        bp.clay_rob.clay_cost = 0;
        bp.clay_rob.obs_cost = 0;

        bp.obs_rob.ore_cost = try std.fmt.parseInt(u8, try nth(&iter, 5), 10);
        bp.obs_rob.clay_cost = try std.fmt.parseInt(u8, try nth(&iter, 2), 10);
        bp.obs_rob.obs_cost = 0;

        bp.geo_rob.ore_cost = try std.fmt.parseInt(u8, try nth(&iter, 5), 10);
        bp.geo_rob.clay_cost = 0;
        bp.geo_rob.obs_cost = try std.fmt.parseInt(u8, try nth(&iter, 2), 10);

        return bp;
    }

    fn canOreRob(self: *const Blueprint, state: *const State) bool {
        return self.ore_rob.enough(state.ore, state.clay, state.obs);
    }

    fn canClayRob(self: *const Blueprint, state: *const State) bool {
        return self.clay_rob.enough(state.ore, state.clay, state.obs);
    }

    fn canObsRob(self: *const Blueprint, state: *const State) bool {
        return self.obs_rob.enough(state.ore, state.clay, state.obs);
    }

    fn canGeoRob(self: *const Blueprint, state: *const State) bool {
        return self.geo_rob.enough(state.ore, state.clay, state.obs);
    }
};

fn parseBluePrints(txt: Str) !ArrayList(Blueprint) {
    var line_iter = mem.split(u8, txt, "\n");
    var list = ArrayList(Blueprint).init(gpa);

    while (line_iter.next()) |line| {
        const bp = try Blueprint.parse(line);
        try list.append(bp);
    }

    return list;
}

const State = struct {
    ore_robs: u8 = 1,
    clay_robs: u8 = 0,
    obs_robs: u8 = 0,
    geo_robs: u8 = 0,

    ore: u16 = 0,
    clay: u16 = 0,
    obs: u16 = 0,
    geo: u16 = 0,

    min: u8 = 0,

    fn tick(self: *State) void {
        self.min += 1;
        self.ore += self.ore_robs;
        self.clay += self.clay_robs;
        self.obs += self.obs_robs;
        self.geo += self.geo_robs;
    }
};

fn compPc(_: void, a: State, b: State) std.math.Order {
    return std.math.order(b.min, a.min);
}

fn optimistic(s: *const State, bp: *const Blueprint, min: u8) u16 {
    var tmp = s.*;

    while (tmp.min <= min) {
        tmp.tick();
        tmp.ore_robs += 1;
        tmp.clay_robs += 1;
        tmp.obs_robs += 1;
        if (bp.canGeoRob(&tmp)) {
            tmp.geo_robs += 1;
            const rob = &bp.geo_rob;
            tmp.ore -= rob.ore_cost;
            tmp.clay -= rob.clay_cost;
            tmp.obs -= rob.obs_cost;
        }
    }

    return tmp.geo;
}

fn search(bp: *Blueprint, comptime min: usize) !usize {
    var frontier = PQ(State, void, compPc).init(gpa, {});
    defer frontier.deinit();

    try frontier.add(State{});

    var m: usize = 0;

    var best = State{};

    while (frontier.removeOrNull()) |tmp| {
        const cur = tmp;
        var cnt: usize = 0;

        const cur_opt = optimistic(&cur, bp, min);
        if (cur_opt == 0) continue;
        if (best.geo > 0) {
            if (cur_opt < best.geo) {
                continue;
            }
        }

        if (cur.geo > best.geo) {
            best = cur;
        }

        if (cur.min == min) {
            m = @max(cur.geo, m);
            continue;
        }

        if (bp.canOreRob(&cur)) {
            cnt += 1;
            var next = cur;
            next.tick();
            next.ore_robs += 1;
            const rob = &bp.ore_rob;
            next.ore -= rob.ore_cost;
            next.clay -= rob.clay_cost;
            next.obs -= rob.obs_cost;
            try frontier.add(next);
        }

        if (bp.canClayRob(&cur)) {
            cnt += 1;
            var next = cur;
            next.tick();
            next.clay_robs += 1;
            const rob = &bp.clay_rob;
            next.ore -= rob.ore_cost;
            next.clay -= rob.clay_cost;
            next.obs -= rob.obs_cost;
            try frontier.add(next);
        }

        if (bp.canObsRob(&cur)) {
            cnt += 1;
            var next = cur;
            next.tick();
            next.obs_robs += 1;
            const rob = &bp.obs_rob;
            next.ore -= rob.ore_cost;
            next.clay -= rob.clay_cost;
            next.obs -= rob.obs_cost;
            try frontier.add(next);
        }

        if (bp.canGeoRob(&cur)) {
            cnt += 1;
            var next = cur;
            next.tick();
            next.geo_robs += 1;
            const rob = &bp.geo_rob;
            next.ore -= rob.ore_cost;
            next.clay -= rob.clay_cost;
            next.obs -= rob.obs_cost;
            try frontier.add(next);
        }

        if (cnt < 4) {
            var next = cur;
            next.tick();
            try frontier.add(next);
        }
    }
    return m;
}

fn p1(text: Str) !usize {
    var bps = try parseBluePrints(text);
    defer bps.deinit();

    var q: usize = 0;

    for (bps.items) |*bp| {
        const c = (try search(bp, 24)) * (bp.id);
        q += c;
    }

    return q;
}

fn p2(text: Str) !usize {
    var bps = try parseBluePrints(text);
    defer bps.deinit();

    var q: usize = 1;

    for (bps.items) |*bp, idx| {
        if (idx >= 3) {
            break;
        }
        const c = (try search(bp, 32));
        q *= c;
    }

    return q;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");

    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
