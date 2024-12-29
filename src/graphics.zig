const std = @import("std");
const math = std.math;
const phy = @import("physics.zig");
const main = @import("main.zig");
const util = @import("utility.zig");
//const ui = @import("ui.zig");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const freetype = @cImport({
    @cInclude("freetype2/freetype/freetype.h");
    @cInclude("freetype2/ft2build.h");
});
const segments = 16;
var curserpos: [2]f64 = undefined;

fn keycallback(_: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
    _ = scancode;
    _ = mods;
    if ((key == glfw.Key.escape) and (action == glfw.Action.press)) {
        main.running = false;
    }
    const step: f64 = 1.0;
    if (action == glfw.Action.press) {
        var vect: [2]f64 = .{ 0.0, 0.0 };
        if ((key == glfw.Key.up)) {
            vect = .{ 0.0, step };
        }
        if ((key == glfw.Key.down)) {
            vect = .{ 0.0, -step };
        }
        if ((key == glfw.Key.right)) {
            vect = .{ step, 0.0 };
        }
        if ((key == glfw.Key.left)) {
            vect = .{ -step, 0.0 };
        }
        if (key == glfw.Key.home) {
            util.packet.mutex.lock();
            util.packet.reset = true;
            util.packet.mutex.unlock();
        }
        if (key == glfw.Key.end) {
            util.packet.mutex.lock();
            util.packet.que = true;
            util.packet.item = curserpos;
            util.packet.mutex.unlock();
        }
        if (key == glfw.Key.tab) {
            try phy.printparticle();
        }
        phy.addforce(0, vect);
    }
}

fn cursorposcallback(_: glfw.Window, xpos: f64, ypos: f64) void {
    const converted = [2]f64{ @as(f64, @floatFromInt(phy.simboundry[0])), @as(f64, @floatFromInt(phy.simboundry[1])) };
    curserpos[0] = (2 * xpos) - converted[0];
    curserpos[1] = -((2 * ypos) - converted[1]);
    //std.debug.print("{any}\n", .{curserpos});
}

fn errorcallback(err: glfw.ErrorCode, decsription: [:0]const u8) void {
    std.log.err("glfw error code{any}--{any}", .{ err, decsription });
}

fn trisphere(rawx: f32, rawy: f32, radius: f32, segment: usize) void {
    const boundry: [2]f32 = .{ @floatFromInt(phy.simboundry[0]), @floatFromInt(phy.simboundry[1]) };
    gl.Begin(gl.TRIANGLE_FAN);
    gl.Color3f(1.0, 0, 0);
    gl.Vertex2f(rawx / boundry[0], rawy / boundry[1]);
    gl.Color3f(0.0, 0, 1.0);
    for (0..(segment + 1)) |i| {
        const theta = 2.0 * math.pi * (@as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(segment)));

        const cx = @as(f32, rawx + (radius * math.sin(theta)));
        const cy = @as(f32, rawy + (radius * math.cos(theta)));
        gl.Vertex2f(cx / boundry[0], cy / boundry[1]);
    }
    gl.End();
}

fn windowhandler(window: glfw.Window) void {
    if (glfw.Window.shouldClose(window)) {
        std.log.warn("stop condition", .{});
        main.running = false;
    }
}

var procs: gl.ProcTable = undefined;

pub fn draw(lock: *std.Thread.Mutex) !void {
    std.log.info("render Thread started\n", .{});
    defer std.log.info("render Thread exited\n", .{});

    if (!glfw.init(.{})) {
        std.log.err("Failed to initialize GLFW", .{});
        main.running = false;
        return;
    }

    defer glfw.terminate();
    const window = glfw.Window.create(@intCast(phy.simboundry[0]), @intCast(phy.simboundry[1]), "OpenGL Fixed Function Triangle", null, null, .{ .context_version_major = 3, .context_version_minor = 2, .opengl_profile = .opengl_compat_profile }) orelse {
        std.log.err("Failed to create GLFW window{any}", .{glfw.getErrorString()});
        main.running = false;
        return;
    };
    defer window.destroy();

    //var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //const allocator = gpa.allocator();
    //var charecters = std.ArrayList(ui.charecter).init(allocator);
    //defer charecters.deinit();
    //try ui.initilizefreetype(&charecters);
    //defer ui.deinitfreetype();

    //set window as opengl drawing context
    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);
    // Initialize the procedure table.
    if (!procs.init(glfw.getProcAddress)) {
        std.log.err("Failed to initialize proc", .{});
        main.running = false;
        return;
    }
    // Make the procedure table current on the calling thread.
    gl.makeProcTableCurrent(&procs);
    defer gl.makeProcTableCurrent(null);

    glfw.swapInterval(1);

    //set various callback functions
    glfw.setErrorCallback(errorcallback);
    window.setKeyCallback(keycallback);
    window.setCursorPosCallback(cursorposcallback);

    //opengl viewport
    var framebuffer: glfw.Window.Size = window.getFramebufferSize();
    phy.simboundry = .{ @intCast(framebuffer.width), @intCast(framebuffer.height) };
    //set size of opengl viewport
    gl.Viewport(0, 0, phy.simboundry[0], phy.simboundry[1]);

    // Main loop
    while (main.running) {
        // Clear the screen
        gl.ClearColor(0.0, 0.1, 0.3, 1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT);

        // Render the circle
        lock.*.lock();
        for (0..main.pointlistptrattribute.*.items.len) |i| {
            trisphere(@floatCast(main.pointlistptrread.*.items[i].position[0]), @floatCast(main.pointlistptrread.*.items[i].position[1]), @floatCast(main.pointlistptrattribute.*.items[i].radius), segments);
        }
        //ui.drawui(window);
        trisphere(@floatCast(curserpos[0]), @floatCast(curserpos[1]), 50, 3);

        lock.*.unlock();
        // Swap buffers and poll events
        window.swapBuffers();
        glfw.pollEvents();
        std.time.sleep(10000);
        windowhandler(window);
        framebuffer = window.getFramebufferSize();
        phy.simboundry = .{ @intCast(framebuffer.width), @intCast(framebuffer.height) };
        gl.Viewport(0, 0, phy.simboundry[0], phy.simboundry[1]);
    }
}
test "tester" {
    try std.testing.expect(true);
}
