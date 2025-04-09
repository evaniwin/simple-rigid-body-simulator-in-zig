const std = @import("std");
const math = std.math;
const phy = @import("physics.zig");
const main = @import("main.zig");
const util = @import("utility.zig");
const ui = @import("ui.zig");
const glfw = @cImport({
    @cInclude("GLFW/glfw3.h");
});
const gl = @import("gl");
const freetype = @cImport({
    @cInclude("freetype2/freetype/freetype.h");
    @cInclude("freetype2/ft2build.h");
});

var curserpos: [2]f32 = undefined;

fn keycallback(_: ?*glfw.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.c) void {
    _ = scancode;
    _ = mods;
    if ((key == glfw.GLFW_KEY_ESCAPE) and (action == glfw.GLFW_PRESS)) {
        main.running = false;
    }
    const step: f32 = 10.0;
    if (action == glfw.GLFW_PRESS or action == glfw.GLFW_REPEAT) {
        var vect: [2]f32 = .{ 0.0, 0.0 };
        if ((key == glfw.GLFW_KEY_UP)) {
            vect = .{ 0.0, step };
        }
        if ((key == glfw.GLFW_KEY_DOWN)) {
            vect = .{ 0.0, -step };
        }
        if ((key == glfw.GLFW_KEY_RIGHT)) {
            vect = .{ step, 0.0 };
        }
        if ((key == glfw.GLFW_KEY_LEFT)) {
            vect = .{ -step, 0.0 };
        }
        if (key == glfw.GLFW_KEY_HOME) {
            util.packet.mutex.lock();
            util.packet.reset = true;
            util.packet.mutex.unlock();
        }

        if (key == glfw.GLFW_KEY_TAB) {
            try phy.printparticle();
        }
        phy.addforce(0, vect);
    }
}

fn mousebuttoncallback(_: ?*glfw.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.c) void {
    _ = mods;
    if (button == glfw.GLFW_MOUSE_BUTTON_LEFT and action == glfw.GLFW_PRESS) {
        util.packet.mutex.lock();
        util.packet.que = true;
        util.packet.item = curserpos;
        util.packet.mutex.unlock();
    }
}

fn cursorposcallback(_: ?*glfw.GLFWwindow, xpos: f64, ypos: f64) callconv(.c) void {
    curserpos[0] = 2 * @as(f32, @floatCast(xpos)) - phy.simboundry[0];
    curserpos[1] = -(2 * @as(f32, @floatCast(ypos)) - phy.simboundry[1]);
    //std.debug.print("{any}\n", .{curserpos});
}

fn errorcallback(err: c_int, decsription: [*c]const u8) callconv(.c) void {
    std.log.err("glfw error code{d}--{any}", .{ err, decsription });
}

fn windowhandler(window: ?*glfw.GLFWwindow) void {
    if (glfw.glfwWindowShouldClose(window) != 0) {
        std.log.warn("stop condition", .{});
        main.running = false;
    }
}
//opengl viewport update
fn viewportsizeupdate(window: ?*glfw.GLFWwindow) void {
    //opengl viewport update
    var framebuffer: [2]c_int = undefined;
    glfw.glfwGetFramebufferSize(window, &framebuffer[0], &framebuffer[1]);
    phy.simboundry = .{ @floatFromInt(framebuffer[0]), @floatFromInt(framebuffer[1]) };
    gl.Viewport(0, 0, @intFromFloat(phy.simboundry[0]), @intFromFloat(phy.simboundry[1]));
}
//orthographic projection matrix
fn orthographic(left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) [4][4]f32 {
    return .{
        .{ 2.0 / (right - left), 0.0, 0.0, -(right + left) / (right - left) },
        .{ 0.0, 2.0 / (top - bottom), 0.0, -(top + bottom) / (top - bottom) },
        .{ 0.0, 0.0, -2.0 / (far - near), -(far + near) / (far - near) },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };
}
var procs: gl.ProcTable = undefined;
pub var VAO: [16]c_uint = undefined;
pub var VBO: [16]c_uint = undefined;
pub var EBO: [16]c_uint = undefined;

