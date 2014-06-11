//
//  BWGLParameter.h
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

#import <Foundation/Foundation.h>
#include "glUtil.h"
@class BWGLShader;
@protocol Logging;


/** This is used by things that are manipulated in a programmatic fashion and then set
    the values. */
@protocol GLVariable
/** Sets the GL variable to this matrix value
    @param varIdx The uniform index to the variable to set
    @param logger An object to log with
 */
- (void) setGLValue: (GLint) varIdx
             logger: (id<Logging>) logger;
@end

/** This manages a parameter mapping, to the specific shader
 */
@interface BWGLParameter : NSObject

/** Initialize
    @param shader    The prgram
    @param fieldName The name of the field too look up
    @param cgl_ctx   The core graphics GL context
 */
- (id)initWithShader: (BWGLShader*) shader
       parameterName: (NSString*)   fieldName
             context: (CGLContextObj) cgl_ctx;


/** Set the variable to a value
    @param value  The value to set it to
    @param logger An object to log with
    @returns 0 on succes, otherwise error
 */
- (int) setValue: (id<GLVariable>) value
          logger: (id<Logging>)    logger;


/** Set the variable to a value
    @param value  The value to set it to
    @param logger An object to log with
    @returns 0 on succes, otherwise error
 */
- (int) setColor: (CGColorRef)     value
          logger: (id<Logging>)    logger;


/** Set the variable to a value
    @param value  The value to set it to
    @param logger An object to log with
    @returns 0 on succes, otherwise error
 */
- (int) setSize: (NSSize)      value
         logger: (id<Logging>) logger;

@end
