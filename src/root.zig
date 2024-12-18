//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const main = @import("main.zig");
const math = std.math;
const util = @import("utility.zig");
const time = std.time;

pub var simboundry: [2]c_int = [2]c_int{ 1200, 800 };
pub const drag: f64 = 0.0001;
const recoil: f64 = 0.9;

pub const point = struct {
    position: [2]f64 = .{ 0.0, 0.0 },
};

pub const pointattribute = struct {
    velocity: [2]f64 = [2]f64{ 0, 0 },
    force: [2]f64 = [2]f64{ 0.0, 0.0 },
    radius: f64 = 100.0,
};

fn printarray(list: [2]f64) !void {
    for (list) |value| {
        std.debug.print("{}  ", .{value});
    }
    std.debug.print("\n", .{});
}
pub fn printparticle() !void {
    for (0..main.pointlistptrattribute.*.items.len) |i| {
        std.debug.print("----------Particle {}\n", .{i});
        try printarray(main.pointlistptrread.items[i].position);
        try printarray(main.pointlistptrwrite.items[i].position);
        try printarray(main.pointlistptrattribute.items[i].velocity);
        try printarray(main.pointlistptrattribute.items[i].force);
    }
}

///calculates the the collision of particle
fn forcecollision(ind: usize) void {
    var force: [2]f64 = .{ 0, 0 };
    for (0..main.pointlistptrattribute.*.items.len) |i| {
        if (i != ind) {
            //using distance formula calculate distance between two particles
            const vec: [2]f64 = [2]f64{ main.pointlistptrread.*.items[i].position[0] - main.pointlistptrread.*.items[ind].position[0], main.pointlistptrread.*.items[i].position[1] - main.pointlistptrread.*.items[ind].position[1] };
            const dist = math.sqrt(math.pow(f64, vec[0], 2) + math.pow(f64, vec[1], 2));
            //get the sum of the radius of the two particles
            const radiustoradius = main.pointlistptrattribute.*.items[ind].radius + main.pointlistptrattribute.*.items[i].radius;
            //check if boundry of two particles are touching then apply repulsion
            if (dist < radiustoradius) {
                for (0..2) |j| {
                    force[j] = force[j] + math.clamp((radiustoradius - dist), 0.0, dist) * (-vec[j] / dist) * recoil;
                }
            }
            addforce(ind, force);
        }
    }
}

/// 'boundrycollition' Calculates collision with boundry
fn boundrycollition(ind: usize) void {
    //Adust the boundry so when the surface of the sphere touches the boundry collision occours
    const boundary: [2]f64 = [2]f64{ @as(f64, @floatFromInt(simboundry[0])) - main.pointlistptrattribute.*.items[ind].radius, @as(f64, @floatFromInt(simboundry[1])) - main.pointlistptrattribute.*.items[ind].radius };
    var force: [2]f64 = [2]f64{ 0, 0 };
    const pos = main.pointlistptrread.*.items[ind].position;
    //calculates rebound
    for (0..2) |i| {
        if (pos[i] > boundary[i]) {
            force[i] = (boundary[i] - pos[i]) * recoil;
        } else if (pos[i] < -boundary[i]) {
            force[i] = -(boundary[i] + pos[i]) * recoil;
        }
    }
    addforce(ind, force);
}

fn forcedrag(ind: usize, timestep: f64) void {
    if (std.math.isNan(main.pointlistptrattribute.*.items[ind].velocity[0]) or std.math.isNan(main.pointlistptrattribute.*.items[ind].velocity[1])) {
        @panic("nan detected before calc");
    }
    for (0..2) |i| {
        main.pointlistptrattribute.*.items[ind].velocity[i] = main.pointlistptrattribute.*.items[ind].velocity[i] - ((main.pointlistptrattribute.*.items[ind].velocity[i] * timestep) * drag);
    }
    if (std.math.isNan(main.pointlistptrattribute.*.items[ind].velocity[0]) or std.math.isNan(main.pointlistptrattribute.*.items[ind].velocity[1])) {
        std.debug.panic("{any},{any},{any}\n", .{ main.pointlistptrattribute.*.items[ind].velocity, timestep, drag });
    }
}

fn velcalc(ind: usize, timestep: f64) void {
    for (0..2) |i| {
        //converts force to velocity
        main.pointlistptrattribute.*.items[ind].velocity[i] = main.pointlistptrattribute.*.items[ind].velocity[i] + main.pointlistptrattribute.*.items[ind].force[i] * timestep;
        //removes force added to velocity
        main.pointlistptrattribute.*.items[ind].force[i] = 0;
    }
}

pub fn addforce(ind: usize, force: [2]f64) void {
    for (0..2) |i| {
        main.pointlistptrattribute.*.items[ind].force[i] = main.pointlistptrattribute.*.items[ind].force[i] + force[i];
    }
}

fn setzero(ind: usize) void {
    main.pointlistptrread.*.items[ind].position = .{ 0.0, 0.0 };
    main.pointlistptrwrite.*.items[ind].position = .{ 0.0, 0.0 };
    main.pointlistptrattribute.*.items[ind].velocity = .{ 0.0, 0.0 };
    main.pointlistptrattribute.*.items[ind].force = .{ 0.0, 0.0 };
}

