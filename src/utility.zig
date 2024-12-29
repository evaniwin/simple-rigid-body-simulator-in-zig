const std = @import("std");

const data = struct {
    mutex: std.Thread.Mutex = std.Thread.Mutex{},
    que: bool = false,
    reset: bool = false,
    point: usize = 0,
    item: [2]f64 = .{ 0, 0 },
};
pub var packet = data{};

const shader =
    \\#version 330 core
    \\layout (location = 0) in vec4 vertex; // <vec2 pos, vec2 tex>
    \\out vec2 TexCoords;
    \\
    \\uniform mat4 projection;
    \\
    \\void main()
    \\{
    \\    gl_Position = projection * vec4(vertex.xy, 0.0, 1.0);
    \\    TexCoords = vertex.zw;
    \\}  
;
const shader2 =
    \\#version 330 core
    \\in vec2 TexCoords;
    \\out vec4 color;
    \\
    \\uniform sampler2D text;
    \\uniform vec3 textColor;
    \\
    \\void main()
    \\{    
    \\    vec4 sampled = vec4(1.0, 1.0, 1.0, texture(text, TexCoords).r);
    \\    color = vec4(textColor, 1.0) * sampled;
    \\}  
;
