//
//  glLogErrors.h
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/27/14.
//
//


/// A protocol used to log messages
@protocol Logging
/** Writes a message to the log
 */
- (void) logMessage:(NSString*)format, ...;
@end


/** This logs any openGL errors.
    @param logger  An object to log with
    @param cgl_ctx The core graphics context (which openGL context we're working with)
    @param file    The source code file that is doing the checking for errors
    @param line    The line in the source file that is checking for errors
    @returns 0 if no errors, otherwise there were errors
 */
extern int _LogGLErrors(id<Logging> logger, CGLContextObj cgl_ctx, char const* file, int line);

/// Log any openGL errors
#define LogGLErrors() _LogGLErrors(logger, cgl_ctx, __FILE__, __LINE__)
