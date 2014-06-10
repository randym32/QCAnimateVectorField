
attribute vec4 inPosition;
uniform vec2 inRenderSize;
/// The position in pixel coordinates
varying vec2 Position_coord;

void main() 
{
    gl_Position = gl_ModelViewProjectionMatrix * inPosition;
    Position_coord = (gl_Position.xy/gl_Position.w+1.0)*0.5* inRenderSize;//vec2(2048.0,1024.0);//
//    gl_PointSize future compute on speed?
}

