//
//  Shaders.metal
//  Fisheye
//
//  Created by Hanton Yang on 1/24/26.
//
//  Metal shaders for 360-degree video rendering.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float4x4 modelViewProjectionMatrix;
};

struct VertexIn {
    float3 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShader(VertexIn in [[stage_in]],
                               constant Uniforms& uniforms [[buffer(2)]]) {
    VertexOut out;
    out.position = uniforms.modelViewProjectionMatrix * float4(in.position, 1.0);
    out.texCoord = in.texCoord;
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<float> samplerY [[texture(0)]],
                               texture2d<float> samplerUV [[texture(1)]]) {
    constexpr sampler textureSampler(mag_filter::linear,
                                     min_filter::linear,
                                     address::clamp_to_edge);

    // Sample Y and UV textures
    float y = samplerY.sample(textureSampler, in.texCoord).r;
    float2 uv = samplerUV.sample(textureSampler, in.texCoord).rg;

    // YUV to RGB conversion (ITU-R BT.709 - matches OpenGL exactly)
    // For digital component video the color format YCbCr is used.
    // ITU-R BT.709, which is the standard for HDTV.
    // http://www.equasys.de/colorconversion.html
    float3 yuv;
    yuv.x = y - (16.0 / 255.0);
    yuv.yz = uv - float2(128.0 / 255.0);

    float3x3 conversionMatrix = float3x3(
        float3(1.164,  1.164,  1.164),
        float3(0.0,   -0.213,  2.112),
        float3(1.793, -0.533,  0.0)
    );

    float3 rgb = conversionMatrix * yuv;
    return float4(rgb, 1.0);
}
