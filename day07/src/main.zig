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

const D7Errors = error{
    DirNotFound,
};

const File = struct {
    name: Str,
    size: usize,
};

const Dir = struct {
    name: Str,
    dirs: StringHashMap(Dir),
    files: StringHashMap(File),
    parent: ?*Dir,

    fn init(name: Str, parent: ?*Dir) Dir {
        // We need to store allocator to be idiomatic 🤔
        return Dir{ .name = name, .dirs = StringHashMap(Dir).init(gpa), .files = StringHashMap(File).init(gpa), .parent = parent };
    }

    fn deinit(self: *Dir) void {
        var dir_iter = self.dirs.valueIterator();
        while (dir_iter.next()) |d| {
            d.deinit();
        }
        self.dirs.deinit();
        self.files.deinit();
    }

    fn addFile(self: *Dir, f: File) !void {
        try self.files.put(f.name, f);
    }

    fn addDir(self: *Dir, d: Dir) !void {
        try self.dirs.put(d.name, d);
    }

    fn cd(self: *Dir, name: Str) !*Dir {
        return self.dirs.getPtr(name) orelse return D7Errors.DirNotFound;
    }

    fn calcSize(self: *const Dir) usize {
        var sum: usize = 0;
        var file_iter = self.files.valueIterator();
        while (file_iter.next()) |f| {
            sum += f.size;
        }

        var dir_iter = self.dirs.valueIterator();
        while (dir_iter.next()) |d| {
            sum += d.calcSize();
        }

        return sum;
    }

    fn calcP1(self: *const Dir, sum: *usize) void {
        var self_size = self.calcSize();
        if (self_size <= 100000) {
            sum.* += self_size;
        }

        var dir_iter = self.dirs.valueIterator();
        while (dir_iter.next()) |d| {
            d.calcP1(sum);
        }
    }

    fn findDirAtLeast(self: *const Dir, needed: usize, m: *usize) void {
        var self_size = self.calcSize();
        if (self_size >= needed) {
            m.* = @min(self_size, m.*);
        }

        var dir_iter = self.dirs.valueIterator();
        while (dir_iter.next()) |d| {
            d.findDirAtLeast(needed, m);
        }
    }
};

fn parseFs(text: Str) !Dir {
    var line_iter = mem.split(u8, text, "\n");

    var root = Dir.init("/", null);
    var pwd = &root;

    while (line_iter.next()) |line| {
        var iter = mem.split(u8, line, " ");
        const col = iter.next().?;

        if (mem.eql(u8, col, "$")) {
            const cmd = iter.next().?;
            if (mem.eql(u8, cmd, "ls")) {
                continue;
            } else if (mem.eql(u8, cmd, "cd")) {
                const dirname = iter.next().?;
                if (mem.eql(u8, dirname, "/")) {
                    pwd = &root;
                } else if (mem.eql(u8, dirname, "..")) {
                    pwd = pwd.parent.?;
                } else {
                    pwd = try pwd.cd(dirname);
                }
            } else {
                unreachable;
            }
        } else {
            if (mem.eql(u8, col, "dir")) {
                const dirname = iter.next().?;
                const dir = Dir.init(dirname, pwd);
                try pwd.addDir(dir);
            } else {
                const name = iter.next().?;
                const file = File{ .name = name, .size = try std.fmt.parseInt(usize, col, 10) };
                try pwd.addFile(file);
            }
        }
    }
    return root;
}

fn p1(text: Str) !usize {
    var root = try parseFs(text);
    defer root.deinit();

    var sum: usize = 0;
    root.calcP1(&sum);
    return sum;
}

fn p2(text: Str) !usize {
    var root = try parseFs(text);
    defer root.deinit();

    const space: usize = 70000000;
    const tgt: usize = 30000000;

    const free = space - root.calcSize();
    const needed = tgt - free;

    var m: usize = std.math.maxInt(usize);
    root.findDirAtLeast(needed, &m);
    return m;
}

pub fn main() anyerror!void {
    defer _ = gpa_impl.deinit();
    const text = @embedFile("input");
    const trimmed = std.mem.trim(u8, text, "\n");
    print("Part 1: {}\n", .{try p1(trimmed)});
    print("Part 2: {}\n", .{try p2(trimmed)});
}
