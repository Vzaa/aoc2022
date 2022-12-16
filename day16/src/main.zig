const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const PriorityQueue = std.PriorityQueue;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
const math = std.math;
const Str = []const u8;

// var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_impl = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const gpa = gpa_impl.allocator();

const LEN: usize = 51;
const MIN: i8 = 30;
const MIN2: i8 = 26;

const IdMap = [LEN]Node;
const DistMap = [LEN]i32;
const Dists = AutoHashMap(u8, DistMap);
const OpenMap = u64;

const Graph = StringHashMap(*Node);

const Node = struct {
    name: Str,
    edges: ArrayList(Str),
    flow: i32,
    id: u8,

    fn parse(text: Str) !Node {
        var iter = mem.split(u8, text, " ");
        _ = iter.next().?;
        var node = iter.next().?;
        _ = iter.next().?;
        _ = iter.next().?;
        var flow_iter = mem.tokenize(u8, iter.next().?, "rate=;");
        _ = iter.next().?;
        _ = iter.next().?;
        _ = iter.next().?;
        _ = iter.next().?;

        var flow = try std.fmt.parseInt(i32, flow_iter.next().?, 10);

        var list = ArrayList(Str).init(gpa);
        while (iter.next()) |vuns| {
            var tmp = mem.tokenize(u8, vuns, ",");
            var v = tmp.next().?;
            try list.append(v);
        }

        return Node{ .name = node, .edges = list, .flow = flow, .id = 0 };
    }

    fn deinit(self: *Node) void {
        self.edges.deinit();
    }
};

const State = struct {
    min: i8,
    pos: u8,
    open: OpenMap,

    fn init(pos: u8) State {
        var open: u64 = 0;
        return State{ .min = 0, .pos = pos, .open = open };
    }

    fn clone(self: *State) !State {
        return State{ .min = self.min, .pos = self.pos, .open = self.open };
    }
};

const PC = struct {
    state: State,
    p: i32,

    fn init(pos: u8) PC {
        return PC{ .state = State.init(pos), .p = 0 };
    }

    fn clone(self: *PC) !PC {
        return PC{
            .state = try self.state.clone(),
            .p = self.p,
        };
    }

    fn tickScore(self: *PC, id_map: *IdMap) i32 {
        var score: i32 = 0;

        var i: u6 = 0;
        while (i < LEN) : (i += 1) {
            const map: u64 = @shlExact(@as(u64, 1), i);
            if (map & self.state.open == map) {
                score += id_map[i].flow;
            }
        }
        return score;
    }

    fn tick(self: *PC, id_map: *IdMap, mins: i8) void {
        var i: u6 = 0;
        if (mins == 0) return;
        while (i < LEN) : (i += 1) {
            const map: u64 = @shlExact(@as(u64, 1), i);
            if (map & self.state.open == map) {
                self.p += id_map[i].flow * mins;
            }
        }
        self.state.min += mins;
    }

    fn isOpen(self: *PC, v: usize) bool {
        const map: u64 = @shlExact(@as(u64, 1), @intCast(u6, v));
        return (map & self.state.open) == map;
    }

    fn open(self: *PC, v: usize) void {
        const map: u64 = @shlExact(@as(u64, 1), @intCast(u6, v));
        self.state.open |= map;
    }

    fn allOpen(self: *PC) bool {
        var i: usize = 0;
        while (i < LEN) : (i += 1) {
            if (!self.isOpen(i)) {
                return false;
            }
        }
        return true;
    }
};

fn compPc(_: void, a: PC, b: PC) std.math.Order {
    return std.math.order(a.p, b.p);
}

fn compPc2(_: void, a: PC2, b: PC2) std.math.Order {
    return std.math.order(a.c, b.c);
}

const PC2 = struct {
    p: u8,
    c: i32,
};

fn shortest(nodes: *Graph, id_map: *IdMap, cur_idx: u8, tgt: u8) !i32 {
    var frontier = PriorityQueue(PC2, void, compPc2).init(gpa, {});
    defer frontier.deinit();

    var visited = AutoHashMap(u8, i32).init(gpa);
    defer visited.deinit();

    try frontier.add(PC2{ .p = cur_idx, .c = 0 });

    while (frontier.removeOrNull()) |cur| {
        var cur_cost = cur.c;

        try visited.put(cur.p, cur.c);

        if (cur.p == tgt) {
            return cur.c;
        }

        var n = id_map[cur.p];

        for (n.edges.items) |e| {
            var cost = cur_cost + 1;
            const id = nodes.get(e).?.id;

            if (visited.get(id)) |old_c| {
                if (old_c > cost) {
                    try frontier.add(PC2{ .p = id, .c = cost });
                    try visited.put(id, cost);
                }
            } else {
                try frontier.add(PC2{ .p = id, .c = cost });
                try visited.put(id, cost);
            }
        }
    }
    unreachable;
}

fn ucs(nodes: *Graph, pos: u8, id_map: *IdMap, dists: *Dists) !i32 {
    var frontier = PriorityQueue(PC, void, compPc).init(gpa, {});
    defer frontier.deinit();
    _ = nodes;

    var m: i32 = 0;
    try frontier.add(PC.init(pos));

    while (frontier.removeOrNull()) |wtf| {
        var cur = wtf;

        if (cur.state.min == 30) {
            m = @max(cur.p, m);
            continue;
        }

        if (!cur.isOpen(cur.state.pos) and id_map[cur.state.pos].flow != 0) {
            var next = try cur.clone();
            next.tick(id_map, 1);
            next.open(cur.state.pos);
            try frontier.add(next);
            continue;
        }

        var idx: u8 = 0;
        const remain = MIN - cur.state.min;

        while (idx < LEN) : (idx += 1) {
            if (cur.isOpen(idx)) {
                continue;
            }

            if (cur.state.pos == idx) {
                continue;
            }

            if (id_map[idx].flow == 0) {
                continue;
            }

            var dist = dists.get(cur.state.pos).?[idx];

            if (remain < dist) {
                var next = try cur.clone();
                next.tick(id_map, @intCast(i8, remain));
                try frontier.add(next);
                continue;
            }

            var next = try cur.clone();
            next.tick(id_map, @intCast(i8, dist));
            next.state.pos = idx;
            try frontier.add(next);
        }

        var next = try cur.clone();
        next.tick(id_map, @intCast(i8, remain));
        try frontier.add(next);
    }

    return m;
}

