//
//  BWGLParameter.m
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

#import "BWGLParameter.h"
#include "glUtil.h"
#import "BWGLShader.h"
#import "glErrorLogging.h"

@implementation BWGLParameter
{
    /// The core graphics GL context
    CGLContextObj cgl_ctx;

    /// The shader program that
    BWGLShader* _shader;

    /// The gl variable index, relative to the program
    GLint uniformIdx;
}

/** Initialize
    @param shader    The prgram
    @param fieldName The name of the field too look up
 */
- (id)initWithShader: (BWGLShader*) shader
       parameterName: (NSString*)   fieldName
             context:  (CGLContextObj) _cgl_ctx
{
    // Call the parent initializer
    if (!(self = [super init]))
        return nil;
    
    cgl_ctx = _cgl_ctx;
    // The processor
    _shader = shader;

    // Look up the variable/field/parameter by name
    uniformIdx = glGetUniformLocation(_shader.prgName, [fieldName  UTF8String]);
    if (uniformIdx < 0)
    {
        NSLog(@"%@ not a parameter in shader", fieldName);
        return nil;
    }

    return self;
}


/** Set the variable to a value
    @param value  The value to set it to
    @param logger An object to log with
    @returns 0 on succes, otherwise error
 */
- (int) setValue: (id<GLVariable>) value
          logger: (id<Logging>) logger
{
    int err;
    // Save the current openGL prgram so that we can switch back to it
    GLint program = 0;
    glGetIntegerv(GL_CURRENT_PROGRAM, &program);
	if ((err = LogGLErrors()))
    {
        // There was a problem getting the current program
        return err;
    }

    // Set up to use the shader, so the parameter can be set
    if (program != _shader.prgName)
    {
        glUseProgram(_shader.prgName);
        LogGLErrors();
    }
    
    // Have the value set itself
    [value setGLValue: uniformIdx
               logger: logger];
    

    // Restore the previous program
    if (program != _shader.prgName)
    {
        glUseProgram(program);
        return LogGLErrors();
    }

    // not yet
    // Let the downstream nodes know that something is dirty
//    [_shader dependenciesChanged];

    // No error
    return 0;
}



/** Set the variable to a value
    @param value  The color to set it to
    @param logger An object to log with
    @returns 0 on succes, otherwise error
 */
- (int) setColor: (CGColorRef) value
          logger: (id<Logging>) logger
{
    int err;
    // Save the current openGL prgram so that we can switch back to it
    GLint program = 0;
    glGetIntegerv(GL_CURRENT_PROGRAM, &program);
	if ((err = LogGLErrors()))
    {
        // There was a problem getting the current program
        return err;
    }

    // Set up to use the shader, so the parameter can be set
    if (program != _shader.prgName)
    {
        glUseProgram(_shader.prgName);
        LogGLErrors();
    }
    
    // Set the color
    CGFloat const* c = CGColorGetComponents(value);
    glUniform4f(uniformIdx, c[0], c[1], c[2], c[3]);
    LogGLErrors();


    // Restore the previous program
    if (program != _shader.prgName)
    {
        glUseProgram(program);
        return LogGLErrors();
    }

    // not yet
    // Let the downstream nodes know that something is dirty
//    [_shader dependenciesChanged];

    // No error
    return 0;
}




/** Set the variable to a value
    @param value  The color to set it to
    @param logger An object to log with
    @returns 0 on succes, otherwise error
 */
- (int) setSize: (NSSize) value
          logger: (id<Logging>) logger
{
    int err;
    // Save the current openGL prgram so that we can switch back to it
    GLint program = 0;
    glGetIntegerv(GL_CURRENT_PROGRAM, &program);
	if ((err = LogGLErrors()))
    {
        // There was a problem getting the current program
        return err;
    }

    // Set up to use the shader, so the parameter can be set
    if (program != _shader.prgName)
    {
        glUseProgram(_shader.prgName);
        LogGLErrors();
    }
    
    // Set the size
    glUniform2f(uniformIdx, value.width, value.height);
    LogGLErrors();


    // Restore the previous program
    if (program != _shader.prgName)
    {
        glUseProgram(program);
        return LogGLErrors();
    }

    // not yet
    // Let the downstream nodes know that something is dirty
//    [_shader dependenciesChanged];

    // No error
    return 0;
}


@end


