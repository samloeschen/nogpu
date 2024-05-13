const std = @import("std");
const vm = @import("vectormath.zig");
const Canvas = @import("canvas.zig");
const app = @import("main.zig");

const Self = @This();

start_instant: std.time.Instant = undefined,
prev_instant: std.time.Instant = undefined,

pub fn init(self: *Self, app_data: *app.AppData) void {
    self.start_instant = std.time.Instant.now() catch unreachable;
    self.prev_instant = self.start_instant;
    // _ = self;
    _ = app_data;
}

pub fn update(self: *Self, app_data: *app.AppData) void {
    const instant = std.time.Instant.now() catch unreachable;
    const time = instant.since(self.start_instant);
    const delta_time = instant.since(self.prev_instant);
    self.prev_instant = instant;

    const delta_time_secs = @as(f64, @floatFromInt(delta_time)) / @as(f64, @floatFromInt(std.time.ns_per_s));
    const time_secs = @as(f64, @floatFromInt(time)) / @as(f64, @floatFromInt(std.time.ns_per_s));

    var canvas = app_data.window_canvas;
    var timer = std.time.Timer.start() catch unreachable;

    canvas.clear(.{ 0, 0.2, 0.2, 1.0 });

    const w: f32 = @floatFromInt(canvas.size[0]);
    const h: f32 = @floatFromInt(canvas.size[1]);
    const px: i32 = @intFromFloat(w * 0.5 + 100.0 * std.math.sin(time_secs));
    const py: i32 = @intFromFloat(h * 0.5 + 100.0 * std.math.sin(time_secs * 3.0));

    canvas.fill_rect(px, py, 64, 64, .{ 1, 1, 1, 1 });

    const elapsed = timer.read();
    const elapsed_ms = @as(f64, @floatFromInt(elapsed)) / @as(f64, @floatFromInt(std.time.ns_per_ms));

    std.debug.print("drawing took {d} ms \n", .{elapsed_ms});

    _ = delta_time_secs;
    // _ = app_data;
}
