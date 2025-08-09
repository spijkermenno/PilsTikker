//
//  GameViewController.swift
//  Cheesery 
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit
import MetalKit

public final class GameViewController: UIViewController {

    // MARK: - Game State

    var bierCount: Double = 0
    var clickCount: Int = 0
    var isShopOpen: Bool = false
    var isSettingsOpen: Bool = false

    // MARK: - Containers & Backgrounds

    var headerContainer: UIView!
    var contentContainer: UIView!
    var headerBackgroundView: UIImageView!
    var contentBackgroundView: UIImageView!
    var fullBackgroundView: UIImageView!   // used when style == .full

    // MARK: - UI Elements

    var imageView: UIImageView!
    var bierCountLabel: UILabel!
    var perSecondLabel: UILabel!
    var shopButton: UIButton!
    var shopView: UIView!
    var settingsButton: UIButton!
    var settingsView: UIView!
    var floatingItemViews: [UIImageView] = []

    // MARK: - Shop (demo data)

    var shopItems: [ShopItem] = [
        ShopItem(
            id: "bierfles",
            name: Localized.Shop.Item.bierfles.name,
            imageName: "bierfles",
            description: Localized.Shop.Item.bierfles.description,
            basePrice: 12,
            productionRate: 0.1
        ),
        ShopItem(
            id: "bierkrat",
            name: Localized.Shop.Item.bierkrat.name,
            imageName: "bierkrat",
            description: Localized.Shop.Item.bierkrat.description,
            basePrice: 24,
            productionRate: 0.3
        ),
        ShopItem(
            id: "bierfust",
            name: Localized.Shop.Item.bierfust.name,
            imageName: "bierfust",
            description: Localized.Shop.Item.bierfust.description,
            basePrice: 120,
            productionRate: 1.0
        )
    ]

    // MARK: - Animation & Timers

    var gameTimer: Timer?
    var itemAnimationTimer: Timer?
    var bounceTimer: Timer?
    var speedBoostTimer: Timer?

    // MARK: - Animation State

    var itemAngle: Double = 0.0
    var itemRotationAngle: Double = 0.0
    var itemRotationOffsets: [Double] = []
    var floatingItemOrder: [String] = []

    var baseRotationSpeed: Double = 0.01
    var currentRotationSpeed: Double = 0.01
    var itemRotationSpeed: Double = -0.00290

    var baseRadius: Double = 110
    var currentRadius: Double = 110
    var bierdopCenterY: CGFloat = 0

    // MARK: - Bounce State

    var bouncePhase: Double = 0.0

    // MARK: - Device Configuration

    var deviceConfig: DeviceConfiguration!
    var ringCapacities: [Int] = []

    // MARK: - Constants

    let keyBierCount = "bierCount"
    let keyLastSaveTime = "lastSaveTime"
    let maxOfflineMinutes: Double = 30.0

    // MARK: - Background Config

    enum BackgroundStyle {
        case split(header: String, content: String) // two images
        case full(image: String)                    // one image fills entire view
    }

    // MARK: - Rain Config

    enum RainDirection { case up, down }
    var rainDirection: RainDirection = .up     // set to .up for bubbles

    // MARK: - Metal "Rain" Background

    private var metalView: MTKView?
    private var rainRenderer: InlineFallingRenderer?
    private var rainSyncTimer: Timer?

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        deviceConfig = getDeviceConfiguration()
        setupRingCapacities()

        // Choose background style here:
        setupContainers(style: .full(image: "background"))
        //setupContainers(style: .split(header: "headerBackground", content: "containerBackground"))

        // ===== Metal background rain behind content =====
        setupMetalRainLayer()

        loadProgress()
        setupUI()           // places labels in header, clicker in content
        setupFloatingItemsAnimation()
        setupShopUI()
        setupSettingsUI()
        setupTimer()
        setupBounceAnimation()
        setupAutosave()

