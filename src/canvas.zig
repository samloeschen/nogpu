const std = @import("std");
const Self = @This();
const vm = @import("vectormath.zig");

size: vm.vec2i = undefined,
pixels: []vm.Color32 = undefined,

pub fn create(width: i32, height: i32, allocator: std.mem.Allocator) !Self {
    const pixels = try allocator.alloc(vm.Color32, @intCast(width * height));
    errdefer (allocator.free(pixels));

    for (pixels, 0..) |_, i| {
        pixels[i] = vm.Color32{ 255, 0, 255, 255 };
    }
    return .{
        .pixels = pixels,
        .size = vm.vec2i{ width, height },
    };
}

pub fn pixelToIndex(self: Self, x: i32, y: i32) usize {
    return @intCast(y * self.size[0] + x);
}

pub fn set_pixel(self: Self, x: i32, y: i32, color: vm.Color) void {
    const color32: vm.Color32 = @intFromFloat(color * @as(vm.Color, @splat(255.0)));
    const idx = pixelToIndex(self, x, y);
    self.pixels[idx] = color32;
}

pub fn clear(self: Self, color: vm.Color) void {
    fill_rect(self, 0, 0, self.size[0], self.size[1], color);
}

pub fn fill_rect(self: Self, xmin: i32, ymin: i32, width: i32, height: i32, color: vm.Color) void {
    const x_from: usize = @intCast(xmin);
    const x_to: usize = @intCast(xmin + width);
    const y_from: usize = @intCast(ymin);
    const y_to: usize = @intCast(ymin + height);
    const w: usize = @intCast(self.size[0]);
    const color32: vm.Color32 = @intFromFloat(color * @as(vm.Color, @splat(255.0)));

    for (y_from..y_to) |y| {
        const line = y * w;
        @memset(self.pixels[line + x_from .. line + x_to], color32);
    }
}
