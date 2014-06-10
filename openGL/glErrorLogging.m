//
//  GLLogging.c
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/26/14.
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

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>
#import "glErrorLogging.h"


/** Maps the OpenGL error to a string
    @param error The error code
    @returns String for the error code
 */
static const char * GetGLErrorString(GLenum error)
{
	switch( error )
	{
		case GL_NO_ERROR     : return "GL_NO_ERROR";
		case GL_INVALID_ENUM : return "GL_INVALID_ENUM";
		case GL_INVALID_VALUE: return "GL_INVALID_VALUE";
		case GL_INVALID_OPERATION: return "GL_INVALID_OPERATION";
#if defined GL_OUT_OF_MEMORY
		case GL_OUT_OF_MEMORY: return "GL_OUT_OF_MEMORY";
		case GL_INVALID_FRAMEBUFFER_OPERATION: return "GL_INVALID_FRAMEBUFFER_OPERATION";
#endif
#if defined GL_STACK_OVERFLOW
		case GL_STACK_OVERFLOW: return "GL_STACK_OVERFLOW";
		case GL_STACK_UNDERFLOW: return "GL_STACK_UNDERFLOW";
		case GL_TABLE_TOO_LARGE: return "GL_TABLE_TOO_LARGE";
#endif
		default: return "(ERROR: Unknown Error Enum)";
	}
}


/** This logs any openGL errors.
    @param logger  An object to log with
    @param cgl_ctx The core graphics context (which openGL context we're working with)
    @param file    The source code file that is doing the checking for errors
    @param line    The line in the source file that is checking for errors
    @returns 0 if no errors, otherwise there were errors
 */
int _LogGLErrors(id<Logging> logger, CGLContextObj cgl_ctx, char const* file, int line)
{
	GLenum err = glGetError();
    int ret = 0;
	while (GL_NO_ERROR != err)
    {
        ret =1;
        [logger logMessage:LogPrefix @"GLError %s set in File:%s Line:%d\n",
              GetGLErrorString(err), file, line];
		err = glGetError();
	}
    return ret;
}



