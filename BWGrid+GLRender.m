/*
    BWGrid+GLRender.m
    Animate Vector Field
    Copyright (c) 2013-2014, Randall Maas
    Created by Randall Maas on 12/30/13.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/


#include <math.h>
#import <Quartz/Quartz.h>
#import <CoreGraphics/CoreGraphics.h>
#import "BWGrid+GLRender.h"
/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#define _max(a,b) (a>b?b:a)

@implementation BWGrid (GLRender)

/** Create a smooth texture (for the line strokes) for the particle
    @param color The color of the line
 */
- (void) createTexture: (CGColorRef)    color
{
    // Get the colors
    const CGFloat* colors = CGColorGetComponents(color);
    int J=0;
    // Create the first row
    for(int I = 0; I < 32; I++)
    {
        double s = sin(I*M_PI/32.0);
        double alpha = (0.35+s*s*8.0)*colors[3];
        if (alpha > 1.0) alpha = 1.0;
        texture[J++] = (uint8_t)(255*colors[0]*alpha);
        texture[J++] = (uint8_t)(255*colors[1]*alpha);
        texture[J++] = (uint8_t)(255*colors[2]*alpha);
        texture[J++] = (uint8_t)(255*alpha);
    }
    // Now copy each row
    for (int I = 1; I < 32; I++, J+= 32)
    {
        memcpy(texture+J, texture, 32*4);
    }
    _colors[0] = colors[0];
    _colors[1] = colors[1];
    _colors[2] = colors[2];
    _colors[3] = colors[3];
    
    // Set up the color tables
    colorMap[0] = colors[0]*0.9;           colorMap[1] = colors[1]*0.9;
    colorMap[2] = colors[2]*0.9;           colorMap[3] = colors[3];
    colorMap[4] = _max(colors[0]*1.2,1.0); colorMap[5] = _max(colors[1]*1.2,1.0);
    colorMap[6] = _max(colors[2]*1.2,1.0); colorMap[7] = colors[3];
    colorMap[8] = _max(colors[0]*1.1,1.0); colorMap[9] = _max(colors[1]*1.1,1.0);
    colorMap[10]= _max(colors[2]*1.1,1.0); colorMap[11]= colors[3];
    colorMap[12]= colors[0]*0.9;           colorMap[13]= colors[1]*0.9;
    colorMap[14]= colors[2]*0.9;           colorMap[15]= colors[3];
    J = 16;
    for (int I = 1; I < _numParticles; I++, J+= 16)
        memcpy(colorMap+J, colorMap, sizeof(float)*16);
}


//  glBegin(GL_LINES);
// Execute is ~ 19000 usec
// Render is ~ 7000 usec
// this takes less power than quads

// This is faster

/** Stroke each of the particle motions
    @param cgl_ctx The open GL context
 
    Note: I'm not sure that this is actually using the texture
 */
- (void) drawParticles: (CGLContextObj) cgl_ctx
{
    // Get the colors
    GLuint theTexture = 0;
    GLint saveName;
    GLint saveViewport[4];
    GLint  saveMode;
    if (!_numParticles)
        return;

    GLenum err = glGetError();
    if (err)
        NSLog(LogPrefix @"gl error 0x%x (line %d)", err, __LINE__);

    /* Setup OpenGL states */
    glGetIntegerv(GL_VIEWPORT, saveViewport);
    glViewport(0, 0, self.numXBins, self.numYBins);
    // Enable clipping (aka scissor)
    glEnable(GL_SCISSOR_TEST);
    glScissor(0, 0, self.numXBins, self.numYBins);
    glGetIntegerv(GL_MATRIX_MODE, &saveMode);

    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(0, self.numXBins,  0, self.numYBins, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();

    // Tell openGL to support our methods
    glDisable(GL_DEPTH_TEST);
//    glShadeModel(GL_FLAT);
    glDisable(GL_LIGHTING);
    glDisable(GL_CULL_FACE);

    glEnable(GL_TEXTURE_2D);
#if 1
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    glPixelStorei(GL_UNPACK_ALIGNMENT,1);

    glGenTextures(1, &theTexture);
    glBindTexture(GL_TEXTURE_2D, theTexture);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 32, 32, 0,
                 GL_BGRA, GL_UNSIGNED_BYTE/*GL_UNSIGNED_INT_8_8_8_8*/, textureMap);
    glGenerateMipmap(GL_TEXTURE_2D);  //Generate num_mipmaps number of mipmaps here.
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
#endif
    
    //  now draw lines
    glEnable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.0f);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND);//
    
    // Vive it the vertices
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2,GL_FLOAT,0, hostVertices);
    err = glGetError();
    if (err)
        NSLog(LogPrefix @"vertex pointer error 0x%x (line %d)", err, __LINE__);
