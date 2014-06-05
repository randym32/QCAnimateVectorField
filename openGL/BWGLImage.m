//
//  GLImage.m
//  OSXGLEssentials
//
//  Created by Randall Maas on 5/22/14.
//
//

#import "glUtil.h"
#import "BWGLImage.h"
#import <Cocoa/Cocoa.h>
#import "glErrorLogging.h"

bool WriteTIFF(CGImageRef image, NSURL* url)
{
    NSDictionary*  properties =
        @{
            (NSString*)kCGImagePropertyTIFFDictionary: @{(NSString*)kCGImagePropertyTIFFCompression:@5}
         }; //LZW compression
    CGImageDestinationRef destinationRef = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, kUTTypeTIFF, 1, NULL);
    CGImageDestinationAddImage(destinationRef, image, (__bridge CFDictionaryRef)properties);
    bool ret = CGImageDestinationFinalize(destinationRef);
    CFRelease(destinationRef);
    return ret;
}

bool WritePNG(CGImageRef image, NSURL* url)
{
    CGImageDestinationRef destinationRef = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destinationRef, image, (CFDictionaryRef)nil);
    bool ret = CGImageDestinationFinalize(destinationRef);
    CFRelease(destinationRef);
    return ret;
}

ImageClass* Path2Image(NSString* path)
{
	return [[ImageClass alloc] initWithContentsOfFile: path];
}

@implementation BWGLImage
{
    /// true if there is an alpha channel
    BOOL hasAlpha;
}
@synthesize width, height;

/** Creates a GL image proxy for the given texture name
    @param The GL texture name
    @returns nil on error, otherwise the proxy for the GL image
 */
- (id)initWithTexName:(GLuint)TexName
{
    if (!(self =[super init]))
        return nil;
    self->_texName = TexName;
    return self;
}

/** Creates the GL image by loading the image from the given path
    @param path The path to load from
    @returns nil on error, otherwise the proxy for the GL image
*/
- (id) initWithPath: (NSString*) path
{
    return [self initWithImage: Path2Image(path)];
}


- (id) initWithAny:(id) any
        colorSpace:(CGColorSpaceRef) colorSpace
{
    if ([any isKindOfClass:[NSImage class]])
        return  [[BWGLImage alloc] initWithImage: any];
    else
        return [[BWGLImage alloc] initWithCGImage: (__bridge CGImageRef)(any)
                                       colorSpace: colorSpace];
}

/** Creates the GL image from the NSImage (or UIImage)
    @param image The image
    @returns nil on error, otherwise the proxy for the GL image
 */
- (id) initWithImage:(ImageClass*) image
{
#if TARGET_OS_IPHONE
    return [self initWithCGImage: image.CGImage];
#else
	return [self initWithBitmap:[[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]]];
#endif
}


/** Creates the GL image from the CoreGraphics image
    @param bitmap The image's bitmap
    @returns nil on error, otherwise the proxy for the image
 */
- (id) initWithBitmap:(NSBitmapImageRep*) bitmap
{
    if (!bitmap)
        return nil;
    if (!(self =[super init]))
        return nil;
    NSSize imageSize = bitmap.size;
    self.width  = imageSize.width;
    self.height = imageSize.height;
    hasAlpha   = bitmap.hasAlpha;
    rowByteSize = bitmap.bytesPerRow;
    bitmapData  = bitmap.bitmapData;
    bitmapRepresentation = bitmap;
    return self;
}


/** Creates the GL image from the CoreGraphics image
    @param cgImage The CoreGraphics image
    @returns nil on error, otherwise the proxy for the GL image
 */
- (id) initWithCGImage:(CGImageRef) cgImage
{
    if (!cgImage)
        return nil;
    return [self initWithCGImage: cgImage
                      colorSpace: CGImageGetColorSpace(cgImage)];
}


/** Creates the GL image from the CoreGraphics image
    @param cgImage The CoreGraphics image
    @returns nil on error, otherwise the proxy for the GL image
 */
