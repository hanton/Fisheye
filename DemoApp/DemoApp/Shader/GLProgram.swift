//
//  ViewController.swift
//  Fisheye
//
//  Created by Hanton Yang on 2/6/23.
//

import Foundation
import OpenGLES.ES3

class GLProgram {
    private var programHandle: GLuint = 0
    private var vertexShader: GLuint = 0
    private var fragmentShader: GLuint = 0

    func compileShaders(vertexShaderName: String, fragmentShaderName: String) -> GLuint {
        programHandle = glCreateProgram()

        if !compileShader(&vertexShader, type: GLenum(GL_VERTEX_SHADER), file: Bundle.main.path(forResource: vertexShaderName, ofType: "glsl")!) {
            print("vertex shader failure")
        }

        if !compileShader(&fragmentShader, type: GLenum(GL_FRAGMENT_SHADER), file: Bundle.main.path(forResource: fragmentShaderName, ofType: "glsl")!) {
            print("fragment shader failure")
        }

        glAttachShader(programHandle, vertexShader)
        glAttachShader(programHandle, fragmentShader)

        if !link() {
            print("link failure")
        }

        return programHandle
    }

    private func link() -> Bool {
        var status: GLint = 0

        glLinkProgram(programHandle)
        glGetProgramiv(programHandle, GLenum(GL_LINK_STATUS), &status)

        if status == GL_FALSE {
            return false
        }

        if vertexShader > 0 {
            glDeleteShader(vertexShader)
            vertexShader = 0
        }

        if fragmentShader > 0 {
            glDeleteShader(fragmentShader)
            fragmentShader = 0
        }

        return true
    }

    private func compileShader(_ shader: inout GLuint, type: GLenum, file: String) -> Bool {
        var status: GLint = 0
        var source: UnsafePointer<Int8>

        do {
            source = try NSString(contentsOfFile: file, encoding: String.Encoding.utf8.rawValue).utf8String!
        } catch {
            print("failed to load shader")
            return false
        }

        var castSource: UnsafePointer<GLchar>? = UnsafePointer<GLchar>(source)

        shader = glCreateShader(type)
        glShaderSource(shader, 1, &castSource, nil)
        glCompileShader(shader)
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)

        if status == GL_FALSE {
            glDeleteShader(shader)
            return false
        }

        return true
    }
}
