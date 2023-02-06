// The MIT License (MIT)
//
// Copyright (c) 2013 Dan Ginsburg, Budirijanto Purnomo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

//
// Book:      OpenGL(R) ES 3.0 Programming Guide, 2nd Edition
// Authors:   Dan Ginsburg, Budirijanto Purnomo, Dave Shreiner, Aaftab Munshi
// ISBN-10:   0-321-93388-5
// ISBN-13:   978-0-321-93388-1
// Publisher: Addison-Wesley Professional
// URLs:      http://www.opengles-book.com
//            http://my.safaribooksonline.com/book/animation-and-3d/9780133440133
//
// ESShapes.c
//
//    Utility functions for generating shapes
//

#include "esShapes.h"

#include <stdlib.h>
#include <math.h>
#include <OpenGLES/gltypes.h>


///
// Defines
//
#define ES_PI  (3.14159265f)

//////////////////////////////////////////////////////////////////
//
//  Public Functions
//
//

//
/// brief Generates geometry for a sphere.  Allocates memory for the vertex data and stores
///        the results in the arrays.  Generate index list for a TRIANGLE_STRIP
/// param numSlices The number of slices in the sphere
/// param vertices If not NULL, will contain array of float3 positions
/// param texCoords If not NULL, will contain array of float2 texCoords
/// param indices If not NULL, will contain the array of indices for the triangle strip
/// return The number of indices required for rendering the buffers (the number of indices stored in the indices array
///         if it is not NULL ) as a GL_TRIANGLE_STRIP
//
int esGenSphere ( int numSlices, float radius, GLfloat **vertices,
                            GLfloat **texCoords, GLushort **indices )
{
  int numParallels = numSlices / 2;
  int numVertices = (numParallels + 1) * (numSlices + 1);
  int numIndices = numParallels * numSlices * 6;
  float angleStep = (2.0f * ES_PI) / ((float) numSlices);
  
  if (vertices != NULL) {
    *vertices = malloc(sizeof(float) * 3 * numVertices);
  }
  
  if (texCoords != NULL) {
    *texCoords = malloc(sizeof(float) * 2 * numVertices);
  }
  
  if (indices != NULL) {
    *indices = malloc(sizeof(uint16_t) * numIndices);
  }
  
  for (int i = 0; i < numParallels + 1; i++) {
    for (int j = 0; j < numSlices + 1; j++) {
      int vertex = (i * (numSlices + 1) + j) * 3;
      
      if (vertices) {
        (*vertices)[vertex + 0] = radius * sinf(angleStep * (float)i) * cosf(angleStep * (float)j);
        (*vertices)[vertex + 1] = radius * cosf(angleStep * (float)i);
        (*vertices)[vertex + 2] = radius * sinf(angleStep * (float)i) * sinf(angleStep * (float)j);
      }
      
      if (texCoords) {
        int texIndex = (i * (numSlices + 1) + j) * 2;
        (*texCoords)[texIndex + 0] = (float)j / (float)numSlices;
        (*texCoords)[texIndex + 1] = ((float)i / (float)numParallels);
      }
    }
  }
  
  // Generate the indices
  if (indices != NULL) {
    GLushort *indexBuf = (*indices);
    for (int i = 0; i < numParallels ; i++) {
      for (int j = 0; j < numSlices; j++) {
        *indexBuf++ = i * (numSlices + 1) + j;
        *indexBuf++ = (i + 1) * (numSlices + 1) + j;
        *indexBuf++ = (i + 1) * (numSlices + 1) + (j + 1);
        
        *indexBuf++ = i * (numSlices + 1) + j;
        *indexBuf++ = (i + 1) * (numSlices + 1) + (j + 1);
        *indexBuf++ = i * (numSlices + 1) + (j + 1);
      }
    }
  }

  return numIndices;
}
