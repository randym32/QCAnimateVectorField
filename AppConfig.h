//
//  AppConfig.h
//  BWAnimateVectorFieldPlugin
//
//  Created by Randall Maas on 6/2/14.
//
//

// These are various configuration settings to help track down problems when developing the plugin.
// There are problems
//   1. The whole GUI, seemingly the whole computer, locks up using NVIDIA drivers.
//       I believe this was caused by a glFlush() with renderbuffers, followed by a call to glFlushRenderAPPLE()
//   2. There is another mystery crash with the openCL, I need to track down
//   3. The texture from this application is random junk, with using NVIDIA drivers


/// 0 enable the GPU
/// 1 disables the use of the GPU
/// For debugging purposes, we allow the GPU to be enabled and disabled.
#define OPENCL_GPU_EN       (0)


// Setting to 0 increases framerate, but slightly less pretty particles
// The GL tutorials say that I should be using GL shaders anyway
#define PARTICLE_TEXTURE_EN (0)

/// Setting this to 0 works for me
/// Setting this to 1 will clear the background and may be a little slower.
#define CLEAR_BACKGROUND_EN (1)

/// Setting this to 1 will enable more logging info to help me track down problems
#define EXTRA_LOGGING_EN    (1)

/// Setting this to 1 forces texture sizes to be a power of 2
#define POWER_OF_2_SIZE_EN  (1)

/// Setting this to 1 will enable use of GL_TEXTURE_RECTANGLE_EXT as a source for the framebuffer
/// Don't change this: Quartz Composer requires texture rectangles
#define FRAMEBUFFER_RECTANGLE_EN (1)

/// The prefix that entries will appear in the log with
#define LogPrefix @"BWAnimateVectorFieldPlugin: "
