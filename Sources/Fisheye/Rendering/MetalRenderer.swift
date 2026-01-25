//
//  MetalRenderer.swift
//  Fisheye
//
//  Created by Hanton Yang on 1/24/26.
//
//  Renders 360-degree video content using Metal.
//

import CoreVideo
import Foundation
import Metal
import MetalKit

/// Renders 360-degree video content using Metal.
public class MetalRenderer {
    // MARK: - Metal Core

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?

    // MARK: - Model and Configuration

    private let model: Sphere
    private let fieldOfView: Float

    // MARK: - Buffers

    private var vertexBuffer: MTLBuffer?
    private var texCoordBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?

    // MARK: - Textures

    private var lumaTexture: CVMetalTexture?
    private var chromaTexture: CVMetalTexture?
    private var videoTextureCache: CVMetalTextureCache?

    // MARK: - Transform

    private var viewportSize: CGSize = CGSize(width: 375, height: 667)

    struct Uniforms {
        var modelViewProjectionMatrix: simd_float4x4
    }

    // MARK: - Initialization

    /// Creates a new Metal renderer.
    ///
    /// - Parameters:
    ///   - device: The Metal device to use for rendering.
    ///   - model: The sphere model for video projection.
    ///   - fieldOfView: Field of view in degrees. Default is 60.
    public init(device: MTLDevice, model: Sphere, fieldOfView: Float = 60.0) {
        self.device = device
        self.model = model
        self.fieldOfView = fieldOfView

        guard let queue = device.makeCommandQueue() else {
            fatalError("Failed to create Metal command queue")
        }
        self.commandQueue = queue

        createBuffers()
        createPipelineState()
        createTextureCache()
    }

    // MARK: - Setup

    private func createBuffers() {
        // Vertex buffer
        let vertexDataSize = model.vertices.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: model.vertices,
                                         length: vertexDataSize,
                                         options: .storageModeShared)
        vertexBuffer?.label = "Vertex Buffer"

        // Texture coordinate buffer
        let texCoordDataSize = model.texCoords.count * MemoryLayout<Float>.size
        texCoordBuffer = device.makeBuffer(bytes: model.texCoords,
                                           length: texCoordDataSize,
                                           options: .storageModeShared)
        texCoordBuffer?.label = "TexCoord Buffer"

        // Index buffer
        let indexDataSize = model.indices.count * MemoryLayout<UInt16>.size
        indexBuffer = device.makeBuffer(bytes: model.indices,
                                        length: indexDataSize,
                                        options: .storageModeShared)
        indexBuffer?.label = "Index Buffer"

