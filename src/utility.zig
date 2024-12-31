const std = @import("std");
const gl = @import("gl");

const data = struct {
    mutex: std.Thread.Mutex = std.Thread.Mutex{},
    que: bool = false,
    reset: bool = false,
    point: usize = 0,
    item: [2]f32 = .{ 0, 0 },
};
pub var packet = data{};

pub const Shader = struct {
    program: u32 = undefined,
    pub fn init(self: *Shader, vertexshadercode: [:0]const u8, fragmentshadercode: [:0]const u8) void {
        // Load shaders
        const vertexshaderstr: c_uint = loadshader(vertexshadercode, gl.VERTEX_SHADER);
        const fragmentshaderstr: c_uint = loadshader(fragmentshadercode, gl.FRAGMENT_SHADER);
        // Create shader program and link shaders
        self.program = gl.CreateProgram();
        gl.AttachShader(self.program, vertexshaderstr);
        gl.AttachShader(self.program, fragmentshaderstr);
        gl.LinkProgram(self.program);
        // Check for linking errors
        var success: i32 = 0;
        gl.GetProgramiv(self.program, gl.LINK_STATUS, &success);
        if (success == 0) {
            var infoLog = std.mem.zeroes([512]u8);
            gl.GetProgramInfoLog(self.program, 512, null, &infoLog);
            std.debug.print("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{any}\n", .{infoLog});
            return;
        }
        // Clean up individual shaders after linking
        gl.DeleteShader(vertexshaderstr);
        gl.DeleteShader(fragmentshaderstr);
    }

    pub fn use(self: *Shader) void {
        gl.UseProgram(self.program);
    }

    fn loadshader(shadersource: [:0]const u8, shadertype: comptime_int) c_uint {
        const shader: c_uint = gl.CreateShader(shadertype);
        gl.ShaderSource(shader, 1, (&shadersource.ptr)[0..1], (&@as(c_int, @intCast(shadersource.len)))[0..1]);
        gl.CompileShader(shader);

        // Check for compilation errors
        var success: c_int = 0;
        gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success);
        if (success == 0) {
            var infoLog = std.mem.zeroes([512]u8);
            gl.GetShaderInfoLog(shader, 512, null, &infoLog);
            std.debug.print("ERROR::SHADER::COMPILATION_FAILED\n{any}\n", .{infoLog});
            return 0;
        }

        return shader;
    }
};

//load shaders source
pub const vertexshadersource = @embedFile("shader/text.vert");
pub const fragmentshadersource = @embedFile("shader/text.frag");
pub const vertexshadersource2 = @embedFile("shader/tri.vert");
pub const fragmentshadersource2 = @embedFile("shader/tri.frag");
pub const vertexshadersphere = @embedFile("shader/sphere.vert");
pub const fragmentshadersphere = @embedFile("shader/sphere.frag");
