//
//  GLImage.h
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/22/14.
//
//

#import <Foundation/Foundation.h>
#import "BWFnNode.h"
#import "glUtil.h"

@protocol QCPlugInContext;

/** An open GL image.
    This is a base class to represent images in the processing network.
     It includes the ability to load the conventional JPEG, and PNG files, as well as wrap OpenGL textures.
      rendering spots such as would be coming to use the frame buffer objects him article from chains of filters should use an image slot that will temper that will allocate in release frame buffer resources appropriate
 */
@interface BWGLImage : BWFnNode
{
    /// The underlying bitmap representation
    NSBitmapImageRep* bitmapRepresentation;
    // Our working bitmap data
    void* bitmapData ;

    unsigned rowByteSize;

    /// The handle for the openGL texture stuff
	GLuint _texName;
    /// 0 if not specified, otherwise GL_TEXTURE_2D or GL_TEXTURE_RECTANGLE_EXT
    GLuint _texType;
    CGLContextObj cgl_ctx;
}
/// The width of the frame buffer, in pixels
@property unsigned width;
/// The height of the frame buffer in pixels
@property unsigned height;

/** Creates the GL image by loading the image from the given path
    @param path The path to load from
    @returns nil on error, otherwise the proxy for the GL image
*/
- (id) initWithPath: (NSString*) path;

- (id) initWithAny:(id) any
        colorSpace:(CGColorSpaceRef) colorSpace;

/** Creates the GL image from the NSImage (or UIImage)
    @param image The image
    @returns nil on error, otherwise the proxy for the GL image
 */
- (id) initWithImage:(ImageClass*) image;

/** Creates the GL image from the CoreGraphics image
    @param bitmap The image's bitmap
    @returns nil on error, otherwise the proxy for the image
 */
- (id) initWithBitmap:(NSBitmapImageRep*) bitmap;


/** Creates the GL image from the CoreGraphics image
    @param cgImage The CoreGraphics image
    @returns nil on error, otherwise the proxy for the GL image
 */
- (id) initWithCGImage:(CGImageRef) cgImage;

/** Creates the GL image from the CoreGraphics image
    @param cgImage The CoreGraphics image
    @param colorSpace The color space to target
    @returns nil on error, otherwise the proxy for the GL image
 */
- (id) initWithCGImage:(CGImageRef) cgImage
            colorSpace:(CGColorSpaceRef) colorSpace;

/** Creates a GL image proxy for the given texture name
    @param The GL texture name
    @param type The GL texture type
    @returns nil on error, otherwise the proxy for the GL image
 */
- (id) initWithTexName:(GLuint) texName;



/** Creates a texture 
    @param type The type of texture to create -- GL_TEXTURE_2D or GL_TEXTURE_RECTANGLE_EXT
    @param _cgl_ctx  The CGL context
    @param logger    An object to log with
    @returns the GL texture name
 */
- (GLuint) texName: (GLuint) type
           context: (CGLContextObj) _cgl_ctx
            logger: (id<Logging>) logger;


/** Reload the bitmap data to the texture data
    @param logger    An object to log with
 */
//- (void) update: (id<Logging>) logger;

@end
@interface BWGLImage (QC)
- (id) toQuartzComposer:(id<QCPlugInContext>) context;
@end