const std = @import("std");

pub fn Queue(comptime T: type) type {
    return struct {
        mutex: std.Thread.Mutex = .{},
        pop_cond: std.Thread.Condition = .{},
        items: std.ArrayList(T) = undefined,

        pub fn init(allocator: std.mem.Allocator) !@This() {
            return .{
                .mutex = std.Thread.Mutex{},
                .pop_cond = std.Thread.Condition{},
                .items = try std.ArrayList(T).initCapacity(allocator, 1024),
            };
        }

        pub fn push(self: *@This(), item: T) void {
            self.mutex.lock();
            defer (self.mutex.unlock());

            self.items.insert(0, item) catch unreachable;
            self.pop_cond.signal();
        }

        pub fn pop(self: *@This()) T {
            self.mutex.lock();
            defer (self.mutex.unlock());

            while (self.items.items.len == 0) {
                self.pop_cond.wait(&self.mutex);
            }
            return self.items.pop();
        }

        pub fn getCount(self: *@This()) usize {
            self.mutex.lock();
            defer (self.mutex.unlock());

            return self.items.items.len;
        }
    };
}

pub fn Atomic(comptime T: type) type {
    return struct {
        value: T,
        mutex: std.Thread.Mutex = {},

        pub fn get(self: *@This()) T {
            self.mutex.lock();
            defer self.mutex.unlock();

            return self.value;
        }

        pub fn set(self: *@This(), new_value: T) void {
            self.mutex.lock();
            defer self.mutex.unlock();

            self.value = new_value;
        }
    };
}

pub const Counter = struct {
    value: usize = 0,
    mutex: std.Thread.Mutex = {},

    pub fn increment(self: *@This()) usize {
        self.mutex.lock();
        defer self.mutex.unlock();
        const prev_value = self.value;
        self.value += 1;

        return prev_value;
    }

    pub fn decrement(self: *@This()) usize {
        self.mutex.lock();
        defer self.mutex.unlock();

        const prev_value = self.value;
        if (self.value > 0) {
            self.value -= 1;
        }
        return prev_value;
    }

    pub fn reset(self: *@This()) usize {
        self.mutex.lock();
        defer self.mutex.unlock();

        const prev_value = self.value;
        self.value = 0;
        return prev_value;
    }

    pub fn get(self: *@This()) usize {
        self.mutex.lock();
        defer self.mutex.unlock();

        return self.value;
    }
};
