//
//  ViewController.swift
//  Fisheye
//
//  Created by Hanton Yang on 2/6/23.
//

import Foundation
import GLKit

class Shader {
    var program: GLuint = 0
    // Vertex Shader
    var position = GLuint()
    var texCoord = GLuint()
    var modelViewProjectionMatrix = GLint()
    // Fragment Shader
    var samplerY = GLuint()
    var samplerUV = GLuint()

    init() {
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