        // keep rain intensity synced to current production rate
        rainSyncTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let perSecond = self.getTotalProductionRate()
            self.rainRenderer?.spawnRatePerSecond = min(Float(perSecond), 200.0)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveProgress),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    deinit {
        gameTimer?.invalidate()
        itemAnimationTimer?.invalidate()
        bounceTimer?.invalidate()
        speedBoostTimer?.invalidate()
        rainSyncTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Containers

private extension GameViewController {
    func setupContainers(style: BackgroundStyle) {
        view.backgroundColor = .black

        // Always create containers; background style only affects which imageViews we add.
        headerContainer = UIView()
        contentContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        // If full background: add it behind both containers
        switch style {
        case .full(let imageName):
            fullBackgroundView = UIImageView(image: UIImage(named: imageName))
            fullBackgroundView.contentMode = .scaleAspectFill
            fullBackgroundView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(fullBackgroundView)
            NSLayoutConstraint.activate([
                fullBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
                fullBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                fullBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                fullBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])

        case .split:
            fullBackgroundView = nil
        }

        view.addSubview(headerContainer)
        view.addSubview(contentContainer)

        let headerHeight: CGFloat = 140 * deviceConfig.bierdopScale

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: headerHeight),

            contentContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Add backgrounds according to style
        switch style {
        case .split(let headerImage, let contentImage):
            headerBackgroundView = UIImageView(image: UIImage(named: headerImage))
            headerBackgroundView.contentMode = .scaleAspectFill
            headerBackgroundView.translatesAutoresizingMaskIntoConstraints = false
            headerContainer.addSubview(headerBackgroundView)

            contentBackgroundView = UIImageView(image: UIImage(named: contentImage))
            contentBackgroundView.contentMode = .scaleAspectFill
            contentBackgroundView.translatesAutoresizingMaskIntoConstraints = false
            contentContainer.addSubview(contentBackgroundView)

            NSLayoutConstraint.activate([
                headerBackgroundView.topAnchor.constraint(equalTo: headerContainer.topAnchor),
                headerBackgroundView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
                headerBackgroundView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
                headerBackgroundView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),

                contentBackgroundView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
                contentBackgroundView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
                contentBackgroundView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
                contentBackgroundView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            ])

        case .full:
            headerBackgroundView = nil
            contentBackgroundView = nil
        }

        // Ensure layout so contentContainer bounds are valid early
        view.layoutIfNeeded()
    }
}

// MARK: - Metal Rain Layer

private extension GameViewController {
    func setupMetalRainLayer() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            // Metal not supported, skip gracefully
            return
        }

        let mtk = MTKView(frame: .zero, device: device)
        mtk.translatesAutoresizingMaskIntoConstraints = false
        mtk.isOpaque = false
        mtk.enableSetNeedsDisplay = false
        mtk.framebufferOnly = true
        mtk.preferredFramesPerSecond = 60
        mtk.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        // Put the Metal view ABOVE the content background (if any), but BELOW game UI
        if let bg = contentBackgroundView {
            contentContainer.insertSubview(mtk, aboveSubview: bg)
        } else {
            contentContainer.addSubview(mtk)
            contentContainer.sendSubviewToBack(mtk)
        }

        NSLayoutConstraint.activate([
            mtk.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            mtk.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            mtk.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            mtk.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
        ])

        let renderer = InlineFallingRenderer(mtkView: mtk, textureName: "FallingBackgroundItem")
        renderer?.direction = (rainDirection == .down) ? .down : .up
        self.metalView = mtk
        self.rainRenderer = renderer
    }
}

// MARK: - Inline Metal Renderer (no .metal file needed)

private final class InlineFallingRenderer: NSObject, MTKViewDelegate {

    // Direction
    enum Direction { case up, down }
    var direction: Direction = .down

    // Config
    var spawnRatePerSecond: Float = 0            // externally set (bier/sec)
    var maxParticles: Int = 1000
    var fallSpeedRange: ClosedRange<Float> = 120...220
    var xDriftRange: ClosedRange<Float> = -20...20
    var angularVelRange: ClosedRange<Float> = -1.5...1.5
    var scaleRange: ClosedRange<Float> = 0.5...1.2

    // Metal
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private weak var view: MTKView?
    private var pipeline: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var instanceBuffer: MTLBuffer!
    private var texture: MTLTexture?

