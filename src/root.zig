//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");

pub const particle = struct {
    position: [2]i32 = [2]i32{ 0, 0 },
    velocity: [2]i32 = [2]i32{ 0, 0 },
    force: [2]i32 = [2]i32{ 0, 0 },
};
fn printarray(list: [2]i32) !void {
    for (list) |value| {
        std.debug.print("{}  ", .{value});
    }
    std.debug.print("\n", .{});
}
pub fn printparticle(particles: std.ArrayList(particle)) !void {
    for (particles.items, 0..) |value, i| {
        std.debug.print("----------Particle {}\n", .{i});
        try printarray(value.position);
        try printarray(value.velocity);
        try printarray(value.force);
    }
}

pub fn solve(_: *std.ArrayList(particle)) void {}

test "basic add functionality" {
    try std.testing.expect(true);
}
