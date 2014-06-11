/*
    BWGrid+GLRender.h
    Animate Vector Field
    Copyright (c) 2013-2014, Randall Maas
    Created by Randall Maas on 12/30/13.

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
@protocol Logging;
@interface BWGrid (GLRender)
/** Load the shaders for the particles
    @param logger  The object to log with
 */
- (void) loadShaders: (id<Logging>)   logger;

/** Set the color for the particles
    @param color The color to use for drawing the particles
    @param logger  The object to log with
 */
- (void) setColor: (CGColorRef) color
           logger: (id<Logging>) logger;



/** Stroke each of the particle motions
    @param logger  The object to log with
 */
- (GLuint) draw: (id<Logging>) logger
               ;
@end
