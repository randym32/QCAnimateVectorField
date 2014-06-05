/*
     File: glUtil.h
 Abstract: 
 Includes the appropriate OpenGL headers (depending on whether this 
 is built for iOS or OSX) and provides some API utility functions
 
  Version: 1.7
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#ifndef __GL_UTIL_H__
#define __GL_UTIL_H__

//The name of the VertexArrayObject are slightly different in
// OpenGLES, OpenGL Core Profile, and OpenGL Legacy
// The arguments are exactly the same across these APIs however
#if TARGET_OS_IPHONE
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
# define ImageClass           UIImage
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

//#include "glErrorLogging.h"
/// The byte size of the specified size
extern GLsizei GLTypeSize(GLenum type);


#endif // __GL_UTIL_H__

