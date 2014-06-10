//
//  GLMisc.m
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/24/14.
/*
    Copyright (c) 2014, Randall Maas

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
#import "glUtil.h"


//
#define Inited (1)

// Figure out the OpenGL features we can use
static unsigned _glFeatures = 0;


// Determine if GLSL version 140 is supported by this context.
//  We'll use this info to generate a GLSL shader source string
//  with the proper version preprocessor string prepended
float  glLanguageVersion;


/** Scan the GL Shading Language Version string
    @param glVersion The gl shading language string
 */
static void ScanShaderVersion (char const* glVersion)
{
    if (!glVersion)
        return;
    // See if we are working with OpenGL ES
    if (!strncasecmp("OpenGL ES", glVersion, 9))
    {
        // glMipmap call is not accelarated on iOS 4 so do not use mipmaps here
        _glFeatures |= GL_MIPMAP_SLOW;
        // OpenGL ES on iOS 4 has only 1 attachment.
        _glFeatures |= GL_SINGLE_COLOR_ATTACHMENT;
    }
    else
        _glFeatures |= GL_MIPMAP_PRESENT;
    
    
    // Get the version
    // Skip until we reach a number
    while (glVersion[0] && !isdigit(glVersion[0]))
        glVersion++;
    // Get the version
	sscanf(glVersion, "%f", &glLanguageVersion);
}


/** Scan the GL framework version
    @param versionStr The gl version string
 */
static void ScanGLVersion (char const* versionStr)
{
    float glVersion= 0;
    if (!versionStr)
        return;
    // Skip until we reach a number
    while (versionStr[0] && !isdigit(versionStr[0]))
    versionStr++;

    // Get the version
	sscanf(versionStr, "%f", &glVersion);
}


static void ProbeGLFeatures(CGLContextObj cgl_ctx)
{
    // Scan the version to see if there are features that we shouldn't use
    ScanShaderVersion((char const*)glGetString(GL_SHADING_LANGUAGE_VERSION));

    // Check to see if we have more than 2 renderers?
    // The first is typically a software renderer and
    // the second is the hardware (GPU) renderer.
    BOOL               isDualGPU = NO;
    GLint              count     = 0;
    CGLRendererInfoObj info      = NULL;
    
    // Get the number of renderers
    CGLError err = CGLQueryRendererInfo(0xFFFFFFFF, &info, &count);
    
    // If the query returned without an error then check
    // renderer count.
    if(err == kCGLNoError)
    {
        // Make certain  that we've more than 2 renderers
        isDualGPU = count > 2;
        
        // Release the renderer infor object data reference
        CGLDestroyRendererInfo(info);
    }
    

    // Get the version
    ScanGLVersion((char const*) glGetString(GL_VERSION));


    // Get ther OpenGL renderer name, and see if there are features that we shouldn't use
    char const* renderer = (const char *)glGetString(GL_RENDERER);
    
    if (!renderer)
        return;

    // Is this a AMD D300 renderer?
    char const* isD300 = strstr(renderer, "D300");
        
    // Is this a AMD D500 renderer?
    char const* isD500 = strstr(renderer, "D500");
        
    // Is this a AMD D700 renderer?
    char  const* isD700 = strstr(renderer, "D700");
        
    // Is this one of the AMD renderers?
    BOOL isAMD = (isD300) || (isD500) || (isD700);

    // Is this an NVidia driver?
    const char* vendor = (const char *)glGetString(GL_VENDOR);
    const char *isNvidia = strstr(renderer, "NVIDIA");
    if (isNvidia)
    {
        // It think that the at the NVidia driver doesn't like Mipmaps.  So disable them
        _glFeatures &= ~(GL_MIPMAP_PRESENT|GL_MIPMAP_SLOW);
    }
}

unsigned glFeatures(CGLContextObj cgl_ctx)
{
    if (_glFeatures)
        return _glFeatures;
    _glFeatures = Inited;
    ProbeGLFeatures(cgl_ctx);
    return _glFeatures;
}
