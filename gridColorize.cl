/*
    Shade the field
    Copyright (c) 2013-2014, Randall Maas
    Created by Randall Maas on 12/22/13.
 
    Translated from https://github.com/cambecc/earth
    Copyright (c) 2013 Cameron Beccario
    The MIT License - http://opensource.org/licenses/MIT

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

#define M_PI   3.1415926535897932384626433832795f

/**
 * Produces a color style in a rainbow-like trefoil color space. Not quite HSV, but produces a nice
 * spectrum. See http://krazydad.com/tutorials/makecolors.php.
 *
 * @param hue the hue rotation in the range [0, 1]
 * @param a the alpha value in the range [0, 1]
 * @returns {Array} [r, g, b, a]
 */
uchar4 sinebowColor(float hue, float a) {
    // Map hue [0, 1] to radians [0, 5/6τ]. Don't allow a full rotation because that keeps hue == 0 and
    // hue == 1 from mapping to the same color.
    float rad = hue * 2 * M_PI * 5.0/6.0;
    rad *= 0.75;  // increase frequency to 2/3 cycle per rad
    
    float s = sin(rad);
    float c = cos(rad);
    uchar r = clamp(floor(-c * 255.0 * 0.4)*a, 0.0, 255.0);
    uchar g = clamp(floor(s * 255.0 * 0.4)*a, 0.0, 255.0);
    float tmp = max(c, -s);
    uchar b = clamp(floor(tmp * 255.0 * 0.4)*a, 0.0, 255.0);
    uchar4 ret = (uchar4)(r, g, b, (uchar) (255.0*a));
    if (b >= r && b >= g)
        return (uchar4)(0,0,0,0);
    return ret;
}


/** This creates a colorized version of the grid magnitude
    @param numXBins The number of bins in the x axis
    @param numYBins The number of bins in the y axis
    @param dataGrid The grid of vectors (mapped to an array)
*/
__kernel void gridColorize(
                            __global float2* dataGrid  // The data in the grid
                           , float            maxMagnitude
                           , __global uchar4* image
                           )
{
    // Get each work-items unique row and column
    int I = get_global_id(0);
    
    float x = dataGrid[I].x;
    float y = dataGrid[I].y;
    float mag = sqrt(x*x+y*y);

    // Compute the color
    if (!isnan(mag))
    {
        uchar4 color = sinebowColor(min(mag, maxMagnitude) / maxMagnitude, 0.5);
        // Blend the pixel
        uchar4 oldColor = image[I];
        float alpha = 1.0 - color[3]/255.0;
        color[0] = clamp((int)(oldColor[0] * alpha+color[0]), 0, 255);
        color[1] = clamp((int)(oldColor[1] * alpha+color[1]), 0, 255);
        color[2] = clamp((int)(oldColor[2] * alpha+color[2]), 0, 255);
        // And store the pixel
        color[3] = clamp((int)(oldColor[3] * alpha+color[3]), 0, 255);
        image[I] = color;
    }
}