- (id) initWithCGImage:(CGImageRef)      cgImage
            colorSpace:(CGColorSpaceRef) colorSpace
{
    if (!cgImage)
        return nil;
    if (!(self =[super init]))
        return nil;

    // first, create a buffer to hold the image
	self.width  = CGImageGetWidth(cgImage);
	self.height = CGImageGetHeight(cgImage);
    hasAlpha= kCGImageAlphaNone != CGImageGetAlphaInfo(cgImage);
    rowByteSize = self.width * 4;
    if(rowByteSize % 16)
        rowByteSize = ((rowByteSize / 16) + 1) * 16;
	bitmapData = malloc(self.height * rowByteSize);
    if (!bitmapData)
    {
        return 0;
    }

	//[context colorSpace]
    // Do a memory transfer to the buffer
	CGContextRef context = CGBitmapContextCreate(bitmapData, self.width, self.height, 8, rowByteSize, colorSpace,
                                                 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
    if (!context)
    {
        free(bitmapData);
        bitmapData=NULL;
        return 0;
    }
	CGContextSetBlendMode(context, kCGBlendModeCopy);
#if 0
	if (flipVertical)
	{
		CGContextTranslateCTM(context, 0.0, height);
		CGContextScaleCTM(context, 1.0, -1.0);
	}
#endif
    // Copy the image into the buffer
	CGContextDrawImage(context, CGRectMake(0.0, 0.0, self.width, self.height), cgImage);
    /* We don't need the image and context anymore */
	CGContextRelease(context);
    
	return self;
}

- (void)dealloc
{
    if (_texName)
        glDeleteTextures(1, &_texName);
    _texName = 0;
    if (bitmapData && !bitmapRepresentation)
        free(bitmapData);
}



/** Creates a texture 
    @param type The type of texture to create -- GL_TEXTURE_2D or GL_TEXTURE_RECTANGLE_EXT
    @param _cgl_ctx  The CGL context
    @param logger    An object to log with
    @returns the GL texture name
 */
- (GLuint) texName: (GLuint) type
           context: (CGLContextObj) _cgl_ctx
            logger: (id<Logging>) logger
{
    cgl_ctx = _cgl_ctx;
    if (GL_TEXTURE_2D != _texType)
        _texType = GL_TEXTURE_RECTANGLE_EXT;
    
	// Create a texture object to apply to model
    // Try to allocate
    if (!_texName)
    {
        _texType = type;
        glGenTextures(1, &_texName);
    }
    if (!_texName)
    {
        LogGLErrors();
        // There was a problem allocating it
        return 0;
    }

    // Set up the filtering for the texture
    glBindTexture(_texType, _texName);
    if (GL_TEXTURE_2D == _texType)
    {
        
        // Set up filter and wrap modes for this texture object
        glTexParameteri(_texType, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    }
    else
    {
        // Set up filter and wrap modes for this texture object
        glTexParameteri(_texType, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    }
    glTexParameteri(_texType, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(_texType, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(_texType, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    // Indicate that pixel rows are tightly packed
    //  (defaults to stride of 4 which is kind of only good for
    //  RGBA or FLOAT data types)
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

//    glPixelStorei(GL_UNPACK_ROW_LENGTH, rowByteSize / ([upsideDown bitsPerPixel]>> 3));

    // Allocate and load image data into texture
    // TODO: Figure out why this isn't BGR
    glTexImage2D(_texType, 0, GL_RGBA, self.width, self.height, 0,
				 hasAlpha? GL_BGRA : GL_BGR, GL_UNSIGNED_BYTE, bitmapData);
    LogGLErrors();
    
    // Create mipmaps for this texture for better image quality
    if (GL_TEXTURE_2D == _texType && (GL_MIPMAP_PRESENT & glFeatures(cgl_ctx)) && bitmapData)
    {
        // Mipmaps might not be supported by the video driver
        glGenerateMipmap(GL_TEXTURE_2D);
        LogGLErrors();
    }

    //
    if (bitmapData && !bitmapRepresentation)
    {
        free(bitmapData);
        bitmapData = NULL;
    }
    return _texName;
}



/** Binds the texture map so that it can be used as source in rendering
    @param logger    An object to log with
 */
- (void) bindAsGLSource: (id<Logging>) logger
{
    // Bind the texture to be used
	glBindTexture(_texType, _texName);
    LogGLErrors();
}
@end

