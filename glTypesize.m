//
//  glTypesize.c
//  BWAnimateVectorFieldPlugin
//
//  Created by Randall Maas on 6/4/14.
//
//

#import "glUtil.h"
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