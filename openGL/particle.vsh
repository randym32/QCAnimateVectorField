
attribute vec4 inPosition;
varying vec2 Position;

void main() 
{
    gl_Position = gl_ModelViewProjectionMatrix * inPosition;
    Position = gl_Position.xy/gl_Position.w+0.5;
}

