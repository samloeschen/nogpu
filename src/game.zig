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

// const colors: [25]vm.Color = .{
//     vm.Color{ 1.0, 0.388, 0.278, 1.0 }, // Tomato
//     vm.Color{ 0.529, 0.808, 0.98, 1.0 }, // Light Sky Blue
//     vm.Color{ 1.0, 1.0, 0.0, 1.0 }, // Yellow
//     vm.Color{ 0.565, 0.933, 0.565, 1.0 }, // Light Green
//     vm.Color{ 1.0, 0.714, 0.757, 1.0 }, // Light Pink
//     vm.Color{ 1.0, 0.647, 0.0, 1.0 }, // Orange
//     vm.Color{ 0.678, 0.847, 0.902, 1.0 }, // Light Blue
//     vm.Color{ 1.0, 0.412, 0.706, 1.0 }, // Hot Pink
//     vm.Color{ 0.133, 0.545, 0.133, 1.0 }, // Forest Green
//     vm.Color{ 1.0, 0.271, 0.0, 1.0 }, // Red Orange
//     vm.Color{ 0.416, 0.353, 0.804, 1.0 }, // Slate Blue
//     vm.Color{ 0.941, 0.902, 0.549, 1.0 }, // Khaki
//     vm.Color{ 0.498, 1.0, 0.831, 1.0 }, // Aquamarine
//     vm.Color{ 1.0, 0.078, 0.576, 1.0 }, // Deep Pink
//     vm.Color{ 0.251, 0.878, 0.816, 1.0 }, // Turquoise
//     vm.Color{ 0.275, 0.51, 0.706, 1.0 }, // Steel Blue
//     vm.Color{ 1.0, 0.98, 0.804, 1.0 }, // Lemon Chiffon
//     vm.Color{ 0.0, 1.0, 1.0, 1.0 }, // Cyan
//     vm.Color{ 0.855, 0.439, 0.839, 1.0 }, // Orchid
//     vm.Color{ 0.282, 0.239, 0.545, 1.0 }, // Dark Slate Blue
//     vm.Color{ 0.69, 0.878, 0.902, 1.0 }, // Powder Blue
//     vm.Color{ 0.933, 0.51, 0.933, 1.0 }, // Violet
//     vm.Color{ 0.18, 0.545, 0.341, 1.0 }, // Sea Green
//     vm.Color{ 0.627, 0.321, 0.176, 1.0 }, // Sienna
//     vm.Color{ 0.824, 0.412, 0.118, 1.0 }, // Chocolate
// };

fn hsvToRgb(h: f32, s: f32, v: f32) vm.Color {
    const c = v * s;
    const x = c * (1 - @abs(((h / 60.0) % 2 - 1)));
    const m = v - c;
    var r: f32 = 0;
    var g: f32 = 0;
    var b: f32 = 0;

    if (h < 60) {
        r = c;
        g = x;
        b = 0;
    } else if (h < 120) {
        r = x;
        g = c;
        b = 0;
    } else if (h < 180) {
        r = 0;
        g = c;
        b = x;
    } else if (h < 240) {
        r = 0;
        g = x;
        b = c;
    } else if (h < 300) {
        r = x;
        g = 0;
        b = c;
    } else {
        r = c;
        g = 0;
        b = x;
    }

    return vm.Color{
        r + m,
        g + m,
        b + m,
        1.0,
    };
}

const num_colors = 50;

pub const colors: [num_colors]vm.Color = makeColors();

pub fn makeColors() [num_colors]vm.Color {
    var colors_array: [num_colors]vm.Color = undefined;
    var i: usize = 0;
    while (i < num_colors) : (i += 1) {
        const hue = (@as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(num_colors))) * 360.0;
        colors_array[i] = hsvToRgb(hue, 1.0, 1.0);
    }
    return colors_array;
}

pub fn update(self: *Self, app_data: *app.AppData) void {
    const instant = std.time.Instant.now() catch unreachable;
    const time = instant.since(self.start_instant);
    const delta_time = instant.since(self.prev_instant);
    self.prev_instant = instant;

    const delta_time_secs = @as(f64, @floatFromInt(delta_time)) / @as(f64, @floatFromInt(std.time.ns_per_s));
    const time_secs = @as(f64, @floatFromInt(time)) / @as(f64, @floatFromInt(std.time.ns_per_s));

    var canvas = app_data.window_canvas;

    canvas.clear(.{ 0.2, 0.2, 0.2, 1.0 });

    for (0..100) |i| {
        const w: f32 = @floatFromInt(canvas.size[0]);
        const h: f32 = @floatFromInt(canvas.size[1]);

        const offset = @as(f32, @floatFromInt(i));
        const px: usize = @intFromFloat(w * 0.5 + 100.0 * (std.math.sin(time_secs) + offset));
        const py: usize = @intFromFloat(h * 0.5 + 100.0 * (std.math.sin(time_secs * 3.0 + offset)));

        const color = colors[i % colors.len];
        canvas.fill_rect(px, py, 64, 64, color);
    }

    _ = delta_time_secs;
    // _ = app_data;
}
