

/// The position in pixel coordinates
varying vec2 Position_coord;
// todo add in the view size
uniform vec4 inColor1;

const vec4 alphaColor=vec4(0.0);
void main()
{
    //       in pixels                          in pixels
    vec2 P = gl_FragCoord.xy/(gl_FragCoord.w) - Position_coord.xy;
    float R =P.x*P.x+ P.y*P.y;
    
    // Now mix the color
    gl_FragColor = mix(alphaColor, inColor1, clamp((1.0-R/1.0)+R/8.0,0.0,1.0));
}