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

const List = ArrayList(Item);

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Item = union(enum) {
    Int: i32,
    List: List,

    fn disp(self: *const Item) void {
        switch (self.*) {
            .Int => |*v| print("{}", .{v.*}),
            .List => |*l| {
                print("[", .{});
                for (l.items) |x, idx| {
                    if (idx != 0) {
                        print(",", .{});
                    }
                    x.disp();
                }
                print("]", .{});
            },
        }
    }

    fn deinit(self: *Item) void {
        switch (self.*) {
            .List => |*l| {
                for (l.items) |*x| {
                    x.deinit();
                }
                l.deinit();
            },
            else => return,
        }
    }
};

fn parseInt(txt: Str, cursor: *usize) !i32 {
    var buf = ArrayList(u8).init(gpa);
    defer buf.deinit();
    while (true) : (cursor.* += 1) {
        switch (txt[cursor.*]) {
            '0'...'9' => {
                try buf.append(txt[cursor.*]);
            },
            ',', ']' => {
                return try std.fmt.parseInt(u8, buf.items, 10);
            },
            else => {
                unreachable;
            },
        }
    }
}

fn parse(txt: Str, cursor: *usize) !?Item {
    const c = txt[cursor.*];
    switch (c) {
        '[' => {
            var l = List.init(gpa);
            while (txt[cursor.*] != ']') {
                cursor.* += 1;
                const v = try parse(txt, cursor);
                if (v) |vv| {
                    try l.append(vv);
                }
            }
            cursor.* += 1;
            return Item{ .List = l };
        },
        '0'...'9' => {
            var i = try parseInt(txt, cursor);
            return Item{ .Int = i };
        },
        ']' => {
            return null;
        },
        else => {
            unreachable;
        },
    }
    unreachable;
}

const Comp = enum {
    Cont,
    Ordered,
    NotOrdered,
};

fn compare(left: *const Item, right: *const Item) !Comp {
    switch (left.*) {
        Item.Int => |*vl| {
            switch (right.*) {
                Item.Int => |*vr| {
                    if (vl.* == vr.*) {
                        return Comp.Cont;
                    } else if (vl.* > vr.*) {
                        return Comp.NotOrdered;
                    } else {
                        return Comp.Ordered;
                    }
                },
                Item.List => |_| {
                    var tmp = List.init(gpa);
                    defer tmp.deinit();
                    try tmp.append(Item{ .Int = vl.* });
                    var tmp_item = Item{ .List = tmp };
                    return compare(&tmp_item, right);
                },
            }
        },
        Item.List => |*ll| {
            switch (right.*) {
                Item.Int => |*vr| {
                    var tmp = List.init(gpa);
                    defer tmp.deinit();
                    try tmp.append(Item{ .Int = vr.* });
                    var tmp_item = Item{ .List = tmp };
                    return compare(left, &tmp_item);
                },
                Item.List => |*lr| {
                    for (ll.items) |*l, idx| {
                        if (idx >= lr.items.len) {
                            return Comp.NotOrdered;
                        }
                        const r = &lr.items[idx];
                        const result = try compare(l, r);
                        if (result == Comp.Cont) {
                            continue;
                        }
                        return result;
                    }
                    if (ll.items.len == lr.items.len) {
                        return Comp.Cont;
                    } else {
                        return Comp.Ordered;
                    }
                },
            }
        },
    }
}

fn p1(text: Str) !usize {
    var pair_iter = mem.split(u8, text, "\n\n");
    var idx: usize = 1;
    var sum: usize = 0;
    while (pair_iter.next()) |pair_str| {
        var line_iter = mem.split(u8, pair_str, "\n");
        var cursor: usize = 0;
        var left = (try parse(line_iter.next().?, &cursor)).?;
        defer left.deinit();
        cursor = 0;
        var right = (try parse(line_iter.next().?, &cursor)).?;
        defer right.deinit();

        const cmp = try compare(&left, &right);
        if (cmp != Comp.NotOrdered) {
            sum += idx;
        }
        idx += 1;
    }
    return sum;
}

fn getDivider(val: i32) !Item {
    var a = ArrayList(Item).init(gpa);
    var aa = ArrayList(Item).init(gpa);
    try aa.append(Item{ .Int = val });
    try a.append(Item{ .List = aa });
    return Item{ .List = a };
}

fn sorter(_: void, a: Item, b: Item) bool {
    const cmp = compare(&a, &b) catch Comp.NotOrdered;
    return cmp != Comp.NotOrdered;
}

fn p2(text: Str) !usize {
    var pair_iter = mem.split(u8, text, "\n\n");

    var list = ArrayList(Item).init(gpa);
    defer list.deinit();
    defer for (list.items) |*l| l.deinit();

    while (pair_iter.next()) |pair_str| {
        var line_iter = mem.split(u8, pair_str, "\n");
        var cursor: usize = 0;
        var left = (try parse(line_iter.next().?, &cursor)).?;
        cursor = 0;
        var right = (try parse(line_iter.next().?, &cursor)).?;

        try list.append(left);
        try list.append(right);
    }

    var div_a = try getDivider(2);
    var div_b = try getDivider(6);

    try list.append(div_a);
    try list.append(div_b);

    std.sort.sort(Item, list.items, {}, sorter);

    var mul: usize = 1;
    for (list.items) |*x, idx| {
        // ayy lmao
        if (x.List.items.ptr == div_a.List.items.ptr) {
            mul *= idx + 1;
        } else if (x.List.items.ptr == div_b.List.items.ptr) {
            mul *= idx + 1;
        }
    }
    return mul;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
