const std = @import("std");
const Allocator = std.mem.Allocator;
const tp = @import("thespian");

const Plane = @import("renderer").Plane;
const command = @import("command");
const EventHandler = @import("EventHandler");

const Widget = @import("../Widget.zig");
const Button = @import("../Button.zig");

errors: usize = 0,
warnings: usize = 0,
info: usize = 0,
hints: usize = 0,
buf: [256]u8 = undefined,
rendered: [:0]const u8 = "",

const Self = @This();
const ButtonType = Button.Options(Self).ButtonType;

pub fn create(allocator: Allocator, parent: Plane, event_handler: ?EventHandler, _: ?[]const u8) @import("widget.zig").CreateError!Widget {
    return Button.create_widget(Self, allocator, parent, .{
        .ctx = .{},
        .label = "",
        .on_click = on_click,
        .on_layout = layout,
        .on_render = render,
        .on_receive = receive,
        .on_event = event_handler,
    });
}

fn on_click(_: *Self, _: *ButtonType, _: Widget.Pos) void {
    command.executeName("show_diagnostics", .{}) catch {};
}

pub fn layout(self: *Self, _: *ButtonType) Widget.Layout {
    return .{ .static = self.rendered.len };
}

pub fn render(self: *Self, btn: *ButtonType, theme: *const Widget.Theme) bool {
    const bg_style = if (btn.active) theme.editor_cursor else if (btn.hover) theme.statusbar_hover else theme.statusbar;
    btn.plane.set_base_style(theme.editor);
    btn.plane.erase();
    btn.plane.home();
    btn.plane.set_style(bg_style);
    btn.plane.fill(" ");
    btn.plane.home();
    _ = btn.plane.putstr(self.rendered) catch {};
    return false;
}

fn format(self: *Self) void {
    var fbs = std.io.fixedBufferStream(&self.buf);
    const writer = fbs.writer();
    if (self.errors > 0) std.fmt.format(writer, "  {d}", .{self.errors}) catch {};
    if (self.warnings > 0) std.fmt.format(writer, "  {d}", .{self.warnings}) catch {};
    if (self.info > 0) std.fmt.format(writer, "  {d}", .{self.info}) catch {};
    if (self.hints > 0) std.fmt.format(writer, "  {d}", .{self.hints}) catch {};
    self.rendered = @ptrCast(fbs.getWritten());
    self.buf[self.rendered.len] = 0;
}

pub fn receive(self: *Self, _: *ButtonType, _: tp.pid_ref, m: tp.message) error{Exit}!bool {
    if (try m.match(.{ "E", "diag", tp.extract(&self.errors), tp.extract(&self.warnings), tp.extract(&self.info), tp.extract(&self.hints) }))
        self.format();
    return false;
}
