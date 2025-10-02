const cbor = @import("cbor");
const Writer = @import("std").Io.Writer;

const Buffer = @import("Buffer.zig");
const Cursor = @import("Cursor.zig");

begin: Cursor = Cursor{},
end: Cursor = Cursor{},

const Self = @This();

pub const Style = enum { normal, inclusive };

pub inline fn eql(self: Self, other: Self) bool {
    return self.begin.eql(other.begin) and self.end.eql(other.end);
}

pub fn from_cursor(cursor: *const Cursor) Self {
    return .{ .begin = cursor.*, .end = cursor.* };
}

pub fn from_pos(sel: Self, root: Buffer.Root, metrics: Buffer.Metrics) error{NotFound}!Self {
    return .{
        .begin = .{
            .row = sel.begin.row,
            .col = try root.pos_to_width(sel.begin.row, sel.begin.col, metrics),
        },
        .end = .{
            .row = sel.end.row,
            .col = try root.pos_to_width(sel.end.row, sel.end.col, metrics),
        },
    };
}

pub fn line_from_cursor(cursor: Cursor, root: Buffer.Root, mtrx: Buffer.Metrics) Self {
    var begin = cursor;
    var end = cursor;
    begin.move_begin();
    end.move_end(root, mtrx);
    end.move_right(root, mtrx) catch {};
    return .{ .begin = begin, .end = end };
}

pub fn empty(self: *const Self) bool {
    return self.begin.eql(self.end);
}

pub fn reverse(self: *Self) void {
    const tmp = self.begin;
    self.begin = self.end;
    self.end = tmp;
}

pub inline fn is_reversed(self: *const Self) bool {
    return self.begin.right_of(self.end);
}

pub fn normalize(self: *Self) void {
    if (self.is_reversed()) self.reverse();
}

pub fn write(self: *const Self, writer: *Writer) !void {
    try cbor.writeArrayHeader(writer, 2);
    try self.begin.write(writer);
    try self.end.write(writer);
}

pub fn extract(self: *Self, iter: *[]const u8) !bool {
    var iter2 = iter.*;
    const len = cbor.decodeArrayHeader(&iter2) catch return false;
    if (len != 2) return false;
    if (!try self.begin.extract(&iter2)) return false;
    if (!try self.end.extract(&iter2)) return false;
    iter.* = iter2;
    return true;
}

pub fn nudge_insert(self: *Self, nudge: Self) void {
    self.begin.nudge_insert(nudge);
    self.end.nudge_insert(nudge);
}

pub fn nudge_delete(self: *Self, nudge: Self) bool {
    if (!self.begin.nudge_delete(nudge))
        return false;
    return self.end.nudge_delete(nudge);
}
