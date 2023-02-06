//
//  ViewController.swift
//  Fisheye
//
//  Created by Hanton Yang on 2/6/23.
//

#version 300 es

precision mediump float;

uniform sampler2D samplerY;
uniform sampler2D samplerUV;

in vec2 textureCoordinate;

out vec4 fragmentColor;

void main() {
  mediump vec3 yuv;
  lowp vec3 rgb;
  
  // For digital component video the color format YCbCr is used.
  // ITU-R BT.709, which is the standard for HDTV.
  // http://www.equasys.de/colorconversion.html
  yuv.x = texture(samplerY, textureCoordinate).r - (16.0 / 255.0);
  yuv.yz = texture(samplerUV, textureCoordinate).ra - vec2(128.0 / 255.0, 128.0 / 255.0);
  rgb = mat3(1.164, 1.164, 1.164,
             0.0, -0.213, 2.112,
             1.793, -0.533, 0.0) * yuv;
  
  fragmentColor = vec4(rgb, 1);
}
