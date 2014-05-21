/*
    BWAnimateVectorField.h
    Animate Vector Field
    Copyright (c) 2013-2014, Randall Maas
    Created by Randall Maas on 12/23/13.

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


#import <Quartz/Quartz.h>
#import "BWGrid.h"



@interface BWAnimateVectorFieldPlugin : QCPlugIn
{
    /// This is the field animation model
    BWGrid* field;
}

// --- Inputs ----------------------------------------------------------------------

/* Declare a property input port of type "Index" and with the key "inputNumParticles"
 This is the number of particles to use in the animation.*/
@property NSUInteger inputNumParticles;



/* Declare a property input port of type "Structure" and with the key "inputStructure"
    This is the JSON data file.
 */
@property(assign) NSDictionary* inputStructure;

/* Declare a property input port of type "Color" and with the key "inputVectorColor" */
@property(assign) CGColorRef inputVectorColor;

@property(assign) NSUInteger inputWidth;
@property(assign) NSUInteger inputHeight;

/* Declare a property input port of type "Color" and with the key "inputEndColor" */
//@property(assign) CGColorRef inputEndColor;

// --- Outputs ---------------------------------------------------------------------

/* Declare a property output port of type "Image" and with the key "outputImage" */
@property(assign) id<QCPlugInOutputImageProvider> outputImage;

// --- Settings --------------------------------------------------------------------
/* Declare a property input port of type "Index" and with the key "inputNumParticles"
 This is the number of particles to use in the animation.*/
//@property NSUInteger settingNumParticles;


@end

