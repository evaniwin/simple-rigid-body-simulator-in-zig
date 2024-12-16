//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const main = @import("main.zig");
const math = std.math;
const time = std.time;

pub var simboundry: [2]c_int = [2]c_int{ 800, 1280 };
pub const drag: f64 = 0.0001;
const recoil: f64 = 0.9;

pub const point = struct {
    position: [2]f64 = .{ 0, 0 },
};

pub const pointattribute = struct {
    velocity: [2]f64 = [2]f64{ 0, 0 },
    force: [2]f64 = [2]f64{ 0, 0 },
    radius: f64 = 0.1,
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
    for (main.pointlistptrread.*.items, 0..) |_, i| {
        //using distance formula calculate distance between two particles
        const vec: [2]f64 = [2]f64{ main.pointlistptrread.*.items[i].position[0] - main.pointlistptrread.*.items[ind].position[0], main.pointlistptrread.*.items[i].position[1] - main.pointlistptrread.*.items[ind].position[1] };
        const dist = math.sqrt(math.pow(f64, vec[0], 2) + math.pow(f64, vec[1], 2));
        //get the sum of the radius of the two particles
        const radiustoradius = main.pointlistptrattribute.*.items[ind].radius + main.pointlistptrattribute.*.items[i].radius;
        //check if boundry of two particles are touching then apply repulsion
        if (dist < radiustoradius) {
            for (0..2) |j| {
                main.pointlistptrattribute.*.items[ind].force[j] = main.pointlistptrattribute.*.items[ind].force[j] + (dist - radiustoradius) * vec[j];
            }
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
    for (0..2) |i| {
        main.pointlistptrattribute.*.items[ind].velocity[i] = main.pointlistptrattribute.*.items[ind].velocity[i] - ((main.pointlistptrattribute.*.items[ind].velocity[i] * timestep) * drag);
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

fn motion(timestep: f64) void {
    for (0..main.pointlistptrattribute.*.items.len) |index| {
        for (0..2) |i| {
            //main.pointlistptrwrite.*.items[index].position[i] = math.clamp(main.pointlistptrread.*.items[index].position[i] + main.pointlistptrattribute.*.items[index].velocity[i] * timestep, @as(f64, @floatFromInt(-simboundry[i])) + 20.0, @as(f64, @floatFromInt(simboundry[i])) + 20.0);
            main.pointlistptrwrite.*.items[index].position[i] = main.pointlistptrread.*.items[index].position[i] + main.pointlistptrattribute.*.items[index].velocity[i] * timestep;
        }
        forcedrag(index, timestep);
    }
}
pub fn solve(lock: *std.Thread.Mutex, _: *time.Timer) void {
    std.debug.print("Thread started\n", .{});
    while (main.running) {
        const timestep: f64 = 1.0 / 1.0;
        for (main.pointlistptrread.*.items, 0..) |_, i| {
            forcecollision(i);
            boundrycollition(
                i,
            );
            velcalc(i, timestep);
            time.sleep(std.time.ns_per_s / 240);
        }
        motion(timestep);
        //std.debug.print("motion\n", .{});
        //try printparticle();

        lock.*.lock();
        main.flipreadwrite();
        lock.*.unlock();
    }
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

    try main.pointadd(.{ 0, 0 });
    //test normal state
    boundrycollition(0);
    var ref = [2]f64{ 0.0, 0.0 };
    try std.testing.expect(std.mem.eql(f64, &pointlist_2.items[0].position, &ref));
    try std.testing.expect(std.mem.eql(f64, &pointlist_attrib.items[0].velocity, &ref));
    try std.testing.expect(std.mem.eql(f64, &pointlist_attrib.items[0].force, &ref));

    //test collision top and right
    pointlist_1.items[0].position = [2]f64{ @as(f64, @floatFromInt(simboundry[0] + 1)) - pointlist_attrib.items[0].radius, @as(f64, @floatFromInt(simboundry[1] + 1)) - pointlist_attrib.items[0].radius };

    boundrycollition(0);
    ref = [2]f64{ -1.0 / recoil, -1.0 / recoil };
    try std.testing.expectEqualSlices(f64, &ref, &pointlist_attrib.items[0].force);

    //test collision bottom and left
    pointlist_1.items[0].position = [2]f64{ -@as(f64, @floatFromInt(simboundry[0] + 1)) + pointlist_attrib.items[0].radius, -@as(f64, @floatFromInt(simboundry[1] + 1)) + pointlist_attrib.items[0].radius };
    pointlist_attrib.items[0].force = .{ 0.0, 0.0 };
    boundrycollition(0);
    ref = [2]f64{ 1.0 / recoil, 1.0 / recoil };
    try std.testing.expectEqualSlices(f64, &ref, &pointlist_attrib.items[0].force);
}
