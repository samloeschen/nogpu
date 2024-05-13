const math = @import("std").math;
pub const vec2 = @Vector(2, f32);
pub const vec2i = @Vector(2, i32);
pub const vec2u: type = @Vector(2, u32);

pub const vec3 = @Vector(3, f32);
pub const vec3i = @Vector(3, i32);
pub const vec4 = @Vector(4, f32);
pub const vec4i = @Vector(4, i32);
pub const Color = vec4;
pub const Color32 = @Vector(4, u8);

pub fn len2(v: anytype) @TypeOf(v[0]) {
    switch (@typeInfo(@TypeOf(v)).Vector.len) {
        inline 2 => {
            return v[0] * v[0] + v[1] * v[1];
        },
        inline 3 => {
            return v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
        },
        inline 4 => {
            return v[0] * v[0] + v[1] * v[1] + v[2] * v[2] + v[3] * v[3];
        },
        else => {
            @compileError("only Vectors with length 2, 3 or 4 are supported!");
        },
    }
}

pub fn dot(a: anytype, b: @TypeOf(a)) @TypeOf(a[0]) {
    switch (@typeInfo(@TypeOf(a)).Vector.len) {
        inline 2 => {
            return a[0] * b[0] + a[1] * b[1];
        },
        inline 3 => {
            return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
        },
        inline 4 => {
            return a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
        },
        else => {
            @compileError("only Vectors with length 2, 3 or 4 are supported!");
        },
    }
}

pub fn lerp(a: anytype, b: @TypeOf(a), t: @TypeOf(a[0])) @TypeOf(a[0]) {
    return math.lerp(a, b, t);
}

pub fn len(v: anytype) @TypeOf(v[0]) {
    return @sqrt(len2(v));
}

pub fn normalized(v: anytype) @TypeOf(v) {
    return v / @as(@TypeOf(v), @splat(len(v)));
}

pub fn mulScalar(v: anytype, s: @TypeOf(v[0])) @TypeOf(v) {
    return v * @as(@TypeOf(v), @splat(s));
}
