//
//  glTypesize.c
//  BWAnimateVectorFieldPlugin
//
//  Created by Randall Maas on 6/4/14.
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

#import "glUtil.h"

/** The byte size of the specified size
    @param type  The gl type
    @returns The size, in bytes; 0 if not known
 */
GLsizei GLTypeSize(GLenum type)
{
	switch (type)
    {
        case GL_BYTE          : return sizeof(GLbyte);
        case GL_UNSIGNED_BYTE : return sizeof(GLubyte);
        case GL_SHORT         : return sizeof(GLshort);
        case GL_UNSIGNED_SHORT: return sizeof(GLushort);
		case GL_INT           : return sizeof(GLint);
		case GL_UNSIGNED_INT  : return sizeof(GLuint);
		case GL_FLOAT         : return sizeof(GLfloat);
	}
	return 0;
}