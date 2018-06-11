//
//  HTYGLKVC.m
//  HTY360Player
//
//  Created by  on 11/8/15.
//  Copyright © 2015 Hanton. All rights reserved.
//

#import "HTYGLKVC.h"
#import "GLProgram.h"
#import "HTY360PlayerVC.h"
#import <CoreMotion/CoreMotion.h>

#define MAX_OVERTURE 95.0
#define MIN_OVERTURE 25.0
#define DEFAULT_OVERTURE 85.0
#define ES_PI  (3.14159265f)
#define ROLL_CORRECTION ES_PI/2.0
#define FramesPerSecond 30
#define SphereSliceNum 200
#define SphereRadius 1.0
#define SphereScale 300

// For digital component video the color format YCbCr is used.
// ITU-R BT.709, which is the standard for HDTV.
// http://www.equasys.de/colorconversion.html
const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

// Uniform index.
enum {
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_Y,
    UNIFORM_UV,
    UNIFORM_COLOR_CONVERSION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

@interface HTYGLKVC ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLProgram *program;
@property (strong, nonatomic) NSMutableArray *currentTouches;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) CMAttitude *referenceAttitude;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (assign, nonatomic) CGFloat overture;
@property (assign, nonatomic) CGFloat fingerRotationX;
@property (assign, nonatomic) CGFloat fingerRotationY;
@property (assign, nonatomic) CGFloat savedGyroRotationX;
@property (assign, nonatomic) CGFloat savedGyroRotationY;
@property (assign, nonatomic) int numIndices;
@property (assign, nonatomic) CVOpenGLESTextureRef lumaTexture;
@property (assign, nonatomic) CVOpenGLESTextureRef chromaTexture;
@property (assign, nonatomic) CVOpenGLESTextureCacheRef videoTextureCache;
@property (assign, nonatomic) GLKMatrix4 modelViewProjectionMatrix;
@property (assign, nonatomic) GLuint vertexIndicesBufferID;
@property (assign, nonatomic) GLuint vertexBufferID;
@property (assign, nonatomic) GLuint vertexTexCoordID;
@property (assign, nonatomic) GLuint vertexTexCoordAttributeIndex;
@property (assign, nonatomic, readwrite) BOOL isUsingMotion;

- (void)setupGL;
- (void)tearDownGL;
- (void)buildProgram;

@end

@implementation HTYGLKVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.contentScaleFactor = [UIScreen mainScreen].scale;
    
    self.preferredFramesPerSecond = FramesPerSecond;
    self.overture = DEFAULT_OVERTURE;
    
    [self addGesture];
    [self setupGL];
    [self startDeviceMotion];
}

- (void)refreshTexture {
    CVReturn err;
    CVPixelBufferRef pixelBuffer = [self.videoPlayerController retrievePixelBufferToDraw];
    if (pixelBuffer != nil) {
        GLsizei textureWidth = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
        GLsizei textureHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
        
        if (!self.videoTextureCache) {
            NSLog(@"No video texture cache");
            return;
        }
        
        [self cleanUpTextures];
        
        // Y-plane
        glActiveTexture(GL_TEXTURE0);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           self.videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RED_EXT,
                                                           textureWidth,
                                                           textureHeight,
                                                           GL_RED_EXT,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &_lumaTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // UV-plane.
        glActiveTexture(GL_TEXTURE1);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           self.videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RG_EXT,
                                                           textureWidth/2,
                                                           textureHeight/2,
                                                           GL_RG_EXT,
                                                           GL_UNSIGNED_BYTE,
                                                           1,
                                                           &_chromaTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        CFRelease(pixelBuffer);
    }
}

- (void)dealloc {
    [self stopDeviceMotion];
    [self tearDownVideoCache];
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexIndicesBufferID);
    glDeleteBuffers(1, &_vertexBufferID);
    glDeleteBuffers(1, &_vertexTexCoordID);
    
    self.program = nil;
}

- (void)tearDownVideoCache {
    [self cleanUpTextures];
    
    CFRelease(_videoTextureCache);
    self.videoTextureCache = nil;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (void)addGesture {
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pinchRecognizer];
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleSingleTapGesture:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTapRecognizer];
}

#pragma mark - Texture Cleanup

