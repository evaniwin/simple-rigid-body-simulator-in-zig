#version 460 core

layout(location = 0) in vec2 aPos;
layout(location = 1) in vec2 aOffset;

uniform vec2 screen;
out vec4 fragColor;

void main() {
   
    fragColor = vec4(1.0,0.0,0.0,1.0);
    vec2 vertpos = vec2((aPos.x*100+aOffset.x)*(1/screen.x),(aPos.y*100 + aOffset.y)*(1/screen.y));
    gl_Position = vec4(vertpos,0.0,1.0);
}
