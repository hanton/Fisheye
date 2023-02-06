//
//  ViewController.swift
//  Fisheye
//
//  Created by Hanton Yang on 2/6/23.
//

#version 300 es

uniform mat4 modelViewProjectionMatrix;

in vec4 position;
in vec2 texCoord;

out vec2 textureCoordinate;

void main() {
  textureCoordinate = texCoord;
  gl_Position = modelViewProjectionMatrix * position;
}
