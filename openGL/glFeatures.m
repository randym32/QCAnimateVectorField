//
//  GLMisc.m
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/24/14.
//
//
#import "glUtil.h"

//
#define Inited (1)

// Figure out the OpenGL features we can use
static unsigned _glFeatures = 0;


// Determine if GLSL version 140 is supported by this context.
//  We'll use this info to generate a GLSL shader source string
//  with the proper version preprocessor string prepended
float  glLanguageVersion;

static void ScanGLVersion (char const* glVersion)
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

static void ProbeGLFeatures(CGLContextObj cgl_ctx)
{
    // Scan the version to see if there are features that we shouldn't use
    ScanGLVersion((char const*)glGetString(GL_SHADING_LANGUAGE_VERSION));

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


    // Get ther OpenGL renderer name, and see if there are features that we shouldn't use
    //    NSLog(@"%s %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));
    const char *renderer = (const char *)glGetString(GL_RENDERER);
    
    if (!renderer)
        return;

    // Is this a AMD D300 renderer?
    const char *isD300 = strstr(renderer, "D300");
        
    // Is this a AMD D500 renderer?
    const char *isD500 = strstr(renderer, "D500");
        
    // Is this a AMD D700 renderer?
    const char *isD700 = strstr(renderer, "D700");
        
    // Is this one of the AMD renderers?
    BOOL isAMD = (isD300) || (isD500) || (isD700);

    // Is this an NVidia renderer?
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
