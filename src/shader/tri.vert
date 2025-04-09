#version 460 core

layout(location = 0) in vec2 aPos;

uniform mat4 projection;
uniform vec4 colour;
out vec4 fragColor;

void main() {
   
    fragColor = colour;

    gl_Position = projection * vec4(aPos,0.0,1.0);
}
