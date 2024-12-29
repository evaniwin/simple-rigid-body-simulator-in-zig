const gl = @import("gl");
const glfw = @import("mach-glfw");
const std = @import("std");
const math = std.math;
const main = @import("main.zig");
const util = @import("utility.zig");
const phy = @import("physics.zig");
const freetype = @cImport({
    @cInclude("freetype2/freetype/freetype.h");
    @cInclude("freetype2/ft2build.h");
});

var ft: freetype.FT_Library = undefined;
var face: freetype.FT_Face = undefined;
var VAO: c_uint = undefined;
var VBO: c_uint = undefined;

pub const charecter = struct {
    Textureid: c_uint, // ID handle of the glyph texture
    size: [2]i32, // Size of glyph
    bearing: [2]i32, // Offset from baseline to left/top of glyph
    Advance: c_uint, // Offset to advance to next glyph

};

pub fn initilizefreetype(charecters: *std.ArrayList(charecter)) !void {
    if (freetype.FT_Init_FreeType(&ft) != 0) {
        std.log.err("Failed to initialize freetype liberary", .{});
        main.running = false;
        return;
    }

    if (freetype.FT_New_Face(ft, "/usr/share/fonts/liberation/LiberationMono-Regular.ttf", 0, &face) != 0) {
        std.log.err("Failed to load freetype face", .{});
        main.running = false;
        return;
    }

    _ = freetype.FT_Set_Pixel_Sizes(face, 0, 48);
    gl.glPixelStorei(gl.GL_UNPACK_ALIGNMENT, 1);
    for (0..128) |i| {
        if (freetype.FT_Load_Char(face, i, freetype.FT_LOAD_RENDER) != 0) {
            std.log.err("Failed to load freetype glyph", .{});
            main.running = false;
            return;
        }
        var texture: c_uint = undefined;
        gl.glGenTextures(@as(c_int, 1), &texture);
        gl.glBindTexture(gl.GL_TEXTURE_2D, texture);
        gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RED, @intCast(face.*.glyph.*.bitmap.width), @intCast(face.*.glyph.*.bitmap.rows), 0, gl.GL_RED, gl.GL_UNSIGNED_BYTE, face.*.glyph.*.bitmap.buffer);

        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR);
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR);

        const chartex: charecter = charecter{
            .Textureid = texture,
            .size = .{ @intCast(face.*.glyph.*.bitmap.width), @intCast(face.*.glyph.*.bitmap.rows) },
            .bearing = .{ face.*.glyph.*.bitmap_left, face.*.glyph.*.bitmap_top },
            .Advance = @intCast(face.*.glyph.*.advance.x),
        };

        try charecters.*.append(chartex);
    }
    gl.glEnable(gl.GL_BLEND);
    gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA);

    //FIXME fix this
    const glGenVertexArrays = gl.glGenVertexArrays;
    const glGenBuffers = gl.glGenBuffers;
    const glBindVertexArray = gl.glBindVertexArray;
    const glBindBuffer = gl.glBindBuffer;
    const glBufferData = gl.glBufferData;
    const glEnableVertexAttribArray = gl.glEnableVertexAttribArray;
    const glVertexAttribPointer = gl.glVertexAttribPointer;

    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glBindVertexArray(VAO);
    glBindBuffer(gl.GL_ARRAY_BUFFER, VBO);
    glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(f32) * 6 * 4, null, gl.GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 4, @sizeOf(f32), gl.GL_FALSE, 4 * @sizeOf(f32), @ptrFromInt(0));
    glBindBuffer(gl.GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

pub fn deinitfreetype() void {
    _ = freetype.FT_Done_Face(face);
    _ = freetype.FT_Done_FreeType(ft);
}

fn drawtext() void {}

fn drawbutton(x: f32, y: f32, width: f32, height: f32) void {
    gl.glBegin(gl.GL_TRIANGLES);
    gl.glVertex2f(x - width, y - height);
    gl.glVertex2f(x + width, y - height);
    gl.glVertex2f(x - width, y + height);
    // |\
    // |  \
    // |_____\
    gl.glVertex2f(x + width, y + height);
    gl.glVertex2f(x + width, y - height);
    gl.glVertex2f(x - width, y + height);
    // \-----|
    //   \   |
    //      \|

    gl.glEnd();
}

pub fn drawui(_: ?*glfw.GLFWwindow) void {
    const bounds: [2]f32 = .{ @floatFromInt(phy.simboundry[0]), @floatFromInt(phy.simboundry[1]) };

    gl.glColor4f(0.5, 0.5, 0.5, 1);
    drawbutton(0, 1, 1, 100 / bounds[1]);

    const mainbuttonaligntop: f32 = 50;
    const button: [2]f32 = [2]f32{ 60, 30 };
    gl.glColor4f(0.6, 0.6, 0.6, 1);
    drawbutton(-1 + (100 / bounds[0]), 1 - mainbuttonaligntop / bounds[1], button[0] / bounds[0], button[1] / bounds[1]);
}
