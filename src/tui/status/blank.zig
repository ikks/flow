const std = @import("std");
const tp = @import("thespian");
const Plane = @import("renderer").Plane;
const EventHandler = @import("EventHandler");

const Widget = @import("../Widget.zig");

plane: Plane,
layout_: Widget.Layout,
on_event: ?EventHandler,

const Self = @This();

pub fn Create(comptime layout_: Widget.Layout) @import("widget.zig").CreateFunction {
    return struct {
        fn create(allocator: std.mem.Allocator, parent: Plane, event_handler: ?EventHandler, arg: ?[]const u8) @import("widget.zig").CreateError!Widget {
            const layout__ = if (layout_ == .static) blk: {
                if (arg) |str_size| {
                    const size = std.fmt.parseInt(usize, str_size, 10) catch break :blk layout_;
                    break :blk Widget.Layout{ .static = size };
                } else break :blk layout_;
            } else layout_;
            const self = try allocator.create(Self);
            errdefer allocator.destroy(self);
            self.* = .{
                .plane = try Plane.init(&(Widget.Box{}).opts(@typeName(Self)), parent),
                .layout_ = layout__,
                .on_event = event_handler,
            };
            return Widget.to(self);
        }
    }.create;
}

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    self.plane.deinit();
    allocator.destroy(self);
}

pub fn layout(self: *Self) Widget.Layout {
    return self.layout_;
}

pub fn render(self: *Self, theme: *const Widget.Theme) bool {
    self.plane.set_base_style(theme.editor);
    self.plane.erase();
    self.plane.home();
    self.plane.set_style(theme.statusbar);
    self.plane.fill(" ");
    return false;
}

pub fn receive(self: *Self, from: tp.pid_ref, m: tp.message) error{Exit}!bool {
    var btn: u32 = 0;
    if (try m.match(.{ "D", tp.any, tp.extract(&btn), tp.more })) {
        if (self.on_event) |h| h.send(from, m) catch {};
        return true;
    }
    return false;
}