pub fn draw(lock: *std.Thread.Mutex) !void {
    std.log.info("render Thread started\n", .{});
    defer std.log.info("render Thread exited\n", .{});

    if (glfw.glfwInit() == 0) {
        std.log.err("Failed to initialize GLFW", .{});
        main.running = false;
        return;
    }
    defer glfw.glfwTerminate();
    const window = glfw.glfwCreateWindow(@intFromFloat(phy.simboundry[0]), @intFromFloat(phy.simboundry[1]), "Physics Simulator", null, null);
    if (window == null) {
        var err: [*c]const u8 = undefined;
        _ = glfw.glfwGetError(&err);
        std.log.err("Failed to create GLFW window{s}", .{err});
        main.running = false;
        return;
    }
    defer glfw.glfwDestroyWindow(window);

    //set window as opengl drawing context
    glfw.glfwMakeContextCurrent(window);
    defer glfw.glfwMakeContextCurrent(null);
    // Initialize the procedure table.
    if (!procs.init(glfw.glfwGetProcAddress)) {
        std.log.err("Failed to initialize proc", .{});
        main.running = false;
        return;
    }
    // Make the procedure table current on the calling thread.
    gl.makeProcTableCurrent(&procs);
    defer gl.makeProcTableCurrent(null);

    glfw.glfwSwapInterval(1);

    //set various callback functions
    _ = glfw.glfwSetErrorCallback(errorcallback);
    _ = glfw.glfwSetKeyCallback(window, keycallback);
    _ = glfw.glfwSetCursorPosCallback(window, cursorposcallback);
    _ = glfw.glfwSetMouseButtonCallback(window, mousebuttoncallback);

    gl.Enable(gl.CULL_FACE);
    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    //vertex array object
    gl.GenVertexArrays(16, &VAO);
    //vertex buffer object
    gl.GenBuffers(16, &VBO);
    //element buffer object
    gl.GenBuffers(16, &EBO);

    var programtext = util.Shader{};
    try programtext.init(util.vertexshadertext, util.fragmentshadertext);

    var programtri = util.Shader{};
    try programtri.init(util.vertexshadertri, util.fragmentshadertri);

    var programsphere = util.Shader{};
    try programsphere.init(util.vertexshadersphere, util.fragmentshadersphere);
    sphereinit(16);
    ui.initilizefreetype();
    // Main loop
    //gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE);
    while (main.running) {
        // Clear the screen
        gl.ClearColor(0.2, 0.2, 0.3, 1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT);

        // Render the circle
        lock.*.lock();

        updateuniforms(&programtext, &programsphere);
        drawspheres(&programsphere);
        ui.drawtopbar(&programtri, &programtext);
        ui.drawtext(&programtext, "use arrow keys to add force and use left mouse button to add particle", .{ 20.0, 10.0 }, 0.4, .{ 1.0, 1.0, 1.0 });

        lock.*.unlock();

        // Swap buffers and poll events
        glfw.glfwSwapBuffers(window);
        glfw.glfwPollEvents();
        windowhandler(window);
        viewportsizeupdate(window);

        //opengl error report
        var err: gl.@"enum" = 1;
        while (err != gl.NO_ERROR) {
            err = gl.GetError();
            // Process/log the error.
            if (err != gl.NO_ERROR) {
                std.log.err("{any}", .{err});
            }
        }
    }
}
fn updateuniforms(a: *util.Shader, b: *util.Shader) void {
    var projection = orthographic(0.0, phy.simboundry[0], 0.0, phy.simboundry[1], -1.0, 1.0);
    a.*.use();
    gl.UniformMatrix4fv(gl.GetUniformLocation(a.*.program, "projection"), 1, gl.TRUE, &projection[0][0]);
    b.*.use();
    projection = orthographic(-phy.simboundry[0], phy.simboundry[0], -phy.simboundry[1], phy.simboundry[1], -1.0, 1.0);
    gl.UniformMatrix4fv(gl.GetUniformLocation(b.*.program, "projection"), 1, gl.TRUE, &projection[0][0]);
}

///creates an offset array for the sphere
///function should be called before render loop
fn sphereinit(segments: usize) void {
    var offsetarray: [64][2]f32 = undefined;
    offsetarray[0] = .{ 0.0, 0.0 };

    var indices: [128]c_uint = undefined;
    indices[0] = 0;
    for (1..(segments + 2)) |index| {
        const theta = -2.0 * math.pi * (@as(f32, @floatFromInt(index)) / @as(f32, @floatFromInt(segments)));

        const cx = @as(f32, math.sin(theta));
        const cy = @as(f32, math.cos(theta));
        offsetarray[index] = .{ cx, cy };
    }
    for (0..(segments - 1)) |index| {
        //0,1,2, 0,2,3, 0,3,4,0
        indices[(index * 3)] = 0;
        indices[(index * 3) + 1] = @intCast(index + 1);
        indices[(index * 3) + 2] = @intCast(index + 2);
    }
    indices[(segments - 1) * 3] = 0;
    indices[((segments - 1) * 3) + 1] = @intCast(segments);
    indices[((segments - 1) * 3) + 2] = 1;

    gl.BindVertexArray(VAO[0]);
    gl.BindBuffer(gl.ARRAY_BUFFER, VBO[0]);
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO[0]);

    gl.BufferData(gl.ARRAY_BUFFER, @intCast(@sizeOf([2]f32) * (segments + 1)), &offsetarray[0][0], gl.STATIC_DRAW);
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, @sizeOf([2]f32), 0);
    gl.EnableVertexAttribArray(0);
}

fn drawspheres(program: *util.Shader) void {
    gl.BindVertexArray(VAO[0]);
    gl.BindBuffer(gl.ARRAY_BUFFER, VBO[1]);
    gl.BufferData(gl.ARRAY_BUFFER, @intCast(@sizeOf([2]f32) * main.pointlistptrread.*.items.len), &main.pointlistptrread.*.items[0], gl.DYNAMIC_DRAW);
    //gl.BufferData(gl.ARRAY_BUFFER, @sizeOf([2]f32), &curserpos, gl.STATIC_DRAW);
    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, @sizeOf([2]f32), 0);
    gl.EnableVertexAttribArray(1);
    gl.VertexAttribDivisor(1, 1);

    program.*.use();
    gl.DrawElementsInstanced(gl.TRIANGLES, 48, gl.UNSIGNED_INT, @ptrFromInt(0), @intCast(main.pointlistptrread.items.len));
}

test "tester" {
    try std.testing.expect(true);
}
