const std = @import("std");
const math = std.math;
const phy = @import("root.zig");
const main = @import("main.zig");
const glfw = @cImport(@cInclude("GLFW/glfw3.h"));
const vulkan = @cImport(@cInclude("vulkan/vulkan.h"));
const gl = @cImport(@cInclude("GL/gl.h"));

var width: c_int = 1280;
var height: c_int = 800;
const segments = 16;

fn key_callback(window: ?*glfw.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = scancode;
    _ = mods;
    if ((key == glfw.GLFW_KEY_ESCAPE) and (action == glfw.GLFW_PRESS)) {
        glfw.glfwSetWindowShouldClose(window, glfw.GLFW_TRUE);
        main.running = false;
    }
    var vect: [2]f32 = undefined;
    if ((key == glfw.GLFW_KEY_UP) and (action == glfw.GLFW_PRESS)) {
        vect = .{ 0.1, 0.0 };
    }
    if ((key == glfw.GLFW_KEY_DOWN) and (action == glfw.GLFW_PRESS)) {
        vect = .{ -0.1, 0.0 };
    }
    if ((key == glfw.GLFW_KEY_RIGHT) and (action == glfw.GLFW_PRESS)) {
        vect = .{ 0.0, 0.1 };
    }
    if ((key == glfw.GLFW_KEY_LEFT) and (action == glfw.GLFW_PRESS)) {
        vect = .{ 0.0, -0.1 };
    }
    phy.addforce(main.particlelistptr, 0, vect);
}

fn frame_buffer_size_callback(_: ?*glfw.GLFWwindow, widthc: c_int, heightc: c_int) callconv(.C) void {
    gl.glViewport(0, 0, width, height);
    width = widthc;
    height = heightc;
}

fn error_callback(err: c_int, decsription: [*c]const u8) callconv(.C) void {
    std.debug.print("glfw error code{d}--{s}", .{ err, decsription });
}

fn trisphere(x: f32, y: f32, radius: f32, segment: usize) void {
    gl.glBegin(gl.GL_TRIANGLE_FAN);
    gl.glColor3f(1.0, 0, 0);
    gl.glVertex2f(y, x);
    gl.glColor3f(0.0, 0, 1.0);
    const fact: f32 = radius * @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
    for (0..(segment + 1)) |i| {
        const theta = 2.0 * math.pi * (@as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(segment)));

        const cx = @as(f32, x + math.sin(theta) * fact);
        const cy = @as(f32, y + radius * math.cos(theta));
        gl.glVertex2f(cy, cx);
    }

    gl.glEnd();
}

pub fn draw(particlelist: *std.ArrayList(phy.particle), lock: *std.Thread.Mutex) void {
    if (glfw.glfwInit() == 0) {
        std.log.err("Failed to initialize GLFW", .{});
        return;
    }
    defer glfw.glfwTerminate();
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 1);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_ANY_PROFILE);

    const window = glfw.glfwCreateWindow(width, height, "OpenGL Fixed Function Triangle", null, null);
    if (window == null) {
        std.log.err("Failed to create GLFW window", .{});
        return;
    }
    defer glfw.glfwDestroyWindow(window);
    //opengl viewport
    glfw.glfwGetFramebufferSize(window, &width, &height);
    gl.glViewport(0, 0, width, height);
    glfw.glfwMakeContextCurrent(window);
    glfw.glfwSwapInterval(1);
    _ = glfw.glfwSetErrorCallback(error_callback);
    _ = glfw.glfwSetFramebufferSizeCallback(window, &frame_buffer_size_callback);
    _ = glfw.glfwSetKeyCallback(window, &key_callback);
    // Main loop
    while (glfw.glfwWindowShouldClose(window) == 0 and main.running) {
        lock.*.lock();
        defer lock.*.unlock();
        // Clear the screen
        gl.glClearColor(0.0, 0.1, 0.3, 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);

        // Render the circle
        for (particlelist.*.items) |value| {
            trisphere(value.position[0], value.position[1], 0.1, segments);
        }
        gl.glEnd();

        // Swap buffers and poll events
        glfw.glfwSwapBuffers(window);
        glfw.glfwPollEvents();
    }
}
