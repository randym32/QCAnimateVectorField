

varying vec2 Position;


void main()
{
    vec2 P = gl_FragCoord.xy/(1024.0*gl_FragCoord.w) - Position.xy;
    float R =P.x*P.x+ P.y*P.y;
	gl_FragColor = vec4(1.0, 0.0, 0.0, 0.2+min(R*1.0,0.8));
}