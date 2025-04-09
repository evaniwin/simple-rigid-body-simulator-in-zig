const std = @import("std");
const math = std.math;
const phy = @import("physics.zig");
const graphics = @import("graphics.zig");
const thread = std.Thread;
pub var running: bool = true;
pub var pointlistptrread: *std.ArrayList([2]f32) = undefined;
pub var pointlistptrwrite: *std.ArrayList([2]f32) = undefined;
pub var pointlistptrattribute: *std.ArrayList(phy.pointattribute) = undefined;
pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};
///add a new particle to the list
pub fn pointadd(values: [2]f32) !void {
    try pointlistptrread.*.append(values);
    try pointlistptrwrite.*.append(values);
    try pointlistptrattribute.*.append(phy.pointattribute{});
}

///flips the read and write pointer
pub fn flipreadwrite() void {
    const temp: *std.ArrayList([2]f32) = pointlistptrread;
    pointlistptrread = pointlistptrwrite;
    pointlistptrwrite = temp;
}

pub fn main() !void {
    const allocator = gpa.allocator();
    std.log.info("Execution of {s} started\n", .{"main"});
    //initilize memory
    var pointlist_1 = std.ArrayList([2]f32).init(allocator);
    defer pointlist_1.deinit();
    pointlistptrread = &pointlist_1;
    var pointlist_2 = std.ArrayList([2]f32).init(allocator);
    defer pointlist_2.deinit();
    pointlistptrwrite = &pointlist_2;
    var pointlistattribute = std.ArrayList(phy.pointattribute).init(allocator);
    defer pointlistptrattribute.deinit();
    pointlistptrattribute = &pointlistattribute;

    try pointadd([2]f32{ 0.0, 0.0 });

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