fn motion(timestep: f64) void {
    for (0..main.pointlistptrattribute.*.items.len) |index| {
        for (0..2) |i| {
            //main.pointlistptrwrite.*.items[index].position[i] = math.clamp(main.pointlistptrread.*.items[index].position[i] + main.pointlistptrattribute.*.items[index].velocity[i] * timestep, @as(f64, @floatFromInt(-simboundry[i])) + 20.0, @as(f64, @floatFromInt(simboundry[i])) + 20.0);
            main.pointlistptrwrite.*.items[index].position[i] = main.pointlistptrread.*.items[index].position[i] + main.pointlistptrattribute.*.items[index].velocity[i] * timestep;
        }
        forcedrag(index, timestep);
    }
}
fn particlehandler() !void {
    if (util.packet.mutex.tryLock()) {
        if (util.packet.que) {
            util.packet.que = false;
            try main.pointadd(util.packet.item);
        }
        if (util.packet.reset) {
            util.packet.reset = false;
            setzero(util.packet.point);
        }
        util.packet.mutex.unlock();
    }
}
pub fn solve(lock: *std.Thread.Mutex, _: *time.Timer) !void {
    std.log.info("Solver Thread started\n", .{});
    defer std.log.info("Solver Thread exited\n", .{});

    while (main.running) {
        const timestep: f64 = 0.1;
        for (0..main.pointlistptrattribute.*.items.len) |i| {
            forcecollision(i);
            boundrycollition(i);
            velcalc(i, timestep);
            time.sleep(std.time.ns_per_s / 240);
        }
        motion(timestep);
        //std.debug.print("motion\n", .{});
        //try printparticle();

        lock.*.lock();
        try particlehandler();
        main.flipreadwrite();
        lock.*.unlock();
    }
}

test "forcedrag" {
    const allocator = std.testing.allocator;

    var pointlist_1 = std.ArrayList(point).init(allocator);
    defer pointlist_1.deinit();
    main.pointlistptrread = &pointlist_1;

    var pointlist_2 = std.ArrayList(point).init(allocator);
    defer pointlist_2.deinit();
    main.pointlistptrwrite = &pointlist_2;

    var pointlist_attrib = std.ArrayList(pointattribute).init(allocator);
    defer pointlist_attrib.deinit();
    main.pointlistptrattribute = &pointlist_attrib;

    try main.pointadd(.{ 0.0, 0.0 });

    forcedrag(0, 0.000001);
    //test normal state
    var ref = [2]f64{ 0.0, 0.0 };
    try std.testing.expectEqualSlices(f64, &ref, &pointlist_2.items[0].position);
    try std.testing.expectEqualSlices(f64, &ref, &pointlist_attrib.items[0].velocity);
    try std.testing.expectEqualSlices(f64, &ref, &pointlist_attrib.items[0].force);
}

test "boundrycollition" {
    const allocator = std.testing.allocator;

    var pointlist_1 = std.ArrayList(point).init(allocator);
    defer pointlist_1.deinit();
    main.pointlistptrread = &pointlist_1;

    var pointlist_2 = std.ArrayList(point).init(allocator);
    defer pointlist_2.deinit();
    main.pointlistptrwrite = &pointlist_2;

    var pointlist_attrib = std.ArrayList(pointattribute).init(allocator);
    defer pointlist_attrib.deinit();
    main.pointlistptrattribute = &pointlist_attrib;

    try main.pointadd(.{ 0.0, 0.0 });
    //test normal state
    boundrycollition(0);
    var ref = [2]f64{ 0.0, 0.0 };
    try std.testing.expectEqualSlices(f64, &ref, &pointlist_2.items[0].position);
    try std.testing.expectEqualSlices(f64, &ref, &pointlist_attrib.items[0].velocity);
    try std.testing.expectEqualSlices(f64, &ref, &pointlist_attrib.items[0].force);
    //test collision top and right
    pointlist_1.items[0].position = [2]f64{ @as(f64, @floatFromInt(simboundry[0])) - main.pointlistptrattribute.*.items[0].radius + 1.0, @as(f64, @floatFromInt(simboundry[1])) - main.pointlistptrattribute.*.items[0].radius + 1.0 };

    boundrycollition(0);
    ref = [2]f64{ -1.0 * recoil, -1.0 * recoil };
    try std.testing.expectEqualSlices(f64, &ref, &pointlist_attrib.items[0].force);

    //test collision bottom and left
    pointlist_1.items[0].position = [2]f64{ -(@as(f64, @floatFromInt(simboundry[0])) - main.pointlistptrattribute.*.items[0].radius + 1.0), -(@as(f64, @floatFromInt(simboundry[1])) - main.pointlistptrattribute.*.items[0].radius + 1.0) };
    pointlist_attrib.items[0].force = .{ 0.0, 0.0 };
    boundrycollition(0);
    ref = [2]f64{ 1.0 * recoil, 1.0 * recoil };
    try std.testing.expectEqualSlices(f64, &ref, &pointlist_attrib.items[0].force);
}
