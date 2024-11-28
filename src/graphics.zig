const std = @import("std");
const phy = @import("root.zig");
const math = std.math;
const gl = @cImport({
    @cInclude("GL/gl.h");
});

const glfw = @cImport({
    @cInclude("GLFW/glfw3.h");
});
fn frame_buffer_size_callback(_: ?*glfw.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    gl.glViewport(0, 0, width, height);
}

fn trisphere(x: f32, y: f32, radius: f32, segment: usize) void {
    gl.glBegin(gl.GL_TRIANGLE_FAN);
    gl.glVertex2f(x, y);
    for (0..(segment + 1)) |i| {
        const theta = 2.0 * math.pi * (@as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(segment)));
        const cx = @as(f32, x + radius * math.sin(theta));
        const cy = @as(f32, y + radius * math.cos(theta));
        gl.glVertex2f(cy, cx);
    }

    gl.glEnd();
}

pub fn draw(_: *std.ArrayList(phy.particle)) void {
    if (glfw.glfwInit() == 0) {
        std.log.err("Failed to initialize GLFW", .{});
        return;
    }
    defer glfw.glfwTerminate();

    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 1);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_ANY_PROFILE);

    const window = glfw.glfwCreateWindow(1280, 800, "OpenGL Fixed Function Triangle", null, null);
    if (window == null) {
        std.log.err("Failed to create GLFW window", .{});
        return;
    }
    defer glfw.glfwDestroyWindow(window);
    //opengl viewport
    var width: c_int = 0;
    var height: c_int = 0;
    glfw.glfwGetFramebufferSize(window, &width, &height);
    gl.glViewport(0, 0, width, height);
    glfw.glfwMakeContextCurrent(window);
    glfw.glfwSwapInterval(1);
    _ = glfw.glfwSetFramebufferSizeCallback(window, &frame_buffer_size_callback);

    // Main loop
    while (glfw.glfwWindowShouldClose(window) == 0) {
        // Clear the screen
        gl.glClearColor(0.2, 0.3, 0.3, 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);

        // Render the triangle
        //gl.glBegin(gl.GL_TRIANGLES);
        trisphere(0.5, 0.5, 0.1, 8);
        //gl.glColor3f(1.0, 0.0, 0.0); // Red
        //gl.glVertex2f(0.0, 0.5); // Top-center
        gl.glEnd();

        // Swap buffers and poll events
        glfw.glfwSwapBuffers(window);
        glfw.glfwPollEvents();
    }
}
