#version 460 core

layout(location = 0) in vec2 aPos;
layout(location = 1) in vec2 aOffset;

uniform mat4 projection;
out vec4 fragColor;

void main() {
   
    fragColor = vec4(1.0,0.0,0.0,1.0);
    vec2 vertpos = vec2(aPos.x*100+aOffset.x,aPos.y*100 + aOffset.y);
    gl_Position = projection * vec4(vertpos,0.0,1.0);
}
