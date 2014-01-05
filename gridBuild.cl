/*
    Build the grid of vectors
    Animate vector field
    Copyright (c) 2013-2014, Randall Maas
    Created by Randall Maas on 12/22/13.
 
    Translated from  https://github.com/cambecc/earth
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
*//*
    Vectors are represented as unit direction
    Points are 2D
 
    The data is provided as a  vector field arranged by lat/lon
    The vectors are in the units of m/s
 
    Problem #1
    The problem is that lat/lon doesn't directly map to meter distances.
    The fix is that Cameron uses a finite differences method.  At the poles 
    these distances between two points is close.  He seems to distort the vecto
    magnitudes at these.
 
    A more sophisticate method might accomodate the wobbly shape of the earth.
 
    Problem #2
    When the particles going over the poles or off the wrap around, the point is lost.
    This singularity hopefully won't be noticed.  But it isn't handled elegantly.
 
    Problem #3
    We need a bigger field.  The field is not sufficiently large for a large sphere.
 */

#define M_PI   3.1415926535897932384626433832795f

/** Bilinear interpolation
    @param x
    @param y
    @param g00
    @param g10
    @param g01
    @param g11
    @returns {float}
*/
float2 bilinear(float x, float y, float2 g00, float2 g10, float2 g01, float2 g11)
{
    float a = (1.0 - x) * (1.0 - y);
    float b = x * (1.0 - y);
    float c = (1.0 - x) * y;
    float d = x * y;
    float u = g00.x * a + g10.x * b + g01.x * c + g11.x * d;
    float v = g00.y * a + g10.y * b + g01.y * c + g11.y * d;
    return (float2)(u, v);
}


/** Interpolates
    @param coord  The coordinate of the point of discussion
    @param origin The origin of the coordinate space
    @param delta  The distance between grid points (e.g., 2.5 deg lon, 2.5 deg lat)
    @returns vector
*/
float2 interpolate(float2 coord
                   , uint2 srcSize  // The number of uv vectors wide and high
                   , __global float2* srcField)
{
    //         1      2           After converting λ and φ to fractional grid indexes i and j, we find the
    //        fi  i   ci          four points "G" that enclose point (i, j). These points are at the four
    //         | =1.4 |           corners specified by the floor and ceiling of i and j. For example, given
    //      ---G--|---G--- fj 8   i = 1.4 and j = 8.3, the four surrounding grid points are (1, 8), (2, 8),
    //    j ___|_ .   |           (1, 9) and (2, 9).
    //  =8.3   |      |
    //      ---G------G--- cj 9   Note that for wrapped grids, the first column is duplicated as the last
    //         |      |           column, so the index ci can be used without taking a modulo.

    // Calculate the longitude (x) index within the source field
    int fi = floor(coord.x);
    // calculate the latitude (y) index withing the source field
    int fj = floor(coord.y);
    uint ci = min(fi+1u, srcSize.x-1u);
    uint cj = min(fj+1u, srcSize.y-1u);

    // The starting spot of the row
    int rowOfs = fj*srcSize.x;

    float2 g00 = srcField[rowOfs+fi];
    float2 g10 = srcField[rowOfs+ci];

    rowOfs += srcSize.x;
    float2 g01 = srcField[rowOfs+fi];
    float2 g11 = srcField[rowOfs+ci];
    // All four points found, so use bilinear interpolation to calculate the wind vector.
    return bilinear(coord.x - fi, coord.y - fj, g00, g10, g01, g11);

}


/**
 * Returns the distortion introduced by the specified projection at the given point.
 *
 * This method uses finite difference estimates to calculate warping by adding a very small amount (h) to
 * both the longitude and latitude to create two lines. These lines are then projected to pixel space, where
 * they become diagonals of triangles that represent how much the projection warps longitude and latitude at
 * that location.
 *
 * <pre>
 *        (u, v+h)                  (xu, yu)
 *           .                         .
 *           |               ==>        \
 *           |                           \   __. (xv, yv)
 *    (u, v) .____. (u+h, v)       (x, y) .--
 * </pre>
 *
 * See:
 *     Map Projections: A Working Manual, Snyder, John P: pubs.er.usgs.gov/publication/pp1395
 *     gis.stackexchange.com/questions/5068/how-to-create-an-accurate-tissot-indicatrix
 *     www.jasondavies.com/maps/tissot
 *
 * @returns {float4} float4 of scaled derivatives [dx/du, dy/du, dx/dv, dy/dv]
 */
