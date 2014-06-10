//
//  GLShader.m
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

#include "glUtil.h"
#import "BWGLShader.h"
#import "BWGLVertexArray.h"
#import "glErrorLogging.h"


/** Takes a string or a file and converts it into a C string
 */
char const* toCString(NSObject* obj)
{
    NSError* e=nil;
    if ([obj isKindOfClass:[NSURL class]])
        obj = [NSString stringWithContentsOfFile: [(NSURL*)obj path]
                                        encoding: NSASCIIStringEncoding
                                           error: &e];

    if ([obj isKindOfClass:[NSString class]])
        return [(NSString*)obj UTF8String];
    return NULL;
}

@implementation BWGLShader
{
    /// The array of vertices
    BWGLVertexArray* _vertices;
    /// The array of nodes that depend on the output of some instance of this
    NSMutableArray* destinations;
    BOOL needsValidation;
}
@synthesize prgName;

/** Initializes the shader program
    @param cgl_ctx   The core graphics GL context
    @returns nil on error, otherwise a reference to the object
 */
- (id)init:  (CGLContextObj) _cgl_ctx
{
    if (!(self = [super init]))
        return nil;
    cgl_ctx = _cgl_ctx;
    destinations=[[NSMutableArray alloc] init];
    return self;
}


- (id) initWithVertexShader: (NSObject*) vertexShaderSrc
             fragmentShader: (NSObject*) fragmentShaderSrc
                 withNormal:(BOOL)hasNormal
               withTexcoord:(BOOL)hasTexcoord
                    context:  (CGLContextObj) _cgl_ctx
                     logger: (id<Logging>) logger
{
    if (!(self = [self init:_cgl_ctx]))
        return nil;
    
    // Build Program
    // Create a program object
	prgName = glCreateProgram();

    // Indicate the attribute indicies on which vertex arrays will be
	//  set with glVertexAttribPointer
	//  See buildVAO to see where vertex arrays are actually set
	glBindAttribLocation(prgName, POS_ATTRIB_IDX, "inPosition");
	
	if(hasNormal)
	{
		glBindAttribLocation(prgName, NORMAL_ATTRIB_IDX, "inNormal");
	}
	
	if(hasTexcoord)
	{
		glBindAttribLocation(prgName, TEXCOORD_ATTRIB_IDX, "inTexcoord");
	}
	

	
    // Attach the vertex shader to our program
    if ([self attach: GL_VERTEX_SHADER
              source: toCString(vertexShaderSrc)])
        return nil;
	
	// Attach the fragment shader to our program
    if ([self attach: GL_FRAGMENT_SHADER
              source: toCString(fragmentShaderSrc)])
        return nil;
	
    if ([self link: logger])
        return nil;
    return self;
}


/// This is used when copying the shader
- (id)initWithShaders:(GLuint*) shaders
{
    if (!(self = [self init:cgl_ctx]))
        return nil;
    // Build Program
    // Create a program object
	prgName = glCreateProgram();
    
    // Attach the  shader to our program
	glAttachShader(prgName, shaders[0]);
    // Attach the  shader to our program
	glAttachShader(prgName, shaders[1]);
    
    return self;
}

- (void) dealloc
{
    if (prgName)
        glDeleteProgram(prgName);
    prgName = 0;
}


- (id)copy
{
    GLsizei count=0;
    GLuint shaders[2];
    glGetAttachedShaders(prgName, 2, &count, shaders);
    if (!count)
        return nil;
    BWGLShader* ret = [[BWGLShader alloc] initWithShaders: shaders];
//    ret.texture =self.texture;
    ret.vertices=self.vertices;
    return ret;
}


- (int) link: (id<Logging>) logger
{
    //////////////////////
	// Link the program //
	//////////////////////
	
	glLinkProgram(prgName);
	GLint logLength, status;
	glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar*)malloc(logLength);
		glGetProgramInfoLog(prgName, logLength, &logLength, log);
        [logger logMessage:@"Program link log:\n%s\n", log];
		free(log);
	}
	
	glGetProgramiv(prgName, GL_LINK_STATUS, &status);
	if (status == 0)
	{
		[logger logMessage: @"Failed to link program"];
		return -1;
	}
	
	glUseProgram(prgName);
    
	GLint samplerLoc = glGetUniformLocation(prgName, "diffuseTexture");
	
	// Indicate that the diffuse texture will be bound to texture unit 0
	glUniform1i(samplerLoc, 0);
	
	return LogGLErrors();
}


- (int) attach: (GLenum) shaderType
        source: (char const*) shaderSrc
{
	GLint logLength, status;

    // GL_SHADING_LANGUAGE_VERSION returns the version standard version form
	//  with decimals, but the GLSL version preprocessor directive simply
	//  uses integers (thus 1.10 should 110 and 1.40 should be 140, etc.)
	//  We multiply the floating point number by 100 to get a proper
	//  number for the GLSL preprocessor directive
	GLuint version = 100 * glLanguageVersion;
    
    // Get the size of the version preprocessor string info so we know
	//  how much memory to allocate for our sourceString
	const GLsizei versionStringSize = sizeof("#version 1234\n");
	
    //////////////////////////////////////
	// Specify and compile the Shader   //
	//////////////////////////////////////
    
	// Allocate memory for the source string including the version preprocessor information
	GLchar* sourceString = malloc(strlen(shaderSrc) +1+ versionStringSize+1024);
    if (!sourceString)
        return -1;
	
    // Prepend our vertex shader source string with the supported GLSL version so
	//  the shader will work on ES, Legacy, and OpenGL 3.2 Core Profile contexts
	sprintf(sourceString, "#version %d\n"
                          "#ifdef GL_ES\n"
                          "precision highp float;\n"
                          "#endif\n\n"
                          "#if __VERSION__ >= 140\n"
                          "out vec4      fragColor;\n"
                          "#define gl_fragColor\n"
                          "#define varying in\n"
                          "#else\n"
                          "#define in varying\n"
                          "#endif\n\n%s", version, shaderSrc);

    GLuint shader = glCreateShader(shaderType);

    // Compile the shader
	glShaderSource(shader, 1, (const GLchar **)&(sourceString), NULL);
    glCompileShader(shader);
    free(sourceString);

    // Report any log messages from compilation
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar*)malloc(logLength);
		glGetShaderInfoLog(shader, logLength, &logLength, log);
		NSLog(@"Shader compile log:\n%s\n", log);
		free(log);
	}

    // Check the compile status
	glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
	if (status == 0)
	{
		NSLog(@"Failed to compile shader:\n%s\n", shaderSrc);
		return -1;
	}
    
    // Attach the  shader to our program
	glAttachShader(prgName, shader);
	
	// Delete the shader since it is now attached
	// to the program, which will retain a reference to it
	glDeleteShader(shader);
    
    return 0;
}


- (BWGLVertexArray*) vertices
{
    return _vertices;
}

- (void)setVertices:(BWGLVertexArray *)vertices
{
    _vertices = vertices;
    needsValidation = true;
}


/** Checks that the program and its settings are reasonable.
 */
- (void) validate
{
	GLint logLength, status;
    // Skip validation if validation isn't needed
    if (!needsValidation)
        return false;
    needsValidation = false;

    // todo: validate after the frame buffer is
    glValidateProgram(prgName);
	glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar*)malloc(logLength);
		glGetProgramInfoLog(prgName, logLength, &logLength, log);
		NSLog(@"Program validate log:\n%s\n", log);
		free(log);
	}
	
	
	glGetProgramiv(prgName, GL_VALIDATE_STATUS, &status);
	if (status == 0)
	{
		NSLog(@"Failed to validate program");
	}
}

@end