fn isTgt(tgts: OpenMap, tgt: usize) bool {
    const map: u64 = @shlExact(@as(u64, 1), @intCast(u6, tgt));
    return (map & tgts) == map;
}

fn ucs2(nodes: *Graph, pos: u8, id_map: *IdMap, dists: *Dists, tgts: OpenMap) !i32 {
    var frontier = PriorityQueue(PC, void, compPc).init(gpa, {});
    defer frontier.deinit();
    _ = nodes;

    var m: i32 = 0;
    try frontier.add(PC.init(pos));

    while (frontier.removeOrNull()) |wtf| {
        var cur = wtf;

        if (cur.state.min == MIN2) {
            m = @max(cur.p, m);
            continue;
        }

        if (!cur.isOpen(cur.state.pos) and id_map[cur.state.pos].flow != 0) {
            var next = try cur.clone();
            next.tick(id_map, 1);
            next.open(cur.state.pos);
            try frontier.add(next);
            continue;
        }

        var idx: u8 = 0;
        const remain = MIN2 - cur.state.min;

        while (idx < LEN) : (idx += 1) {
            if (cur.isOpen(idx)) {
                continue;
            }

            if (cur.state.pos == idx) {
                continue;
            }

            if (!isTgt(tgts, idx)) {
                continue;
            }

            if (id_map[idx].flow == 0) {
                continue;
            }

            var dist = dists.get(cur.state.pos).?[idx];

            if (remain < dist) {
                var next = try cur.clone();
                next.tick(id_map, @intCast(i8, remain));
                try frontier.add(next);
                continue;
            }

            var next = try cur.clone();
            next.tick(id_map, @intCast(i8, dist));
            next.state.pos = idx;
            try frontier.add(next);
        }

        var next = try cur.clone();
        next.tick(id_map, @intCast(i8, remain));
        try frontier.add(next);
    }

    return m;
}

fn preCalc(nodes: *Graph, id_map: *IdMap) !Dists {
    var map = AutoHashMap(u8, DistMap).init(gpa);

    var i: u8 = 0;
    while (i < LEN) : (i += 1) {
        var distmap: DistMap = undefined;
        var j: u8 = 0;
        while (j < LEN) : (j += 1) {
            if (i == j) continue;
            const res = try shortest(nodes, id_map, i, j);
            // print("dist {}\n", .{res});
            distmap[j] = res;
        }

        try map.put(i, distmap);
    }

    return map;
}

fn p1(text: Str) !i32 {
    var id_map: IdMap = undefined;

    var nodes = Graph.init(gpa);
    defer nodes.deinit();
    defer {
        var viter = nodes.valueIterator();
        while (viter.next()) |v| v.*.deinit();
    }

    var start: u8 = 0;

    var id: u8 = 0;
    var line_iter = mem.split(u8, text, "\n");
    while (line_iter.next()) |line| {
        var n = try Node.parse(line);
        id_map[id] = n;
        id += 1;
    }
    std.sort.sort(Node, &id_map, {}, sorter);

    for (id_map) |*n, idx| {
        if (mem.eql(u8, "AA", n.name)) {
            start = @intCast(u8, idx);
        }
        n.id = @intCast(u8, idx);
        try nodes.put(n.name, &id_map[idx]);
    }

    var dists = try preCalc(&nodes, &id_map);
    defer dists.deinit();

    var res = try ucs(&nodes, start, &id_map, &dists);
    return res;
}

fn sorter(_: void, a: Node, b: Node) bool {
    return a.flow > b.flow;
}

fn p2(text: Str) !i64 {
    var id_map: IdMap = undefined;

    var nodes = Graph.init(gpa);
    defer nodes.deinit();
    defer {
        var viter = nodes.valueIterator();
        while (viter.next()) |v| v.*.deinit();
    }

    var start: u8 = 0;

    var id: u8 = 0;
    var line_iter = mem.split(u8, text, "\n");
    while (line_iter.next()) |line| {
        var n = try Node.parse(line);
        id_map[id] = n;
        id += 1;
    }
    std.sort.sort(Node, &id_map, {}, sorter);

    var cnt: u6 = 0;

    for (id_map) |*n, idx| {
        if (mem.eql(u8, "AA", n.name)) {
            start = @intCast(u8, idx);
        }
        n.id = @intCast(u8, idx);
        if (n.flow > 0) cnt += 1;
        try nodes.put(n.name, &id_map[idx]);
    }

    var dists = try preCalc(&nodes, &id_map);
    defer dists.deinit();

    var tgts: OpenMap = 0;

    var m: i32 = 0;
    while (tgts < @shlExact(@as(u64, 1), cnt)) : (tgts += 1) {
        var a = try ucs2(&nodes, start, &id_map, &dists, tgts);
        var b = try ucs2(&nodes, start, &id_map, &dists, ~tgts);
        m = @max(a + b, m);
    }
    return m;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