    // Data
    private struct Vertex { var position: SIMD2<Float>; var uv: SIMD2<Float> }
    private struct InstanceData {
        var position: SIMD2<Float>
        var scale: Float
        var rotation: Float
        var color: SIMD4<Float>
    }
    private struct Particle {
        var pos: SIMD2<Float>
        var vel: SIMD2<Float>
        var rot: Float
        var angVel: Float
        var scale: Float
        var life: Float
    }

    private var particles: [Particle] = []
    private var instanceCapacity: Int = 0
    private var viewport: SIMD2<Float> = .zero
    private var lastTime: CFTimeInterval = CACurrentMediaTime()
    private var spawnAccumulator: Float = 0

    // Quad
    private static let quad: [Vertex] = [
        Vertex(position: [-0.5,  0.5], uv: [0, 0]),
        Vertex(position: [ 0.5,  0.5], uv: [1, 0]),
        Vertex(position: [-0.5, -0.5], uv: [0, 1]),
        Vertex(position: [ 0.5,  0.5], uv: [1, 0]),
        Vertex(position: [ 0.5, -0.5], uv: [1, 1]),
        Vertex(position: [-0.5, -0.5], uv: [0, 1]),
    ]

    init?(mtkView: MTKView, textureName: String) {
        guard let device = mtkView.device,
              let queue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.queue = queue
        self.view = mtkView

        super.init()

        mtkView.delegate = self

        buildPipeline()
        buildBuffers()
        loadTexture(named: textureName)
    }

