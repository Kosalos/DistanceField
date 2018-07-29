import UIKit
import Metal

class ViewController: UIViewController {
    var control = Control()
    var cBuffer:MTLBuffer! = nil
    
    var timer = Timer()
    var outTexture: MTLTexture!
    let bytesPerPixel: Int = 4
    var pipeline1: MTLComputePipelineState!
    let queue = DispatchQueue(label: "Queue")
    lazy var device: MTLDevice! = MTLCreateSystemDefaultDevice()
    lazy var commandQueue: MTLCommandQueue! = { return self.device.makeCommandQueue() }()
    var circleMove:Bool = false
    var cameraX:Float = 0.0
    var cameraY:Float = 0.0
    var cameraZ:Float = 0.0
    var focusX:Float = 0.0
    var focusY:Float = 0.0
    var focusZ:Float = 0.0
    var dist1000:Float = 0.0
    
    let SIZE:Int = 768
    
    let threadGroupCount = MTLSizeMake(8,8,1) //12,12,1)
    lazy var threadGroups: MTLSize = { MTLSizeMake(SIZE / threadGroupCount.width, SIZE / threadGroupCount.height, 1) }()
    
    @IBOutlet var metalTextureView: MetalTextureView!
    @IBOutlet var resetButton: UIButton!
    @IBOutlet var circleButton: UIButton!
    @IBOutlet var dCameraXY: DeltaView!
    @IBOutlet var sCameraZ: SliderView!
    @IBOutlet var dFocusXY: DeltaView!
    @IBOutlet var sFocusZ: SliderView!
    @IBOutlet var sZoom: SliderView!
    @IBOutlet var sDist: SliderView!
    @IBOutlet var sP1: SliderView!
    @IBOutlet var sP2: SliderView!
    @IBOutlet var sP3: SliderView!
    @IBOutlet var sP4: SliderView!
    @IBOutlet var sP5: SliderView!
    @IBOutlet var sP6: SliderView!
    @IBOutlet var sP7: SliderView!
    @IBOutlet var sP8: SliderView!
    @IBOutlet var sP9: SliderView!
    @IBOutlet var sPA: SliderView!
    @IBOutlet var sPB: SliderView!
    @IBOutlet var sPC: SliderView!

    @IBAction func resetButtonPressed(_ sender: UIButton) { reset() }
    
    var sList:[SliderView]! = nil
    var dList:[DeltaView]! = nil
    
