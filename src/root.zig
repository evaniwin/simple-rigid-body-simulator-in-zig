//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const main = @import("main.zig");
const math = std.math;

pub const simstep = 30;

pub const particle = struct {
    position: [2]f32 = [2]f32{ 0.0, 0.0 },
    velocity: [2]f32 = [2]f32{ 0, 0 },
    force: [2]f32 = [2]f32{ 0, 0 },
    radius: f32 = 10,
    drag: f32 = 0.01,
};
fn printarray(list: [2]f32) !void {
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

fn forcecollision(particlelist: *std.ArrayList(particle), ind: usize) void {
    for (particlelist.*.items) |part| {
        const vecx = part.position[0] - particlelist.*.items[ind].position[0];
        const vecy = part.position[1] - particlelist.*.items[ind].position[1];
        const dist = math.sqrt(math.pow(f32, vecx, 2) + math.pow(f32, vecy, 2));
        const radiustoradius = particlelist.*.items[ind].radius + part.radius;
        if (dist < 2 * radiustoradius) {
            particlelist.*.items[ind].force[0] = particlelist.*.items[ind].force[0] + (dist - radiustoradius) * vecx;
            particlelist.*.items[ind].force[1] = particlelist.*.items[ind].force[1] + (dist - radiustoradius) * vecy;
        }
    }
}

fn boundrycollition(particlelist: *std.ArrayList(particle), ind: usize) void {
    const rebound: f32 = 0.2;
    const boundry: f32 = 1 - particlelist.*.items[ind].radius;
    var force: [2]f32 = undefined;
    if (particlelist.*.items[ind].position[0] > boundry) {
        force[0] = -rebound;
        if (particlelist.*.items[ind].velocity[0] > 0) {
            particlelist.*.items[ind].velocity[0] = -particlelist.*.items[ind].velocity[0];
        }
    } else if (particlelist.*.items[ind].position[0] < (-boundry)) {
        force[0] = rebound;
        if (particlelist.*.items[ind].velocity[0] < 0) {
            particlelist.*.items[ind].velocity[0] = -particlelist.*.items[ind].velocity[0];
        }
    }

    if (particlelist.*.items[ind].position[1] > boundry) {
        force[1] = -rebound;
        if (particlelist.*.items[ind].velocity[1] > 0) {
            particlelist.*.items[ind].velocity[1] = -particlelist.*.items[ind].velocity[1];
        }
    } else if (particlelist.*.items[ind].position[1] < (-boundry)) {
        force[1] = rebound;
        if (particlelist.*.items[ind].velocity[1] < 0) {
            particlelist.*.items[ind].velocity[1] = -particlelist.*.items[ind].velocity[1];
        }
    }
}

fn forcedrag(particlelist: *std.ArrayList(particle), ind: usize) void {
    particlelist.*.items[ind].velocity[0] = particlelist.*.items[ind].velocity[0] * particlelist.*.items[ind].drag;
    particlelist.*.items[ind].velocity[1] = particlelist.*.items[ind].velocity[1] * particlelist.*.items[ind].drag;
}

fn velcalc(particlelist: *std.ArrayList(particle), ind: usize) void {
    //converts force to velocity
    particlelist.*.items[ind].velocity[0] = particlelist.*.items[ind].force[0] / simstep;
    particlelist.*.items[ind].velocity[1] = particlelist.*.items[ind].force[1] / simstep;
    //removes force added to velocity
    particlelist.*.items[ind].force[0] = math.clamp((1 - (1 / simstep)) * particlelist.*.items[ind].force[0], -1, 1);
    particlelist.*.items[ind].force[1] = math.clamp((1 - (1 / simstep)) * particlelist.*.items[ind].force[1], -1, 1);
}

pub fn addforce(particlelist: *std.ArrayList(particle), ind: usize, force: [2]f32) void {
    particlelist.*.items[ind].force[0] = particlelist.*.items[ind].force[0] + force[0];
    particlelist.*.items[ind].force[1] = particlelist.*.items[ind].force[1] + force[1];
    try printparticle(particlelist.*);
}

fn motion(particlelist: *std.ArrayList(particle)) void {
    for (0..particlelist.*.items.len) |index| {
        particlelist.*.items[index].position[0] = particlelist.*.items[index].position[0] + particlelist.*.items[index].velocity[0] / simstep;
        particlelist.*.items[index].position[1] = particlelist.*.items[index].position[1] + particlelist.*.items[index].velocity[1] / simstep;
    }
}
//pub fn solve(_: *std.ArrayList(particle), _: *std.Thread.Mutex) void {}
pub fn solve(particlelist: *std.ArrayList(particle), lock: *std.Thread.Mutex) void {
    std.debug.print("Thread started", .{});
    while (main.running) {
        lock.*.lock();
        defer lock.*.unlock();
        for (particlelist.*.items, 0..) |_, i| {
            forcedrag(particlelist, i);
            forcecollision(particlelist, i);
            boundrycollition(particlelist, i);
            velcalc(particlelist, i);
        }
        motion(particlelist);
    }
}

test "basic add functionality" {
    try std.testing.expect(true);
}
