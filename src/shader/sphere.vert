#version 460 core

layout(location = 0) in vec2 aPos; 


out vec4 fragColor;

void main() {
   
    fragColor = vec4(1.0,0.0,0.0,1.0);
    
   gl_Position = vec4(aPos*0.1,0.0,1.0);
}