    //MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let defaultLibrary:MTLLibrary! = self.device.makeDefaultLibrary()
            guard let kf1 = defaultLibrary.makeFunction(name: "rayMarchShader")  else { fatalError() }
            pipeline1 = try device.makeComputePipelineState(function: kf1)
        }
        catch { print("Unexpected error: \(error).") } //fatalError("error creating pipelines") }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb,
            width: SIZE,
            height: SIZE,
            mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]

        outTexture = self.device.makeTexture(descriptor: textureDescriptor)!
        metalTextureView.initialize(outTexture)
        
        cBuffer = device.makeBuffer(bytes: &control, length: MemoryLayout<Control>.stride, options: MTLResourceOptions.storageModeShared)
        
        layoutViews()
        setControlPointer(&control)
        initializeObjs()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        sList = [ sCameraZ,sFocusZ,sZoom,sDist,sP1,sP2,sP3,sP4,sP5,sP6,sP7,sP8,sP9,sPA,sPB,sPC ]
        dList = [ dCameraXY,dFocusXY ]
        
        let cameraMin:Float = -5
        let cameraMax:Float = 5
        let focusMin:Float = -10
        let focusMax:Float = 10
        let zoomMin:Float = 0.001
        let zoomMax:Float = 1
        let distMin:Float = 0.00001 * 1000
        let distMax:Float = 0.03 * 1000
        let sPmin:Float = 0.01
        let sPmax:Float = 1
        let sPchg:Float = 0.6
        
        dCameraXY.initializeFloat1(&cameraX, cameraMin, cameraMax, 1, "Cam XY")
        dCameraXY.initializeFloat2(&cameraY)
        sCameraZ.initializeFloat(&cameraZ, .delta, cameraMin, cameraMax, 1, "Cam Z")
        dFocusXY.initializeFloat1(&focusX, focusMin,focusMax, 1, "Foc XY")
        dFocusXY.initializeFloat2(&focusY)
        sFocusZ.initializeFloat(&focusZ, .delta, focusMin, focusMax, 1, "Foc Z")
        sZoom.initializeFloat(&control.zoom, .delta, zoomMin, zoomMax, 2, "Zoom")
        sDist.initializeFloat(&dist1000, .direct, distMin, distMax, 0.1, "minDist")
        sP1.initializeFloat(&control.p1,.delta, sPmin,sPmax,sPchg, "P1")
        sP2.initializeFloat(&control.p2,.delta, sPmin,sPmax,sPchg, "P2")
        sP3.initializeFloat(&control.p3,.delta, sPmin,sPmax,sPchg, "P3")
        sP4.initializeFloat(&control.p4,.delta, sPmin,sPmax,sPchg, "P4")
        sP5.initializeFloat(&control.p5,.delta, sPmin,sPmax,sPchg, "P5")
        sP6.initializeFloat(&control.p6,.delta, sPmin,sPmax,sPchg, "P6")
        sP7.initializeFloat(&control.p7,.delta, sPmin,sPmax,sPchg, "P7")
        sP8.initializeFloat(&control.p8,.delta, sPmin,sPmax,sPchg, "P8")
        sP9.initializeFloat(&control.p9,.delta, sPmin,sPmax,sPchg, "P9")
        sPA.initializeFloat(&control.pA,.delta, sPmin,sPmax,sPchg, "PA")
        sPB.initializeFloat(&control.pB,.delta, sPmin,sPmax,sPchg, "PB")
        sPC.initializeFloat(&control.pC,.delta, sPmin,sPmax,sPchg, "Size")

        reset()
        Timer.scheduledTimer(withTimeInterval:0.05, repeats:true) { timer in self.timerHandler() }
    }
    
    //MARK: -
    
    var oldXS:CGFloat = 0
    
    @objc func layoutViews() {
        let xs:CGFloat = view.bounds.width
        let ys:CGFloat = view.bounds.height
        
        let cxs:CGFloat = 200
        let cxs2:CGFloat = cxs/2 - 3
        let cys:CGFloat = 100
        let bys:CGFloat = 25    // slider height
        let gap:CGFloat = 3
        
        var x:CGFloat = xs-cxs-100  // leave some empty space to the right of widgets
        var y:CGFloat = 10
        
        func frame(_ xs:CGFloat, _ ys:CGFloat, _ dx:CGFloat, _ dy:CGFloat) -> CGRect {
            let r = CGRect(x:x, y:y, width:xs, height:ys)
            x += dx; y += dy
            return r
        }
        
        metalTextureView.frame = CGRect(x:0, y:0, width:x-10, height:ys)
        
        dCameraXY.frame = frame(cxs,cys,0,cys+gap)
        sCameraZ.frame  = frame(cxs,bys,0,bys+gap)
        y += 20
        dFocusXY.frame = frame(cxs,cys,0,cys+gap)
        sFocusZ.frame  = frame(cxs,bys,0,bys+gap)
        y += 20
        sZoom.frame  = frame(cxs,bys,0,bys+gap)
        sDist.frame  = frame(cxs,bys,0,bys+gap)
        y += 20
        let x2 = x
        let y2 = y
        sP1.frame  = frame(cxs2,bys,0,bys+gap)
        sP2.frame  = frame(cxs2,bys,0,bys+gap)
        sP3.frame  = frame(cxs2,bys,0,bys+gap)
        sP4.frame  = frame(cxs2,bys,0,bys+gap)
        sP5.frame  = frame(cxs2,bys,0,bys+gap)
        sP6.frame  = frame(cxs2,bys,0,bys+gap)
        x += cxs2+3
        y = y2
        sP7.frame  = frame(cxs2,bys,0,bys+gap)
        sP8.frame  = frame(cxs2,bys,0,bys+gap)
        sP9.frame  = frame(cxs2,bys,0,bys+gap)
        sPA.frame  = frame(cxs2,bys,0,bys+gap)
        sPB.frame  = frame(cxs2,bys,0,bys+gap)
        sPC.frame  = frame(cxs2,bys,0,bys+gap)
        x = x2
        y += 10
        circleButton.frame  = frame(cxs,bys,0,bys+gap)
        resetButton.frame  = frame(cxs,bys,0,bys+gap)
    }
    
    func reset() {
        control.camera = vector_float3(1.59,3.89,0.75)
        control.focus = vector_float3(-0.52,-1.22,-0.31)
        control.zoom = 0.6141
        control.size = Int32(SIZE) // image size
        control.power = 8
        control.minimumStepDistance = 0.003
        dist1000 = control.minimumStepDistance * 1000.0
        control.p1 = 0.5
        control.p2 = 0.5
        control.p3 = 0.5
        control.p4 = 0.5
        control.p5 = 0.5
        control.p6 = 0.5
        control.p7 = 0.5
        control.p8 = 0.5
        control.p9 = 0.5
        control.pA = 0.5
        control.pB = 0.5
        control.pC = 0.5  // sphere size

        unWrapFloat3()
        
        for s in sList { s.setNeedsDisplay() }
        for d in dList { d.setNeedsDisplay() }
    }
    
    //MARK: -
    
    func unWrapFloat3() {
        cameraX = control.camera.x
        cameraY = control.camera.y
        cameraZ = control.camera.z
        focusX = control.focus.x
        focusY = control.focus.y
        focusZ = control.focus.z
    }
    
    func wrapFloat3() {
        control.camera.x = cameraX
        control.camera.y = cameraY
        control.camera.z = cameraZ
        control.focus.x = focusX
        control.focus.y = focusY
        control.focus.z = focusZ
        control.minimumStepDistance = dist1000 / 1000.0
    }
    
    //MARK: -
    
    let bColors:[UIColor] = [ UIColor(red:0.5, green:0.5, blue:0.5, alpha:1),  UIColor(red:1, green:0, blue:0.0, alpha:1) ]
    func updateCircleButton() { circleButton.setTitleColor(bColors[Int(circleMove ? 1 : 0)], for:[]) }
    
    var circleDistance = Float()
    var circleAngle = Float()
    
    @IBAction func circleButtonPressed(_ sender: UIButton) {
        circleMove = !circleMove
        updateCircleButton()
        
        if circleMove {
            circleDistance = sqrtf(control.camera.x * control.camera.x + control.camera.z * control.camera.z)
            circleAngle = Float.pi + atan2f(control.focus.z - control.camera.z, control.focus.x - control.camera.x)
            unWrapFloat3()
        }
    }
    
    //MARK: -

    @objc func timerHandler() {

        updateObjs()

        if circleMove {
            func alter(_ v :Float) -> Float {
                if (arc4random() & 1023) < 800 { return v }
                var r = v + cosf(circleAngle) / 40
                if r < 0 { r = 0 } else if r > 1 { r = 1 }
                return r
            }
            
            control.p1 = alter(control.p1)
            control.p2 = alter(control.p2)
            control.p3 = alter(control.p3)
            control.p4 = alter(control.p4)
            control.p5 = alter(control.p5)
            control.p6 = alter(control.p6)
            control.p7 = alter(control.p7)
            control.p8 = alter(control.p8)
            control.p9 = alter(control.p9)
            control.pA = alter(control.pA)
            control.pB = alter(control.pB)
            circleAngle += 0.02

            for s in sList { s.setNeedsDisplay() }
        }
        
        for s in sList { _ = s.update() }
        for d in dList { _ = d.update() }

        calcRayMarch()
        metalTextureView.display(metalTextureView.layer)
    }
    
    //MARK: -
    
    var timeAngle:Float = 0
    
    func calcRayMarch() {
        wrapFloat3()
        control.minimumStepDistance = dist1000 / 1000.0
        
        control.time = sinf(timeAngle) * 50
        timeAngle += 0.001
        
        cBuffer.contents().copyMemory(from: &control, byteCount:MemoryLayout<Control>.stride)
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        commandEncoder.setComputePipelineState(pipeline1)
        commandEncoder.setTexture(outTexture, index: 0)
        commandEncoder.setBuffer(cBuffer, offset: 0, index: 0)
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    override var prefersStatusBarHidden: Bool { return true }
}