        // Uniform buffer
        let uniformBufferSize = MemoryLayout<Uniforms>.size
        uniformBuffer = device.makeBuffer(length: uniformBufferSize,
                                          options: .storageModeShared)
        uniformBuffer?.label = "Uniform Buffer"
    }

    private func createPipelineState() {
        // Load the Metal library - try module bundle first, then fall back to default
        let library: MTLLibrary

        #if SWIFT_PACKAGE
        // For Swift Packages, load from Bundle.module
        if let libraryURL = Bundle.module.url(forResource: "default", withExtension: "metallib"),
           let moduleLibrary = try? device.makeLibrary(URL: libraryURL) {
            library = moduleLibrary
        } else if let defaultLibrary = device.makeDefaultLibrary() {
            // Fallback to default library
            library = defaultLibrary
        } else {
            fatalError("Failed to load Metal library. Tried Bundle.module and default library.")
        }
        #else
        // For non-SPM builds, use the default library
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            fatalError("Failed to create default Metal library")
        }
        library = defaultLibrary
        #endif

        guard let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
            let availableFunctions = library.functionNames.joined(separator: ", ")
            fatalError("Failed to load shader functions. Available: [\(availableFunctions)]")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()

        // Position attribute (attribute 0)
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        // TexCoord attribute (attribute 1)
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = 0
        vertexDescriptor.attributes[1].bufferIndex = 1

        // Vertex buffer layout
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 3
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        // TexCoord buffer layout
        vertexDescriptor.layouts[1].stride = MemoryLayout<Float>.size * 2
        vertexDescriptor.layouts[1].stepRate = 1
        vertexDescriptor.layouts[1].stepFunction = .perVertex

        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }

    private func createTextureCache() {
        CVMetalTextureCacheCreate(kCFAllocatorDefault,
                                  nil,
                                  device,
                                  nil,
                                  &videoTextureCache)
    }

    // MARK: - Public Methods

    /// Sets the viewport size for aspect ratio calculation.
    ///
    /// - Parameter size: The new viewport size.
    public func setViewportSize(_ size: CGSize) {
        viewportSize = size
    }

    /// Updates the video texture from a pixel buffer.
    ///
    /// - Parameter pixelBuffer: The video frame pixel buffer.
    public func updateTexture(_ pixelBuffer: CVPixelBuffer) {
        guard let textureCache = videoTextureCache else { return }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        cleanTextures()

        // Create Y (luma) texture
        var yTextureRef: CVMetalTexture?
        let yResult = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .r8Unorm,
            width,
            height,
            0,
            &yTextureRef
        )

        guard yResult == kCVReturnSuccess else {
            return
        }

        lumaTexture = yTextureRef

        // Create UV (chroma) texture
        var uvTextureRef: CVMetalTexture?
        let uvResult = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .rg8Unorm,
            width / 2,
            height / 2,
            1,
            &uvTextureRef
        )

        guard uvResult == kCVReturnSuccess else {
            return
        }

        chromaTexture = uvTextureRef
    }

    /// Updates the model-view-projection matrix based on rotation.
    ///
    /// - Parameters:
    ///   - rotationX: Rotation around the X axis in radians.
    ///   - rotationY: Rotation around the Y axis in radians.
    public func updateModelViewProjectionMatrix(_ rotationX: Float, _ rotationY: Float) {
        let aspect = abs(Float(viewportSize.width) / Float(viewportSize.height))
        let nearZ: Float = 0.1
        let farZ: Float = 100.0
        let fieldOfViewInRadians = simd_float4x4.degreesToRadians(fieldOfView)

        let projectionMatrix = simd_float4x4.perspectiveProjection(
            fovY: fieldOfViewInRadians,
            aspect: aspect,
            nearZ: nearZ,
            farZ: farZ
        )

        var modelViewMatrix = matrix_identity_float4x4
        modelViewMatrix = simd_float4x4.rotationX(rotationX) * modelViewMatrix
        modelViewMatrix = simd_float4x4.rotationY(rotationY) * modelViewMatrix

        let mvpMatrix = projectionMatrix * modelViewMatrix

        // Update uniform buffer
        guard let uniformBuffer = uniformBuffer else { return }
        let uniforms = Uniforms(modelViewProjectionMatrix: mvpMatrix)
        memcpy(uniformBuffer.contents(), [uniforms], MemoryLayout<Uniforms>.size)
    }

    /// Renders the current frame.
    ///
    /// - Parameters:
    ///   - view: The MTKView to render into.
    ///   - commandBuffer: The command buffer to encode rendering commands.
    @MainActor
    public func render(in view: MTKView, commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let pipelineState = pipelineState,
              let vertexBuffer = vertexBuffer,
              let texCoordBuffer = texCoordBuffer,
              let indexBuffer = indexBuffer,
              let uniformBuffer = uniformBuffer else {
            return
        }

        guard let yTexture = lumaTexture.flatMap({ CVMetalTextureGetTexture($0) }),
              let uvTexture = chromaTexture.flatMap({ CVMetalTextureGetTexture($0) }) else {
            // Textures not ready yet - this is normal during initialization
            return
        }

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.label = "Fisheye Render Encoder"

        renderEncoder?.setRenderPipelineState(pipelineState)

        // Set vertex buffers
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder?.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
        renderEncoder?.setVertexBuffer(uniformBuffer, offset: 0, index: 2)

        // Set fragment textures
        renderEncoder?.setFragmentTexture(yTexture, index: 0)
        renderEncoder?.setFragmentTexture(uvTexture, index: 1)

        // Draw
        renderEncoder?.drawIndexedPrimitives(
            type: .triangle,
            indexCount: model.indexCount,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )

        renderEncoder?.endEncoding()

        commandBuffer.present(drawable)
    }

    // MARK: - Private Methods

    private func cleanTextures() {
        lumaTexture = nil
        chromaTexture = nil

        if let textureCache = videoTextureCache {
            CVMetalTextureCacheFlush(textureCache, 0)
        }
    }
}
