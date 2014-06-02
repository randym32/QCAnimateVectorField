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


// Setting to 0 increases framerate, but slightly less pretty particles
// The GL tutorials say that I should be using GL shaders anyway
#define PARTICLE_TEXTURE_EN (0)

/// Setting this to 0 works for me
/// Setting this to 1 will clear the background and may be a little slower.
#define CLEAR_BACKGROUND_EN (1)

/// Setting this to 1 will enable more logging info to help me track down problems
#define EXTRA_LOGGING_EN    (1)

/// The prefix that entries will appear in the log with
#define LogPrefix @"BWAnimateVectorFieldPlugin: "