float4 distortion(float2 latlon)
{
    float H = 0.0000630957344f; // pow(10, -5.2);
    float hu = latlon.x < 0 ? H : -H;
    float hv = latlon.y < 0 ? H : -H;
    float2 pu = (float2)(latlon.x + hu, latlon.y);
    float2 pv = (float2)(latlon.x,      latlon.y + hv);
    
    // Meridian scale factor (see Snyder, equation 4-3), where R = 1. This handles issue where length of 1º λ
    // changes depending on v. Without this, there is a pinching effect at the poles.
    float k = cos(latlon.y / 360.0 * M_PI *2.0);
    
    return (float4)(
                    (pu.x - latlon.x) / hu / k,
                    (pu.y - latlon.y) / hu / k,
                    (pv.x - latlon.x) / hv,
                    (pv.y - latlon.y) / hv
                    );
}


/** Calculate distortion of the wind vector caused by the shape of the projection at point
     (x, y). The wind vector is modified in place and returned by this function.
    @param latlon  The coordinate of the point of discussion
    @returns distorted vector
 */
float2 distort(float2 latlon, float scale, float2 wind)
{
    float2 uv = wind * scale;
    float4 d = distortion(latlon);


    // Scale distortion vectors by u and v, then add.
    wind.x = d.x * uv.x + d.z * uv.y;
    wind.y = d.y * uv.x + d.w * uv.y;
    
    return wind;
}


/** Build the internal form of the grid
    create the data grid by interpolating these, and handling the metric distance for the
    projection

    @param gridSize   The number of elements in the original grid
    @param srcGrid    The internal representation of the u-v grid
    @param origin     The origin of the coordinate space (e.g., 0.0E, 90.0N)
    @param delta      The distance between grid points (e.g., 2.5 deg lon, 2.5 deg lat)
    @param velocityScale The ?
    @param numXBins   The number of bins wide the out grid is
    @param vectorField The grid modified for animation
*/
kernel void gridInterpolate(
                             uint2  srcSize
                           , __global float2* srcField
                           , float2 origin
                           , float2 delta
                           , float velocityScale
                           , uint2 tgtSize
                           , __global float2* tgtField
                           )
{
    // Step thru each of the degree points
    // Get each work-items unique row-column
    // Make this into a point (vector)
    uint2 tgtPoint = (uint2)(get_global_id(0),get_global_id(1));
    if (tgtSize.x == 0 || tgtSize.y == 0)
        return;
    
    // First, calculate the point within the source field
    // We use the srcSize (which may be longer than the original) so that the right hand size gets wrap around info
    float2 srcPoint= (float2)( clamp((float)(tgtPoint.x*srcSize.x)/(float)tgtSize.x, 0.0f, (float)srcSize.x-0.1f)
                             , clamp((float)(tgtPoint.y*srcSize.y)/(float)tgtSize.y, 0.0f, (float)srcSize.y-0.1f) );
    float2 wind = interpolate(srcPoint, srcSize, srcField);

    // Second, calculate the lat/lon of the wind vector
    float2 latlon;
    latlon . x = srcPoint.x - origin.x;
    latlon . y  =  origin.y - srcPoint.y;
    
    // If the wind vector is valid, use the grid distoration
    // Calculate the distortion from the particular projection onto the grid
    wind = distort(latlon, velocityScale, wind);

    // The source data often starts at Longitude 0, while the land maps start at -180.
    // Shift this to match those maps
    tgtField[tgtPoint.x +     tgtPoint.y*tgtSize.x] = wind;
}



/** Build the internal form of the grid

    @param uData      The grid of the u component's of the vector
    @param vData      The grid of the v component's of the vector
    @param gridSize   The number of elements in the original grid
    @param delta      The distance between grid points (e.g., 2.5 deg lon, 2.5 deg lat)
    @param srcGrid    The internal representation of the u-v grid
 */
kernel void gridBuild(
                     __constant float* uData, __constant float* vData
                     // The number of source grid points W-E and N-S (e.g., 144 x 73)
                     , uint2 gridSize
                     , float2 delta
                     , bool isContinuous
                     , __global  float2* srcGrid
                      )
{
    // Get each work-items unique row
    int j = get_global_id(0);
    int p = j * gridSize.x;
    
    // Scan mode 0 assumed. Longitude increases from λ0, and latitude decreases from φ0.
    // http://www.nco.ncep.noaa.gov/pmb/docs/grib2/grib2_table3-4.shtml
    // Continuous srcGrids have an extra column
    int rowOfs = (gridSize.x + (isContinuous?1:0)) * j;
    for (int i = 0; i < gridSize.x; i++, p++)
    {
        // Note: because the latitude decreases, the direction of the y component is flipped
        // I fix it here
        srcGrid[rowOfs + i] = (float2)(uData[p], -vData[p]);
    }
    if (isContinuous)
    {
        // For wrapped grids, duplicate first column as last column to simplify interpolation logic
        srcGrid[rowOfs + gridSize.x] = srcGrid[rowOfs];
    }
}