    private func buildPipeline() {
        // Compile tiny shader inline (no .metal file required)
        let src = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexIn { float2 position; float2 uv; };
        struct InstanceData { float2 position; float scale; float rotation; float4 color; };
        struct VSOut { float4 position [[position]]; float2 uv; float4 color; };

        vertex VSOut vs_main(
            const device VertexIn*      vtx  [[buffer(0)]],
            constant float2&            vp   [[buffer(1)]],
            const device InstanceData*  inst [[buffer(2)]],
            uint vid [[vertex_id]],
            uint iid [[instance_id]]
        ) {
            VertexIn v = vtx[vid];
            InstanceData I = inst[iid];
            float2 p = v.position * I.scale * 42.0;   // base size ~42px
            float s = sin(I.rotation), c = cos(I.rotation);
            float2 pr = float2(p.x * c - p.y * s, p.x * s + p.y * c);
            float2 pixel = I.position + pr;
            float2 ndc = float2((pixel.x / vp.x) * 2.0 - 1.0, (pixel.y / vp.y) * 2.0 - 1.0);

            VSOut o;
            o.position = float4(ndc.x, -ndc.y, 0, 1); // flip Y to match UIKit
            o.uv = v.uv;
            o.color = I.color;
            return o;
        }

        fragment float4 fs_main(VSOut in [[stage_in]], texture2d<float> tex [[texture(0)]]) {
            constexpr sampler s(address::clamp_to_edge, filter::linear);
            float4 c = tex.sample(s, in.uv);
            return float4(c.rgb, c.a) * in.color;
        }
        """

        do {
            let lib = try device.makeLibrary(source: src, options: nil)
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction = lib.makeFunction(name: "vs_main")
            desc.fragmentFunction = lib.makeFunction(name: "fs_main")
            desc.colorAttachments[0].pixelFormat = view?.colorPixelFormat ?? .bgra8Unorm
            desc.colorAttachments[0].isBlendingEnabled = true
            desc.colorAttachments[0].rgbBlendOperation = .add
            desc.colorAttachments[0].alphaBlendOperation = .add
            desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            desc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            pipeline = try device.makeRenderPipelineState(descriptor: desc)
        } catch {
            print("Metal pipeline error: \(error)")
        }
    }

    private func buildBuffers() {
        let vbSize = MemoryLayout<Vertex>.stride * Self.quad.count
        let vb = device.makeBuffer(bytes: Self.quad, length: vbSize, options: .storageModeShared)
        vertexBuffer = vb
        reserveInstances(capacity: 256)
    }

    private func reserveInstances(capacity: Int) {
        instanceCapacity = max(64, capacity)
        instanceBuffer = device.makeBuffer(length: MemoryLayout<InstanceData>.stride * instanceCapacity, options: .storageModeShared)
    }

    private func loadTexture(named: String) {
        guard let cg = UIImage(named: named)?.cgImage else {
            print("⚠️ Missing texture: \(named)")
            return
        }
        let loader = MTKTextureLoader(device: device)
        texture = try? loader.newTexture(cgImage: cg, options: [MTKTextureLoader.Option.SRGB: false])
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewport = SIMD2(Float(size.width), Float(size.height))
    }

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let dt = Float(now - lastTime)
        lastTime = now

        // Spawn
        let rate = min(spawnRatePerSecond, Float(maxParticles))
        spawnAccumulator += rate * dt
        let spawns = Int(floor(spawnAccumulator))
        if spawns > 0 {
            spawnAccumulator -= Float(spawns)
            spawn(count: spawns)
        }

        // Update
        for i in particles.indices {
            particles[i].pos += particles[i].vel * dt
            particles[i].rot += particles[i].angVel * dt
            particles[i].life -= dt
        }

        // Remove out-of-bounds depending on direction
        switch direction {
        case .down:
            particles.removeAll { $0.pos.y > viewport.y + 60 || $0.life <= 0 }
        case .up:
            particles.removeAll { $0.pos.y < -60 || $0.life <= 0 }
        }

        // Ensure capacity
        if particles.count > instanceCapacity {
            reserveInstances(capacity: min(particles.count * 2, maxParticles))
        }

        // Instance upload
        let count = min(particles.count, instanceCapacity)
        if count == 0 {
            guard let drawable = view.currentDrawable,
                  let rp = view.currentRenderPassDescriptor else { return }
            let cmd = queue.makeCommandBuffer()
            let enc = cmd?.makeRenderCommandEncoder(descriptor: rp)
            enc?.endEncoding()
            cmd?.present(drawable)
            cmd?.commit()
            return
        }

        let instancesPtr = instanceBuffer.contents().bindMemory(to: InstanceData.self, capacity: count)
        for (i, p) in particles.prefix(count).enumerated() {
            instancesPtr[i] = InstanceData(position: p.pos,
                                           scale: p.scale,
                                           rotation: p.rot,
                                           color: SIMD4(1, 1, 1, 1))
        }

        // Draw
        guard let drawable = view.currentDrawable,
              let rp = view.currentRenderPassDescriptor else { return }
        var vp = viewport
        let cmd = queue.makeCommandBuffer()
        let enc = cmd?.makeRenderCommandEncoder(descriptor: rp)
        enc?.setRenderPipelineState(pipeline)
        enc?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        enc?.setVertexBytes(&vp, length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
        enc?.setVertexBuffer(instanceBuffer, offset: 0, index: 2)
        if let texture { enc?.setFragmentTexture(texture, index: 0) }
        enc?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: count)
        enc?.endEncoding()
        cmd?.present(drawable)
        cmd?.commit()
    }

    // MARK: - Spawning

    private func spawn(count: Int) {
        guard viewport.x > 0, viewport.y > 0 else { return }
        let cap = max(0, maxParticles - particles.count)
        let toSpawn = min(count, cap)
        guard toSpawn > 0 else { return }

        for _ in 0..<toSpawn {
            let x = Float.random(in: 0...viewport.x)

            let startY: Float
            let vy: Float
            switch direction {
            case .down:
                startY = -40                               // just above the top
                vy = Float.random(in: fallSpeedRange)      // positive => falling down
            case .up:
                startY = viewport.y + 40                   // just below the bottom
                vy = -Float.random(in: fallSpeedRange)     // negative => moving up
            }

            let vx = Float.random(in: xDriftRange)
            let rot = Float.random(in: 0...(2 * .pi))
            let ang = Float.random(in: angularVelRange)
            let scale = Float.random(in: scaleRange)
            let life: Float = (viewport.y + 120) / max(40, abs(vy))

            particles.append(Particle(
                pos: SIMD2(x, startY),
                vel: SIMD2(vx, vy),
                rot: rot,
                angVel: ang,
                scale: scale,
                life: life
            ))
        }
    }
}
