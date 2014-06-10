//
//  glLogErrors.h
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/27/14.
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
