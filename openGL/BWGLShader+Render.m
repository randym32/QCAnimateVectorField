//
//  GLShadedMesh.m
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

#import "BWGLShader.h"
#import "BWGLVertexArray.h"
#import "glUtil.h"
#import "glErrorLogging.h"

@implementation BWGLShader(render)

- (void) setCulling:(GLenum) mode
{
    if (mode)
    {
        // Cull back faces now that we no longer render
        // with an inverted matrix
        glCullFace(mode);
    }
}


/** This is used to evaluate the shader (targeting the current render buffer)
    @param logger    The object to log with
*/

- (void) evaluate: (id<Logging>) logger
{
    // Set up to use the shader.  We do this before as f may set some variables
    glUseProgram(self.prgName);
	LogGLErrors();
   
    [self.vertices draw];
    // Check for errors to make sure all of our setup went ok
    LogGLErrors();
}
@end