- (void)cleanUpTextures {
    if (self.lumaTexture) {
        CFRelease(_lumaTexture);
        self.lumaTexture = NULL;
    }
    
    if (self.chromaTexture) {
        CFRelease(_chromaTexture);
        self.chromaTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

#pragma mark - Generate Sphere
//https://github.com/danginsburg/opengles-book-samples/blob/604a02cc84f9cc4369f7efe93d2a1d7f2cab2ba7/iPhone/Common/esUtil.h#L110
int esGenSphere(int numSlices, float radius, float **vertices,
                float **texCoords, uint16_t **indices, int *numVertices_out) {
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
                (*vertices)[vertex + 0] = radius * sinf(angleStep * (float)i) * sinf(angleStep * (float)j);
                (*vertices)[vertex + 1] = radius * cosf(angleStep * (float)i);
                (*vertices)[vertex + 2] = radius * sinf(angleStep * (float)i) * cosf(angleStep * (float)j);
            }
            
            if (texCoords) {
                int texIndex = (i * (numSlices + 1) + j) * 2;
                (*texCoords)[texIndex + 0] = (float)j / (float)numSlices;
                (*texCoords)[texIndex + 1] = 1.0f - ((float)i / (float)numParallels);
            }
        }
    }
    
    // Generate the indices
    if (indices != NULL) {
        uint16_t *indexBuf = (*indices);
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
    
    if (numVertices_out) {
        *numVertices_out = numVertices;
    }
    
    return numIndices;
}

#pragma mark - Setup OpenGL

- (void)setupGL {
    [EAGLContext setCurrentContext:self.context];
    [self buildProgram];
    [self setupBuffers];
    [self setupVideoCache];
    [self.program use];
    glUniform1i(uniforms[UNIFORM_Y], 0);
    glUniform1i(uniforms[UNIFORM_UV], 1);
    glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, kColorConversion709);
}

- (void)setupBuffers {
    GLfloat *vVertices = NULL;
    GLfloat *vTextCoord = NULL;
    GLushort *indices = NULL;
    int numVertices = 0;
    self.numIndices = esGenSphere(SphereSliceNum, SphereRadius, &vVertices, &vTextCoord, &indices, &numVertices);
    
    //Indices
    glGenBuffers(1, &_vertexIndicesBufferID);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.vertexIndicesBufferID);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.numIndices*sizeof(GLushort), indices, GL_STATIC_DRAW);
    
    // Vertex
    glGenBuffers(1, &_vertexBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBufferID);
    glBufferData(GL_ARRAY_BUFFER, numVertices*3*sizeof(GLfloat), vVertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*3, NULL);
    
    // Texture Coordinates
    glGenBuffers(1, &_vertexTexCoordID);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexTexCoordID);
    glBufferData(GL_ARRAY_BUFFER, numVertices*2*sizeof(GLfloat), vTextCoord, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(self.vertexTexCoordAttributeIndex);
    glVertexAttribPointer(self.vertexTexCoordAttributeIndex, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
}

- (void)setupVideoCache {
    if (!self.videoTextureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_videoTextureCache);
        if (err != noErr) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
            return;
        }
    }
}

#pragma mark - Device Motion

- (void)startDeviceMotion {
    self.isUsingMotion = NO;
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.referenceAttitude = nil;
    self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
    self.motionManager.gyroUpdateInterval = 1.0f / 60;
    self.motionManager.showsDeviceMovementDisplay = YES;
    
    [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
    
    self.referenceAttitude = self.motionManager.deviceMotion.attitude; // Maybe nil actually. reset it later when we have data
    
    self.savedGyroRotationX = 0;
    self.savedGyroRotationY = 0;
    
    self.isUsingMotion = YES;
}

- (void)stopDeviceMotion {
    self.fingerRotationX = self.savedGyroRotationX-self.referenceAttitude.roll- ROLL_CORRECTION;
    self.fingerRotationY = self.savedGyroRotationY;
    
    self.isUsingMotion = NO;
    [self.motionManager stopDeviceMotionUpdates];
    self.motionManager = nil;
}

#pragma mark - GLKViewController Subclass
//As an alternative to implementing a glkViewControllerUpdate: method in a delegate, your subclass can provide an update method instead.
//https://developer.apple.com/library/ios/documentation/GLkit/Reference/GLKViewController_ClassRef/index.html
- (void)update {
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.overture), aspect, 0.1f, 400.0f);
    projectionMatrix = GLKMatrix4Rotate(projectionMatrix, ES_PI, 1.0f, 0.0f, 0.0f);
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    float scale = SphereScale;
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, scale, scale, scale);
    if(self.isUsingMotion) {
        CMDeviceMotion *deviceMotion = self.motionManager.deviceMotion;
        if (deviceMotion != nil) {
            CMAttitude *attitude = deviceMotion.attitude;
            
            if (self.referenceAttitude != nil) {
                [attitude multiplyByInverseOfAttitude:self.referenceAttitude];
            } else {
                //NSLog(@"was nil : set new attitude", nil);
                self.referenceAttitude = deviceMotion.attitude;
            }
            
            float cRoll = -fabs(attitude.roll); // Up/Down landscape
            float cYaw = attitude.yaw;  // Left/ Right landscape
            float cPitch = attitude.pitch; // Depth landscape
            
            UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
            if (orientation == UIDeviceOrientationLandscapeRight ){
                cPitch = cPitch*-1; // correct depth when in landscape right
            }
            
            modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, cRoll); // Up/Down axis
            modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, cPitch);
            modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, cYaw);
            
            modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, ROLL_CORRECTION);
            
            modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.fingerRotationX);
            modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.fingerRotationY);
            
            self.savedGyroRotationX = cRoll + ROLL_CORRECTION + self.fingerRotationX;
            self.savedGyroRotationY = cPitch + self.fingerRotationY;
        }
    } else {
        modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.fingerRotationX);
        modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.fingerRotationY);
    }
    
    self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    [self convertAngles:self.modelViewProjectionMatrix];
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, GL_FALSE, self.modelViewProjectionMatrix.m);
}

