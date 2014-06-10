/*
     File: glUtil.h
     Includes the appropriate OpenGL headers (depending on whether
      built for iOS or OSX)
 */
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


#ifndef __GL_UTIL_H__
#define __GL_UTIL_H__

//The name of the VertexArrayObject are slightly different in
// OpenGLES, OpenGL Core Profile, and OpenGL Legacy
// The arguments are exactly the same across these APIs however
#if TARGET_OS_IPHONE
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
# define glBindVertexArray    glBindVertexArrayOES
# define glGenVertexArrays    glGenVertexArraysOES
# define glDeleteVertexArrays glDeleteVertexArraysOES
#else
// Mac OS X
#import <OpenGL/OpenGL.h>
#import <OpenGL/glext.h>
# define ImageClass           NSImage

// OpenGL 3.2 is only supported on MacOS X Lion and later
// CGL_VERSION_1_3 is defined as 1 on MacOS X Lion and later
// We only use it we're not in a quartz environment
#if (CGL_VERSION_1_3) && !defined(__gl_h_)
# import <OpenGL/gl3.h>
# define glBindVertexArray    glBindVertexArray
# define glGenVertexArrays    glGenVertexArrays
# define glGenerateMipmap     glGenerateMipmap
# define glDeleteVertexArrays glDeleteVertexArrays
#else
# import <OpenGL/gl.h>
/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

# define glBindVertexArray    glBindVertexArrayAPPLE
# define glGenVertexArrays    glGenVertexArraysAPPLE
#ifndef glGenerateMipmap
# define glGenerateMipmap     glGenerateMipmapEXT
#endif
# define glDeleteVertexArrays glDeleteVertexArraysAPPLE
#endif

#endif

// This is the set of openGL features that can used or have other info
#define GL_MIPMAP_PRESENT (2)
#define GL_MIPMAP_SLOW    (4)
#define GL_SINGLE_COLOR_ATTACHMENT (8)

// Figure out the OpenGL features we can use
extern unsigned glFeatures(CGLContextObj cgl_ctx);

/// The scanned version of the openGL version
extern float  glLanguageVersion;


/** The byte size of the specified size
    @param type  The gl type
    @returns The size, in bytes; 0 if not known
 */
extern GLsizei GLTypeSize(GLenum type);


#endif // __GL_UTIL_H__

