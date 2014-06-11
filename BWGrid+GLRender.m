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
#import "glErrorLogging.h"
#import "BWGLVertexArray.h"
#import "BWGLVertexBuffer.h"
#import "BWGLParameter.h"

#define _max(a,b) (a>b?b:a)

@implementation BWGrid (GLRender)

/** This loads the shader program for the particle shader
    @param logger  The object to log with
 */
- (void) loadShaders: (id<Logging>)   logger
{
    glFeatures(cgl_ctx);
    // Get the shaders
    NSBundle* bundle =[NSBundle bundleForClass:[self class]];
    NSURL* vertexURL = [NSURL fileURLWithPath:[bundle pathForResource:@"particle"
                                                               ofType:@"vsh"]];
	NSURL* fragmentURL = [NSURL fileURLWithPath:[bundle pathForResource:@"particle"
                                                                 ofType:@"fsh"]];
    // Build the shader
    shader = [[BWGLShader alloc] initWithVertexShader: vertexURL
                                       fragmentShader: fragmentURL
                                           withNormal: NO
                                         withTexcoord: NO
                                              context: cgl_ctx
                                               logger: logger];
    // Look up the color input variable
    shaderColor =  [shader variableReference:@"inColor1"];
    // Look up the render size variable
    shaderRenderSize =  [shader variableReference:@"inRenderSize"];
}


/** Set the color for the particles
    @param color The color to use for drawing the particles
    @param logger  The object to log with
 */
- (void) setColor: (CGColorRef) color
           logger: (id<Logging>) logger
{
    [shaderColor setColor: color
                   logger: logger];
}


/** Stroke each of the particle motions
    @param logger  The object to log with
 
    Note: I'm not sure that this is actually using the texture
 */
- (void) drawParticles: (id<Logging>) logger
{
    GLint saveName;
    GLint saveViewport[4];
    GLint  saveMode;
    if (!_numParticles)
    {
#if EXTRA_LOGGING_EN
        [logger logMessage:@"No particles"];
#endif
        return;
    }

    
    /* Setup OpenGL states */
    glGetIntegerv(GL_VIEWPORT, saveViewport);
    glViewport(0, 0, self.numXBins, self.numYBins);
#if SCISSOR_EN > 0
    // Enable clipping (aka scissor)
    glEnable(GL_SCISSOR_TEST);
    glScissor(0, 0, self.numXBins, self.numYBins);
#endif
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

    //  now draw lines
    glEnable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.0f);
    glBlendFunc(GL_SRC_ALPHA, GL_DST_ALPHA);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND);
//    glEnable(GL_PROGRAM_POINT_SIZE_EXT);
//    glPointSize(POINT_SIZE);
    glLineWidth(LINE_WIDTH);

    // Run the shader on the particle vertices
    [shader evaluate:logger];
    // Check for errors to make sure all of our setup went ok
    LogGLErrors();

    glDisable(GL_BLEND);
    glDisable(GL_ALPHA_TEST);


    /* Restore OpenGL states */
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(saveMode);
#if SCISSOR_EN > 0
    glDisable(GL_SCISSOR_TEST);
#endif
    glViewport(saveViewport[0], saveViewport[1], saveViewport[2], saveViewport[3]);
}

/** Draw the scene
    @param logger  The object to log with
 */
- (GLuint) draw: (id<Logging>) logger
{
    GLuint texType;
    GLuint texName = 0;      // This texture that will be passed to Quartz Composer
    // Create an OpenGL texture that we will pass to Quartz Composer.
    // We will also render to this
    glGenTextures(1, &texName);

    // We'll use texture rectangles
    // Uses GL_TEXTURE_RECTANGLE_EXT since the rectangles may be non power of two
    texType = GL_TEXTURE_RECTANGLE_EXT;
    glEnable(GL_TEXTURE_RECTANGLE_EXT);
	glBindTexture(texType, texName);
    LogGLErrors();

    // The tutorial says we need filtering
    glTexParameteri(texType, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(texType, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(texType, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(texType, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    // Define the size and initial contents of the texture buffer.
    glTexImage2D(texType, 0, GL_RGBA8, self.numXBins, self.numYBins, 0,
                 GL_BGRA, GL_UNSIGNED_BYTE, NULL);
    LogGLErrors();
    
    // Configure the frame buffer
    // The texName is color attachment 0
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, texType, texName, 0);
    // Set the list of draw buffers
    GLenum DrawBuffers[1] = {GL_COLOR_ATTACHMENT0_EXT};
    glDrawBuffers(1, DrawBuffers);
    LogGLErrors();

#if EXTRA_LOGGING_EN
    [logger logMessage:LogPrefix @"%s,%d: checking frame buffer status", __FILE__, __LINE__];
#endif
	GLenum status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
    
    // Always check that it is ok
	if(status == GL_FRAMEBUFFER_COMPLETE_EXT)
    {
#if CLEAR_BACKGROUND_EN
        // I'm not sure if this does anything yet
        // Set to transparent
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        // Clear the background
        glClear(GL_COLOR_BUFFER_BIT);
        LogGLErrors();
#endif

        // This might be over kill, but we need to save atleast some of the state .. just not sure which
        // If we don't the rendering of other gradients doesn't come out right
        glPushAttrib(GL_ALL_ATTRIB_BITS);
        [shader validate];
        [self drawParticles: logger];
        glPopAttrib(); // Restore old OpenGL States
    }
    else
    {
        [logger logMessage:LogPrefix @"Frame buffer status: 0x%x", status];
        LogGLErrors();
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
