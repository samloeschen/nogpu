const std = @import("std");
const vm = @import("vectormath.zig");
const threadsafe = @import("threadsafe.zig");

const JobQueue = threadsafe.Queue(JobContext);

size: @Vector(2, usize) = undefined,
pixels: []vm.Color32 = undefined,
job_queue: JobQueue = undefined,
render_threads: []std.Thread = undefined,
job_arena: std.heap.ArenaAllocator = undefined,

inflight_cond: std.Thread.Condition = {},
inflight_counter: threadsafe.Counter = {},
inflight_mutex: std.Thread.Mutex = {},

const JobFunc: type = *const fn (job_data: *anyopaque, slice: []vm.Color32) void;

const JobContext = struct {
    job_fn: JobFunc,
    data: *anyopaque,
    slice: []vm.Color32,
};

const TestJob = struct {
    color: vm.Color32,
    pub fn execute(self: *@This(), slice: []vm.Color32) void {
        @memset(slice, self.color);
    }
};

fn makeRenderWorker(self: *@This()) void {
    while (true) {
        const job = self.job_queue.pop();
        _ = self.inflight_counter.increment();
        @call(.auto, job.job_fn, .{ job.data, job.slice });

        const prev_value = self.inflight_counter.decrement();
        if (prev_value == 1) {
            self.inflight_cond.signal();
        }
    }
}

pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) !*@This() {
    var inst = try allocator.create(@This());
    inst.size = .{ width, height };
    errdefer (allocator.destroy(inst));

    inst.pixels = try allocator.alloc(vm.Color32, width * height);
    errdefer (allocator.free(inst.pixels));

    const logical_threads = std.Thread.getCpuCount() catch 1;
    inst.render_threads = try allocator.alloc(std.Thread, logical_threads);
    errdefer (allocator.free(inst.render_threads));

    inst.job_queue = try JobQueue.init(allocator);
    inst.job_arena = std.heap.ArenaAllocator.init(allocator);
    for (0..inst.render_threads.len) |i| {
        inst.render_threads[i] = try std.Thread.spawn(.{ .allocator = inst.job_arena.allocator() }, makeRenderWorker, .{inst});
    }

    for (inst.pixels, 0..) |_, i| {
        inst.pixels[i] = vm.Color32{ 255, 0, 255, 255 };
    }

    return inst;
}

pub fn finishJobs(self: *@This()) void {
    self.inflight_mutex.lock();
    while (self.inflight_counter.get() > 0) {
        self.inflight_cond.wait(&self.inflight_mutex);
    }
    self.inflight_mutex.unlock();

    _ = self.job_arena.reset(.retain_capacity);
}

pub fn pixelToIndex(self: *@This(), x: i32, y: i32) usize {
    return @intCast(y * self.size[0] + x);
}

pub fn set_pixel(self: *@This(), x: i32, y: i32, color: vm.Color) void {
    const color32: vm.Color32 = @intFromFloat(color * @as(vm.Color, @splat(255.0)));
    const idx = pixelToIndex(self, x, y);
    self.pixels[idx] = color32;
}

pub fn clear(self: *@This(), color: vm.Color) void {
    fill_rect(self, 0, 0, self.size[0], self.size[1], color);
}

fn chunk_work(self: *@This(), xmin: usize, ymin: usize, width: usize, height: usize, job: anytype) !void {
    // cache the job until we are done drawing
    const T = @TypeOf(job);
    var allocator = self.job_arena.allocator();
    const cached_job = try allocator.create(T);
    errdefer (allocator.free(cached_job));
    cached_job.* = job;

    for (0..height) |y| {
        const line = (y + ymin) * self.size[0];

        const slice = self.pixels[line + xmin .. line + xmin + width];
        self.job_queue.push(.{
            .data = cached_job,
            .job_fn = @as(JobFunc, @ptrCast(&T.execute)),
            .slice = slice,
        });
    }
}

pub fn fill_rect(self: *@This(), xmin: usize, ymin: usize, width: usize, height: usize, color: vm.Color) void {
    // const x_from: usize = @intCast(xmin);
    // const x_to: usize = @intCast(xmin + width);
    // const y_from: usize = @intCast(ymin);
    // const y_to: usize = @intCast(ymin + height);
    // const w: usize = @intCast(self.size[0]);
    // const color32: vm.Color32 = @intFromFloat(color * @as(vm.Color, @splat(255.0)));

    // for (y_from..y_to) |y| {
    //     const line = y * w;
    //     @memset(self.pixels[line + x_from .. line + x_to], color32);
    // }

    self.chunk_work(xmin, ymin, width, height, TestJob{ .color = @intFromFloat(color * @as(vm.Color, @splat(255.0))) }) catch unreachable;
}
