const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const std = @import("std");
const Canvas = @import("canvas.zig");
const vm = @import("vectormath.zig");
const app = @import("main.zig");
const Self = @This();

size: vm.vec2i = undefined,
sdl_renderer_handle: *c.struct_SDL_Renderer = undefined,
sdl_screen_handle: *c.struct_SDL_Window = undefined,

canvas: Canvas = undefined,
canvas_surface: *c.struct_SDL_Surface = undefined,
instant: std.time.Instant = undefined,

pub fn start_sdl() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
}

pub fn quit_sdl() void {
    c.SDL_Quit();
}

pub fn create(width: i32, height: i32, allocator: std.mem.Allocator) !Self {
    const flags = 0;

    const screen_handle = c.SDL_CreateWindow("nogpu", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, width, height, flags) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    const canvas_surface = c.SDL_CreateRGBSurfaceWithFormat(0, width, height, 0, c.SDL_PIXELFORMAT_ARGB8888);

    const renderer_handle = c.SDL_CreateSoftwareRenderer(canvas_surface) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    return .{
        .sdl_renderer_handle = renderer_handle,
        .sdl_screen_handle = screen_handle,
        .size = vm.vec2i{ width, height },
        .canvas = try Canvas.create(width, height, allocator),
        .canvas_surface = canvas_surface,
    };
}

pub fn destroy(self: Self) void {
    c.SDL_DestroyRenderer(self.sdl_renderer_handle);
    c.SDL_DestroyWindow(self.sdl_screen_handle);
}

fn present_canvas(self: Self) void {
    const window_surface = c.SDL_GetWindowSurface(self.sdl_screen_handle);

    const w = @as(usize, @intCast(self.size[0]));
    const h = @as(usize, @intCast(self.size[1]));
    const surface_bytes = @as([*]vm.Color32, @ptrCast(@alignCast(window_surface.*.pixels)));

    _ = c.SDL_LockSurface(self.canvas_surface);

    for (0..h) |y| {
        const line = y * w;
        @memcpy(surface_bytes[line .. line + w], self.canvas.pixels[line .. line + w]);
    }

    _ = c.SDL_UnlockSurface(self.canvas_surface);
    _ = c.SDL_BlitSurface(self.canvas_surface, null, window_surface, null);
    _ = c.SDL_UpdateWindowSurface(self.sdl_screen_handle);
}

pub fn runloop(self: Self, app_context: anytype) void {
    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }

        present_canvas(self);
        app_context.update();

        // c.SDL_RenderPresent(self.sdl_renderer_handle);
        // c.SDL_Delay(16);
    }
}