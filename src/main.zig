const std = @import("std");
const math = std.math;
const phy = @import("physics.zig");
const graphics = @import("graphics.zig");
const thread = std.Thread;
pub var running: bool = true;
pub var pointlistptrread: *std.ArrayList(phy.point) = undefined;
pub var pointlistptrwrite: *std.ArrayList(phy.point) = undefined;
pub var pointlistptrattribute: *std.ArrayList(phy.pointattribute) = undefined;

///add a new particle to the list
pub fn pointadd(values: [2]f64) !void {
    const point: [2]f64 = .{ values[0], values[1] };
    try pointlistptrread.*.append(phy.point{ .position = point });
    try pointlistptrwrite.*.append(phy.point{ .position = point });
    try pointlistptrattribute.*.append(phy.pointattribute{});
}

///flips the read and write pointer
pub fn flipreadwrite() void {
    const temp: *std.ArrayList(phy.point) = pointlistptrread;
    pointlistptrread = pointlistptrwrite;
    pointlistptrwrite = temp;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    std.log.info("Execution of {s} started\n", .{"main"});
    //initilize memory
    var pointlist_1 = std.ArrayList(phy.point).init(allocator);
    defer pointlist_1.deinit();
    pointlistptrread = &pointlist_1;
    var pointlist_2 = std.ArrayList(phy.point).init(allocator);
    defer pointlist_2.deinit();
    pointlistptrwrite = &pointlist_2;
    var pointlistattribute = std.ArrayList(phy.pointattribute).init(allocator);
    defer pointlistptrattribute.deinit();
    pointlistptrattribute = &pointlistattribute;

    try pointadd([2]f64{ 0.0, 0.0 });

    //thread and thread mutex
    var lock = thread.Mutex{};
    const renderthread = try thread.spawn(.{}, graphics.draw, .{&lock});
    defer thread.join(renderthread);
    try std.Thread.setName(renderthread, "renderthread");
    var clock: std.time.Timer = try std.time.Timer.start();
    const solverthread = try thread.spawn(.{}, phy.solve, .{ &lock, &clock });
    defer thread.join(solverthread);
    try std.Thread.setName(solverthread, "solverthread");
}
test flipreadwrite {
    try std.testing.expect(true);
}
