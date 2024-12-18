const std = @import("std");

const data = struct {
    mutex: std.Thread.Mutex = std.Thread.Mutex{},
    que: bool = false,
    reset: bool = false,
    point: usize = 0,
    item: [2]f64 = .{ 0, 0 },
};
pub var packet = data{};
