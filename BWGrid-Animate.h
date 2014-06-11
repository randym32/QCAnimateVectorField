/*
    BWGrid-Animate.h
    Animate vector field
    Copyright (c) 2013-2014, Randall Maas
    Created by Randall Maas on 12/22/13.
 
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

#import "BWGrid.h"

/* Animates the vectors of the grid
 */
@interface BWGrid (Animate)
/** This is used to change the number of particles in the animation
    @param numParticles  The number particles that should be in the system
    @param logger       The object to log with

    Note: if the number of particles is more than were allocated, the system may toss out the
   old points
*/
- (void) setNumParticles : (int)         numParticles
                   logger: (id<Logging>) logger;

/** This is used to randomize the num next particles
    @param numParticles The number of particles to initialize
*/
- (void) randomizeParticles: (int) numParticles
                           ;

/// Update the animation
- (void) animationStep;
@end
