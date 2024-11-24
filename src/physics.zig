const std = @import("std");
const main = @import("main.zig");

pub const particle = struct { position: [2]i32 = .{ 0, 0 }, velocity: [2]i32 = .{ 0, 0 }, force: [2]i32 = .{ 0, 0 } };

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

fn printarray(list: []i32) void {
    for (list) |value| {
        std.debug.print("{d}", .{value});
    }
}

pub fn printpoints(points: []particle, len: i32) void {
    for (0..len) |i| {
        std.debug.print("----------------------point {d}", .{i});
        printarray(points[i].position);
        printarray(points[i].velocity);
        printarray(points[i].force);
        std.debug.print("----------------------");
    }
}

//pub fn initilizearray(*particlelist: particle) void{

//}
