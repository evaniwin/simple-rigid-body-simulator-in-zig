const gl = @import("gl");
const glfw = @import("mach-glfw");
const std = @import("std");
const math = std.math;
const main = @import("main.zig");
const util = @import("utility.zig");
const phy = @import("physics.zig");
const graphics = @import("graphics.zig");
const freetype = @cImport({
    @cInclude("freetype2/freetype/freetype.h");
    @cInclude("freetype2/ft2build.h");
});

var ft: freetype.FT_Library = undefined;
var face: freetype.FT_Face = undefined;
var charecters: [128]charecter = undefined;

pub const charecter = struct {
    Textureid: c_uint, // ID handle of the glyph texture
    size: [2]c_uint, // Size of glyph
    bearing: [2]c_int, // Offset from baseline to left/top of glyph
    Advance: c_long, // Offset to advance to next glyph

};

pub fn initilizefreetype() !void {
    if (freetype.FT_Init_FreeType(&ft) != freetype.FT_Err_Ok) {
        std.log.err("Failed to initialize freetype liberary", .{});
        //main.running = false;
        return;
    }

    if (freetype.FT_New_Face(ft, "/usr/share/fonts/liberation/LiberationMono-Regular.ttf", 0, &face) != freetype.FT_Err_Ok) {
        std.log.err("Failed to load freetype face", .{});
        //main.running = false;
        return;
    }

    _ = freetype.FT_Set_Pixel_Sizes(face, 0, 48);
    gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1);
    for (0..128) |i| {
        if (freetype.FT_Load_Char(face, i, freetype.FT_LOAD_RENDER) != freetype.FT_Err_Ok) {
            std.log.err("Failed to load freetype glyph", .{});
            //main.running = false;
            return;
        }
        var texture: [1]c_uint = undefined;
        gl.GenTextures(1, &texture);
        gl.BindTexture(gl.TEXTURE_2D, texture[0]);

        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, @intCast(face.*.glyph.*.bitmap.width), @intCast(face.*.glyph.*.bitmap.rows), 0, gl.RED, gl.UNSIGNED_BYTE, face.*.glyph.*.bitmap.buffer);
        charecters[i] = charecter{ .Textureid = texture[0], .size = .{ face.*.glyph.*.bitmap.width, face.*.glyph.*.bitmap.rows }, .bearing = .{ face.*.glyph.*.bitmap_left, face.*.glyph.*.bitmap_top }, .Advance = @intCast(face.*.glyph.*.advance.x) };
    }
    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(f32) * 6 * 4, null, gl.DYNAMIC_DRAW);
    gl.VertexAttribPointer(0, 4, @sizeOf(f32), gl.FALSE, 4 * @sizeOf(f32), 0);
    std.log.info("initilized freetype", .{});
}

pub fn deinitfreetype() void {
    _ = freetype.FT_Done_Face(face);
    _ = freetype.FT_Done_FreeType(ft);
}

fn drawtext(shader: *util.Shader, text: []const u8, posconst: [2]f32, scale: f32, colour: [3]f32) void {
    shader.*.use();
    gl.Uniform3f(gl.GetUniformLocation(shader.*.program, "textcolour"), colour[0], colour[1], colour[2]);
    gl.ActiveTexture(gl.TEXTURE0);
    gl.BindVertexArray(graphics.VAO[0]);
    var pos = posconst;

    //iterate through input string
    for (text) |char| {
        const charstruct = charecters[char];
        const poschar: [2]f32 = .{ @as(f32, @floatFromInt(charstruct.bearing[0])) * scale, (@as(f32, @floatFromInt(charstruct.size[1])) - @as(f32, @floatFromInt(charstruct.bearing[1]))) * scale };
        // width and height of charecter
        const sizechar: [2]f32 = .{ @as(f32, @floatFromInt(charstruct.size[0])) * scale, @as(f32, @floatFromInt(charstruct.size[1])) * scale };

        //vertices
        const vertices: [6][4]f32 = .{
            .{ poschar[0], poschar[1] + sizechar[1], 0.0, 0.0 },
            .{ poschar[0], poschar[1], 0.0, 1.0 },
            .{ poschar[0] + sizechar[0], poschar[1], 1.0, 1.0 },

            .{ poschar[0], poschar[1] + sizechar[1], 0.0, 0.0 },
            .{ poschar[0] + sizechar[0], poschar[1], 1.0, 1.0 },
            .{ poschar[0] + sizechar[0], poschar[1] + sizechar[1], 1.0, 0.0 },
        };
        
        std.log.info("verticer{any}", .{vertices});
        // render glyph texture over quad
        gl.BindTexture(gl.TEXTURE_2D, charstruct.Textureid);
        // update content of VBO memory
        gl.BindBuffer(gl.ARRAY_BUFFER, graphics.VBO[0]);
        gl.BufferSubData(gl.ARRAY_BUFFER, 0, @sizeOf(@TypeOf(vertices)), &vertices);
        gl.BindBuffer(gl.ARRAY_BUFFER, 0);
        // render quad
        gl.DrawArrays(gl.TRIANGLES, 0, 6);
        // now advance cursors for next glyph (note that advance is number of 1/64 pixels)
        pos[0] += @as(f32, @floatFromInt(charstruct.Advance >> 6)) * scale; // bitshift by 6 to get value in pixels (2^6 = 64)

    }
    gl.BindVertexArray(graphics.VAO[0]);
    gl.BindTexture(gl.TEXTURE_2D, 0);
}
//TODO
pub fn drawui(_: glfw.Window) void {
    var shader = util.Shader{};
    //compile shader program
    shader.init(util.vertexshadersource, util.fragmentshadersource);

    drawtext(&shader, "This is sample text", .{ 25.0, 25.0 }, 0.1, .{ 0.9, 0.8, 0.2 });
}
