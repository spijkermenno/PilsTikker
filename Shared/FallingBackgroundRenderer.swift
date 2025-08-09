//
//  FallingBackgroundRenderer.swift
//  Cheesery iOS
//
//  Created by Menno Spijker on 09/08/2025.
//

import Foundation
import Metal
import MetalKit
import simd
import UIKit

final class FallingBackgroundRenderer: NSObject, MTKViewDelegate {

    // MARK: - Config
    var spawnRatePerSecond: Float = 0             // set from game loop (bier/sec)
    var maxParticles: Int = 1_000                 // safety cap
    var fallSpeedRange: ClosedRange<Float> = 120...220
    var xDriftRange: ClosedRange<Float> = -20...20
    var angularVelRange: ClosedRange<Float> = -1.5...1.5
    var scaleRange: ClosedRange<Float> = 0.5...1.2
    var textureName: String = "FallingBackgroundItem"

    // MARK: - Metal
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private var pipeline: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var instanceBuffer: MTLBuffer!
    private var texture: MTLTexture!
    private var viewportSize = vector_float2(0, 0)

    // MARK: - Particles
    private struct Vertex {
        var position: vector_float2
        var uv: vector_float2
    }
    private struct InstanceData {
        var position: vector_float2   // center
        var scale: Float
        var rotation: Float
        var color: vector_float4
    }
    private struct Particle {
        var pos: SIMD2<Float>
        var vel: SIMD2<Float>
        var rot: Float
        var angVel: Float
        var scale: Float
        var life: Float // seconds until recycle (optional)
    }

    private var particles: [Particle] = []
    private var instances: [InstanceData] = []
    private var lastTime: CFTimeInterval = CACurrentMediaTime()
    private var spawnAccumulator: Float = 0

    // Quad (two triangles)
    private static let quad: [Vertex] = [
        Vertex(position: [-0.5,  0.5], uv: [0, 0]),
        Vertex(position: [ 0.5,  0.5], uv: [1, 0]),
        Vertex(position: [-0.5, -0.5], uv: [0, 1]),
        Vertex(position: [ 0.5,  0.5], uv: [1, 0]),
        Vertex(position: [ 0.5, -0.5], uv: [1, 1]),
        Vertex(position: [-0.5, -0.5], uv: [0, 1]),
    ]

    init(mtkView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            fatalError("Metal not supported on this device.")
        }
        self.device = device
        self.queue = queue

        super.init()

        mtkView.device = device
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.framebufferOnly = true
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0) // transparent

        buildPipeline(view: mtkView)
        buildBuffers()
        loadTexture(named: textureName)
    }

    // MARK: - Setup

    private func buildPipeline(view: MTKView) {
        let library = try! device.makeDefaultLibrary(bundle: .main)
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = library.makeFunction(name: "vs_main")
        desc.fragmentFunction = library.makeFunction(name: "fs_main")
        desc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        desc.colorAttachments[0].isBlendingEnabled = true
        desc.colorAttachments[0].rgbBlendOperation = .add
        desc.colorAttachments[0].alphaBlendOperation = .add
        desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        desc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        pipeline = try! device.makeRenderPipelineState(descriptor: desc)
    }

    private func buildBuffers() {
        let quadSize = MemoryLayout<Vertex>.stride * Self.quad.count
        vertexBuffer = device.makeBuffer(bytes: Self.quad, length: quadSize, options: .storageModeShared)
        instanceBuffer = device.makeBuffer(length: MemoryLayout<InstanceData>.stride * maxParticles, options: .storageModeShared)
    }

    private func loadTexture(named: String) {
        guard let uiImage = UIImage(named: named)?.cgImage else { return }
        let loader = MTKTextureLoader(device: device)
        texture = try? loader.newTexture(cgImage: uiImage, options: [
            MTKTextureLoader.Option.SRGB: false
        ])
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize = .init(Float(size.width), Float(size.height))
    }

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let dt = Float(now - lastTime)
        lastTime = now

        // Spawn particles based on spawnRatePerSecond (can be fractional)
        let rate = min(spawnRatePerSecond, Float(maxParticles))    // clamp rate
        spawnAccumulator += rate * dt
        let spawns = Int(floor(spawnAccumulator))
        if spawns > 0 {
            spawnAccumulator -= Float(spawns)
            spawn(count: spawns)
        }

        // Update particles
        let bottomY = -50.0 as Float
        for i in particles.indices {
            particles[i].pos += particles[i].vel * dt
            particles[i].rot += particles[i].angVel * dt
            particles[i].life -= dt
        }
        // Recycle off-screen/dead
        particles.removeAll { p in
            p.pos.y < bottomY || p.life <= 0
        }

        // Write instances
        instances.removeAll(keepingCapacity: true)
        instances.reserveCapacity(particles.count)
        for p in particles {
            instances.append(InstanceData(
                position: p.pos,
                scale: p.scale,
                rotation: p.rot,
                color: [1, 1, 1, 1]
            ))
        }
        if instances.count == 0 {
            // Nothing to draw, but still present to avoid stalling
            guard let drawable = view.currentDrawable,
                  let passDesc = view.currentRenderPassDescriptor else { return }
            let cmd = queue.makeCommandBuffer()
            let enc = cmd?.makeRenderCommandEncoder(descriptor: passDesc)
            enc?.endEncoding()
            cmd?.present(drawable)
            cmd?.commit()
            return
        }

        // Copy instance data
        let ptr = instanceBuffer.contents().bindMemory(to: InstanceData.self, capacity: instances.count)
        ptr.assign(from: instances, count: instances.count)

        guard let drawable = view.currentDrawable,
              let passDesc = view.currentRenderPassDescriptor else { return }

        let cmd = queue.makeCommandBuffer()
        let enc = cmd?.makeRenderCommandEncoder(descriptor: passDesc)

        enc?.setRenderPipelineState(pipeline)
        enc?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        enc?.setVertexBytes(&viewportSize, length: MemoryLayout<vector_float2>.stride, index: 1)
        enc?.setVertexBuffer(instanceBuffer, offset: 0, index: 2)
        if let texture { enc?.setFragmentTexture(texture, index: 0) }

        enc?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: instances.count)

        enc?.endEncoding()
        cmd?.present(drawable)
        cmd?.commit()
    }

    // MARK: - Spawning

    private func spawn(count: Int) {
        guard viewportSize.x > 0, viewportSize.y > 0 else { return }
        let cap = max(0, maxParticles - particles.count)
        let toSpawn = min(count, cap)
        guard toSpawn > 0 else { return }

        for _ in 0..<toSpawn {
            let x = Float.random(in: 0...viewportSize.x)
            let y = viewportSize.y + 40
            let vy = -Float.random(in: fallSpeedRange)
            let vx = Float.random(in: xDriftRange)
            let rot = Float.random(in: 0...(2 * .pi))
            let ang = Float.random(in: angularVelRange)
            let scale = Float.random(in: scaleRange)
            let life: Float = (viewportSize.y + 120) / max(40, -vy)  // seconds until off-screen

            particles.append(Particle(
                pos: [x, y],
                vel: [vx, vy],
                rot: rot,
                angVel: ang,
                scale: scale,
                life: life
            ))
        }
    }
}