// convert the current view matrix to yaw and roll center
-(void)convertAngles:(GLKMatrix4)matrix{
    float yaw = 0;
    float roll = 0;
    
    if (matrix.m00 == 1.0f) {
        yaw = atan2f(matrix.m02, matrix.m23);
        roll = 0;
        
    }
    else if (matrix.m00 == -1.0f) {
        yaw = atan2f(matrix.m02, matrix.m23);
        roll = 0;
    }
    else {
        yaw = atan2(-matrix.m20,matrix.m00);
        roll = atan2(-matrix.m12,matrix.m11);
    }
    
    if(roll>0){
        roll = roll-ES_PI;
    }
    else{
        roll = roll+ES_PI;
    }
    
    [self.videoPlayerController currentTargetingAtYaw:yaw andRoll:roll];
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self refreshTexture];
    
    glClear(GL_COLOR_BUFFER_BIT);
    glDrawElements(GL_TRIANGLES, self.numIndices, GL_UNSIGNED_SHORT, 0);
}

#pragma mark - OpenGL Program

- (void)buildProgram {
    self.program = [[GLProgram alloc]
                    initWithVertexShaderFilename:@"Shader"
                    fragmentShaderFilename:@"Shader"];
    
    [self.program addAttribute:@"position"];
    [self.program addAttribute:@"texCoord"];
    
    if (![self.program link]) {
        self.program = nil;
        NSAssert(NO, @"Falied to link HalfSpherical shaders");
    }
    
    self.vertexTexCoordAttributeIndex = [self.program attributeIndex:@"texCoord"];
    
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = [self.program uniformIndex:@"modelViewProjectionMatrix"];
    uniforms[UNIFORM_Y] = [self.program uniformIndex:@"SamplerY"];
    uniforms[UNIFORM_UV] = [self.program uniformIndex:@"SamplerUV"];
    uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] = [self.program uniformIndex:@"colorConversionMatrix"];
}

#pragma mark - Touch Event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if(self.isUsingMotion) return;
    for (UITouch *touch in touches) {
        [_currentTouches addObject:touch];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if(self.isUsingMotion) return;
    UITouch *touch = [touches anyObject];
    float distX = [touch locationInView:touch.view].x - [touch previousLocationInView:touch.view].x;
    float distY = [touch locationInView:touch.view].y - [touch previousLocationInView:touch.view].y;
    distX *= -0.005;
    distY *= -0.005;
    self.fingerRotationX += distY *  self.overture / 100;
    self.fingerRotationY -= distX *  self.overture / 100;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isUsingMotion) return;
    for (UITouch *touch in touches) {
        [self.currentTouches removeObject:touch];
    }
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        [self.currentTouches removeObject:touch];
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
    self.overture /= recognizer.scale;
    
    if (self.overture > MAX_OVERTURE) {
        self.overture = MAX_OVERTURE;
    }
    
    if (self.overture < MIN_OVERTURE) {
        self.overture = MIN_OVERTURE;
    }
}

- (void)handleSingleTapGesture:(UITapGestureRecognizer *)recognizer {
    [self.videoPlayerController toggleControls];
}

@end
