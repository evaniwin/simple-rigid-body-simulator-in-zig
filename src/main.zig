const std = @import("std");
const math = std.math;
const phy = @import("root.zig");
const graphics = @import("graphics.zig");
const thread = std.Thread;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    std.debug.print("Execution of {s} started\n", .{"main"});
    var particlelist = std.ArrayList(phy.particle).init(allocator);
    defer particlelist.deinit();
    try particlelist.append(phy.particle{});
    try phy.printparticle(particlelist);
    const renderthread = try thread.spawn(.{}, graphics.draw, .{&particlelist});
    thread.join(renderthread);
    const solverthread = try thread.spawn(.{}, phy.solve, .{&particlelist});
    thread.join(solverthread);
}
