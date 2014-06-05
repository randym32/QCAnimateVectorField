//
//  GLLogging.c
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/26/14.
//
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>
#import "glErrorLogging.h"
//#import "glUtil.h"
//#import <Foundation/Foundation.h>


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