#if 1
    // Attempting a texture map
    glTexCoordPointer(2,GL_FLOAT,0,textureMap);
    err =glGetError();
    if (err)
        NSLog(LogPrefix @"texture pointer error 0x%x",err);
#endif
    glEnableClientState( GL_COLOR_ARRAY );
    glColorPointer(4, GL_FLOAT, 0, colorMap);
    glDrawArrays(GL_QUADS,0,_numParticles*4);
#if 1
    glDeleteTextures(1, &theTexture);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
#endif
    glDisableClientState( GL_COLOR_ARRAY );
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);
    glDisable(GL_ALPHA_TEST);


    /* Restore OpenGL states */
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(saveMode);
    glDisable(GL_SCISSOR_TEST);
    glViewport(saveViewport[0], saveViewport[1], saveViewport[2], saveViewport[3]);
}


/** Draw the scene
 */
- (GLuint) draw: (CGLContextObj) cgl_ctx
{
    GLuint texName = 0;      // This texture that will be passed to Quartz Composer
    // Create an OpenGL texture that we will pass to Quartz Composer.
    // We will also render to this
    glGenTextures(1, &texName);
    // We'll use texture rectangles (TBD)
    // If found that GL_TEXTURE_2D just does not work
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texName);
    GLenum err = glGetError();
    if (err)
        NSLog(LogPrefix @"bind texture error 0x%x (line %d)", err, __LINE__);

    // Define the size and initial contents of the texture buffer.  We are passing in the "background"
    // image as the initial content for the texture
    glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA8, self.numXBins, self.numYBins, 0,
                 GL_BGRA, GL_UNSIGNED_BYTE/*GL_UNSIGNED_INT_8_8_8_8*/, NULL);// background);
    if ((err = glGetError()))
        NSLog(LogPrefix @"texImage2D error 0x%x (line %d)", err, __LINE__);
    
    // The tutorial says we need filtering
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // Configure the frame buffer
    // The texName is color attachment 0
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_RECTANGLE_EXT, texName, 0);
    // Set the list of draw buffers
    GLenum DrawBuffers[1] = {GL_COLOR_ATTACHMENT0_EXT};
    glDrawBuffers(1, DrawBuffers);
	GLenum status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
    
    // Always check that it is ok
	if(status == GL_FRAMEBUFFER_COMPLETE_EXT)
    {
#if 0
        // I'm not sure if this does anything yet
        if (1 || !background)
        {
            // Set to transparent
            glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
            // Clear the background
            glClear(GL_COLOR_BUFFER_BIT);
            if ((err = glGetError()))
                NSLog(LogPrefix @"glClear error 0x%x (line %d)", err, __LINE__);
        }
#endif

        // This might be over kill, but we need to save atleast some of the state .. just not sure which
        // If we don't the rendering of other gradients doesn't come out right
        glPushAttrib(GL_ALL_ATTRIB_BITS);
        [self drawParticles: cgl_ctx ];
        glPopAttrib(); // Restore old OpenGL States
    }
    else
    {
        //When you're done using the texture, delete it. This will set texname to 0 and
        //delete all of the graphics card memory associated with the texture. If you
        //don't call this method, the texture will stay in graphics card memory until you
        //close the application.
        glDeleteTextures(1, &texName);
        texName = 0;
    }
    return texName;
}
@end
