//
//  Shader.swift
//  Fisheye
//
//  Created by Hanton Yang on 2/6/23.
//

import Foundation
import GLKit

/// Manages the OpenGL ES shader program and its uniform/attribute locations.
public class Shader {
    /// The compiled and linked OpenGL program handle.
    public var program: GLuint = 0
    // Vertex Shader attributes
    /// Position attribute location.
    public var position = GLuint()
    /// Texture coordinate attribute location.
    public var texCoord = GLuint()
    /// Model-view-projection matrix uniform location.
    public var modelViewProjectionMatrix = GLint()
    // Fragment Shader uniforms
    /// Y (luma) texture sampler uniform location.
    public var samplerY = GLuint()
    /// UV (chroma) texture sampler uniform location.
    public var samplerUV = GLuint()

    /// Creates and compiles the shader program.
    public init() {
        let glProgram = GLProgram()
        program = glProgram.compileShaders(vertexShaderName: "vertexShader", fragmentShaderName: "fragmentShader")
        glUseProgram(program)

        // Vertex Shader
        position = GLuint(glGetAttribLocation(program, "position"))
        glEnableVertexAttribArray(position)
        texCoord = GLuint(glGetAttribLocation(program, "texCoord"))
        glEnableVertexAttribArray(texCoord)
        modelViewProjectionMatrix = GLint(glGetUniformLocation(program, "modelViewProjectionMatrix"))

        // Fragment Shader
        samplerY = GLuint(glGetUniformLocation(program, "samplerY"))
        samplerUV = GLuint(glGetUniformLocation(program, "samplerUV"))
    }
}
