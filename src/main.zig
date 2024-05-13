const std = @import("std");
const Window = @import("window.zig");
const Game = @import("game.zig");
const Canvas = @import("canvas.zig");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const assert = @import("std").debug.assert;

const WIDTH = 640;
const HEIGHT = 480;

pub const AppData = struct {
    window_canvas: Canvas,
};

pub fn color32tou32(color32: @Vector(4, u8)) u32 {
    return c.SDL_MapRGBA(c.SDL_PIXELFORMAT_RGBA32, color32[0], color32[1], color32[2], color32[3]);
}

pub fn main() !void {
    var app_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    defer app_arena.deinit();
    const allocator = app_arena.allocator();

    try Window.start_sdl();
    defer Window.quit_sdl();

    var window = try Window.create(WIDTH, HEIGHT, allocator);
    defer window.destroy();

    var app_data = AppData{
        .window_canvas = window.canvas,
    };
    var game = Game{};

    const ctx = struct {
        game: *Game,
        app_data: *AppData,
        pub fn update(self: @This()) void {
            self.game.update(self.app_data);
        }
    };

    game.init(&app_data);
    window.runloop(ctx{
        .game = &game,
        .app_data = &app_data,
    });
}
