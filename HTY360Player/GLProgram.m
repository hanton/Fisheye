//
//  GLProgram.m
//  HTY360Player
//
//  Created by  on 11/8/15.
//  Copyright © 2015 Hanton. All rights reserved.
//

#import "GLProgram.h"

@interface GLProgram()

- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
               string:(NSString *)shaderString;

@end

@implementation GLProgram

#pragma mark - Init

- (id)initWithVertexShaderString:(NSString *)vShaderString
            fragmentShaderString:(NSString *)fShaderString {
    self = [super init];
    if (self) {
        self.attributes = [[NSMutableArray alloc] init];
        self.uniforms = [[NSMutableArray alloc] init];
        self.program = glCreateProgram();
        
        if (![self compileShader:&_vertShader
                            type:GL_VERTEX_SHADER
                          string:vShaderString])
            NSLog(@"Failed to compile vertex shader");
        
        if (![self compileShader:&_fragShader
                            type:GL_FRAGMENT_SHADER
                          string:fShaderString])
            NSLog(@"Failed to compile fragment shader");
        
        glAttachShader(_program, _vertShader);
        glAttachShader(_program, _fragShader);
    }
    
    return self;
}

- (id)initWithVertexShaderFilename:(NSString *)vShaderFilename
            fragmentShaderFilename:(NSString *)fShaderFilename {
    NSString *vertShaderPathname = [[NSBundle mainBundle] pathForResource:vShaderFilename ofType:@"vsh"];
    NSString *vertexShaderString = [NSString stringWithContentsOfFile:vertShaderPathname
                                                             encoding:NSUTF8StringEncoding
                                                                error:nil];
    
    NSString *fragShaderPathname = [[NSBundle mainBundle] pathForResource:fShaderFilename ofType:@"fsh"];
    NSString *fragmentShaderString = [NSString stringWithContentsOfFile:fragShaderPathname
                                                               encoding:NSUTF8StringEncoding
                                                                  error:nil];
    
    if ((self = [self initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString])) {
        
    }
    
    return self;
}

#pragma mark - Dealloc

- (void)dealloc {
    if (self.vertShader) {
        glDeleteShader(self.vertShader);
    }
    
    if (self.fragShader) {
        glDeleteShader(self.fragShader);
    }
    
    if (self.program) {
        glDeleteProgram(self.program);
        self.program = 0;
    }
}

#pragma mark - Private Method

- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
               string:(NSString *)shaderString {
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[shaderString UTF8String];
    if (!source) {
        NSLog(@"Failed to load shader: %@", shaderString);
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    
    if (status != GL_TRUE) {
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            NSLog(@"Shader compile log:\n%s", log);
            free(log);
        }
    }
    
    return status == GL_TRUE;
}

#pragma mark - Public Method

- (void)addAttribute:(NSString *)attributeName {
    if (![self.attributes containsObject:attributeName]) {
        [self.attributes addObject:attributeName];
        glBindAttribLocation(self.program,
                             (GLuint)[self.attributes indexOfObject:attributeName],
                             [attributeName UTF8String]);
    }
}

- (GLuint)attributeIndex:(NSString *)attributeName {
    return (GLuint)[self.attributes indexOfObject:attributeName];
}

- (GLuint)uniformIndex:(NSString *)uniformName {
    return glGetUniformLocation(self.program, [uniformName UTF8String]);
}

- (BOOL)link {
    GLint status;
    glLinkProgram(self.program);
    
    glGetProgramiv(self.program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
        return NO;
    
    if (self.vertShader) {
        glDeleteShader(self.vertShader);
        self.vertShader = 0;
    }
    if (self.fragShader) {
        glDeleteShader(self.fragShader);
        self.fragShader = 0;
    }
    
    return YES;
}

- (void)use {
    glUseProgram(self.program);
}

@end
