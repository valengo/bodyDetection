//
//  ViewController.swift
//  bodyDetection
//
//  Created by Andressa Valengo on 22/10/19.
//  Copyright © 2019 Andressa Valengo. All rights reserved.
//

import UIKit
import RealityKit
import ARKit
import Combine

class CustomSphere: Entity, HasModel {
     required init(color: UIColor, radius: Float) {
       super.init()
       self.components[ModelComponent] = ModelComponent(
         mesh: .generateSphere(radius: radius),
         materials: [SimpleMaterial(
           color: color,
           isMetallic: false)
         ]
       )
     }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}

class JointViewModel {
    var name: ARSkeleton.JointName
    var transform: simd_float4x4
    var point: CGPoint
    
    init(name: ARSkeleton.JointName, transform: simd_float4x4, point: CGPoint) {
        self.name = name
        self.transform = transform
        self.point = point
    }
}

class ViewController: UIViewController {
    
    enum SceneState {
        case looking
        case detectingStart
        case dectingEnd
        case trackingStart
    }
    
    var sceneState: SceneState = .looking
    
    @IBOutlet weak var distancesTextView: UITextView!
    @IBOutlet weak var stateMessage: UILabel!
    @IBOutlet var arView: ARView!
    @IBOutlet weak var segmentationImage: UIImageView!
    @IBOutlet weak var startRecordingStateImage: UIImageView!
    @IBOutlet weak var stopRecordingStateImage: UIImageView!
        
    let jointNames: [ARSkeleton.JointName] = [.root, .spine2, .spine3, .spine4, .spine5, .spine6, .spine7]
    let context = CIContext(options: nil)
        
    var jointDots = [CAShapeLayer]()
    var jointProjections = [ARSkeleton.JointName: JointViewModel]()
    var estimationDots = [CAShapeLayer]()
    var addedSpheres = [CustomSphere]()
    
    var corePointsDistance = [ARSkeleton.JointName: CGFloat]()
    
    let spheresAnchor = AnchorEntity()
    
    var bodyAnchor: ARBodyAnchor?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        arView.session.delegate = self
        
        distancesTextView.text = ""
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }
        
        // arView.debugOptions = [.showAnchorGeometry, .showAnchorOrigins, .showWorldOrigin]
    }
    
    func toggleCamera() {
        startRecordingStateImage.isHidden = !startRecordingStateImage.isHidden
        stopRecordingStateImage.isHidden = !stopRecordingStateImage.isHidden
    }
    
    @IBAction func cameraButtonTap(_ sender: Any) {
        switch sceneState {
        case .looking:
            sceneState = .detectingStart
            detectBody()
        case .detectingStart:
            sceneState = .dectingEnd
        case .dectingEnd:
            sceneState = .trackingStart
            detectJoints()
        case .trackingStart:
            sceneState = .looking
            estimateScale()
            estimateCoreScale()
        }
        toggleCamera()
        setStateMessage()
    }
    
    func setStateMessage() {
        if sceneState == .detectingStart {
            stateMessage.text = "Detecting body..."
        } else if sceneState == .trackingStart {
            stateMessage.text = "Detecting joints..."
        } else {
            stateMessage.text = ""
        }
    }
    
    @IBAction func resetState() {
        sceneState = .looking
        segmentationImage.image = nil
        hideAllJoints2D()
        setStateMessage()
        hideEstimationDots()
        distancesTextView.text = ""
        
        startRecordingStateImage.isHidden = false
        stopRecordingStateImage.isHidden = true
        
        addedSpheres.forEach {
            $0.removeFromParent()
        }
        addedSpheres.removeAll()
    }
    
    func detectJoints() {
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        arView.scene.addAnchor(spheresAnchor)
    }
    
    func detectBody() {
        let config = ARWorldTrackingConfiguration()
        config.frameSemantics = [.personSegmentation]
        arView.session.run(config)
    }
    
    @IBAction func hideAllJoints2D() {
        jointDots.forEach {
            $0.removeFromSuperlayer()
        }
        jointDots.removeAll()
    }
    
    @IBAction func hideEstimationDots() {
        estimationDots.forEach {
            $0.removeFromSuperlayer()
        }
        estimationDots.removeAll()
    }
    
    @IBAction func toggleSegmentationImageContentMode() {
        if segmentationImage.contentMode == .scaleAspectFit {
            segmentationImage.contentMode = .scaleAspectFill
        } else {
            segmentationImage.contentMode = .scaleAspectFit
        }
    }

    @IBAction func showAllJoints2D() {
        guard let anchors = arView.session.currentFrame?.anchors else {return}
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor {
                self.bodyAnchor = bodyAnchor
                
                hideAllJoints2D()
                
                let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                
                for jointName in jointNames {
                    if let transform = bodyAnchor.skeleton.modelTransform(for: jointName) {
                        let position = bodyPosition + simd_make_float3(transform.columns.3)
                        print("original \(jointName.rawValue): \(position)")
                        let projection = arView.project([position.x, position.y, position.z])!
                        
                        let shapeLayer = CAShapeLayer();
                        shapeLayer.path = UIBezierPath(ovalIn: CGRect(x: CGFloat(projection.x), y: CGFloat(projection.y), width: 3, height: 3)).cgPath;
                        shapeLayer.fillColor = UIColor.green.cgColor
                        view.layer.addSublayer(shapeLayer)
                        jointDots.append(shapeLayer)
                        
                        jointProjections[jointName] = JointViewModel(name: jointName, transform: transform, point: projection)
                    }
                }
            }
        }
    }

    func estimatePoint(pointsOfInterest: [CGPoint], cgImage: CGImage) {
        if let colors = cgImage.colors(at: pointsOfInterest) {
            for i in 0..<colors.count {
                let color = colors[i]
                let point = pointsOfInterest[i]
                let offset = abs(segmentationImage.aspectFillSize.width - segmentationImage.frame.size.width) / 2
                let xProportion = segmentationImage.aspectFillSize.width / CGFloat(cgImage.width)
                let yProportion = segmentationImage.aspectFillSize.height / CGFloat(cgImage.height)
                let projection = CGPoint(x: point.x * xProportion, y: point.y * yProportion)
                if color.rgba.blue == 1 && color.rgba.red == 1 && color.rgba.green == 1 {
                    let shapeLayer = CAShapeLayer();
                    shapeLayer.path = UIBezierPath(ovalIn: CGRect(x: CGFloat(projection.x) - offset, y: CGFloat(projection.y), width: 3, height: 3)).cgPath;
                    shapeLayer.fillColor = UIColor.red.cgColor
                    view.layer.addSublayer(shapeLayer)
                    estimationDots.append(shapeLayer)
                } else {
                    let shapeLayer = CAShapeLayer();
                    shapeLayer.path = UIBezierPath(ovalIn: CGRect(x: CGFloat(projection.x) - offset, y: CGFloat(projection.y), width: 3, height: 3)).cgPath;
                    shapeLayer.fillColor = UIColor.blue.cgColor
                    view.layer.addSublayer(shapeLayer)
                    estimationDots.append(shapeLayer)
                }
            }
        } else {
            print("Error when trying to retrieve colors from image!")
        }
    }
    
    func estimateScale() {
        if let image = segmentationImage.image, let cgImage = image.cgImage {
            for jointName in jointNames {
                if let point = jointProjections[jointName]?.point {
                    let xProportion = CGFloat(cgImage.width) / view.frame.size.width
                    let yProportion = CGFloat(cgImage.height) / view.frame.size.height
                    let projection = CGPoint(x: point.x * xProportion, y: point.y * yProportion)
                    var pointsOfInterest = [CGPoint]()
                    for i in Int(point.x)...Int(view.frame.width)  {
                        pointsOfInterest.append(CGPoint(x: CGFloat(i) * xProportion, y: projection.y))
                    }
                    estimatePoint(pointsOfInterest: pointsOfInterest, cgImage: cgImage)
                    pointsOfInterest.removeAll()
                    for i in 0...Int(view.frame.width)/2 {
                        pointsOfInterest.append(CGPoint(x: CGFloat(i) * xProportion, y: projection.y))
                    }
                    estimatePoint(pointsOfInterest: pointsOfInterest, cgImage: cgImage)
                }
            }
        }
    }
    
    func normalize(_ matrix: float4x4) -> float4x4 {
        var normalized = matrix
        normalized.columns.0 = simd.normalize(normalized.columns.0)
        normalized.columns.1 = simd.normalize(normalized.columns.1)
        normalized.columns.2 = simd.normalize(normalized.columns.2)
        return normalized
    }
    
    func estimateMaxPoint(of pointsOfInterest: [CGPoint], in cgImage: CGImage) -> CGPoint? {
        if let colors = cgImage.colors(at: pointsOfInterest) {
            let offset = abs(segmentationImage.aspectFillSize.width - segmentationImage.frame.size.width) / 2
            let xProportion = segmentationImage.aspectFillSize.width / CGFloat(cgImage.width)
            let yProportion = segmentationImage.aspectFillSize.height / CGFloat(cgImage.height)
            
            for i in 0..<colors.count {
                let color = colors[i]
                let point = pointsOfInterest[i]
                let projection = CGPoint(x: point.x * xProportion, y: point.y * yProportion)
                if color.rgba.blue != 1 || color.rgba.red != 1 || color.rgba.green != 1 {
                    return CGPoint(x: CGFloat(projection.x) - offset, y: CGFloat(projection.y))
                }
            }
        }
        return nil
    }
    
    func checkSize(left: CGPoint, right: CGPoint) {
        guard let camera = arView.session.currentFrame?.camera, let bodyAnchor = bodyAnchor else {return}
        
        if let leftUnp = camera.unprojectPoint(left, ontoPlane: bodyAnchor.transform, orientation: .portrait, viewportSize: view.frame.size),
            let rightUnp = camera.unprojectPoint(right, ontoPlane: bodyAnchor.transform, orientation: .portrait, viewportSize: view.frame.size) {
            let rotation = Transform(matrix: bodyAnchor.transform).rotation
            let scale: simd_float3 = [1, 1, 1]
            addSphere(radius: 0.025, anchor: spheresAnchor, transform: Transform(scale: scale, rotation: rotation, translation: leftUnp))
            addSphere(radius: 0.025, anchor: spheresAnchor, transform: Transform(scale: scale, rotation: rotation, translation: rightUnp))
            
            distancesTextView.text.append(contentsOf: "root (unprojection) -> 3D \(CGFloat(simd_distance(rightUnp, leftUnp)).fomatted())\n")
        }
    }
    
    func addSphere(radius: Float, anchor: AnchorEntity, transform: Transform) {
        let sphere = CustomSphere(color: .systemPink, radius: radius)
        sphere.transform = transform
        anchor.addChild(sphere, preservingWorldTransform: true)
        addedSpheres.append(sphere)
    }
    
    func estimateCoreScale() {
        
        guard let rootData = jointProjections[.root],
            let spine7data = jointProjections[.spine7] else {return}
        
        let distance3D = CGFloat(simd_distance(spine7data.transform.columns.3, rootData.transform.columns.3))
        let distance2D = spine7data.point.distanceTo(rootData.point)
        let scaleProportion = distance3D / distance2D
        
        distancesTextView.text.append(contentsOf: "Estimated distances:\n")
        distancesTextView.text.append(contentsOf: "Core height -> 2D: \(distance2D.fomatted()); 3D \(distance3D.fomatted())\n")
        
        if let image = segmentationImage.image, let cgImage = image.cgImage {
            for jointName in jointNames {
                let xProportion = CGFloat(cgImage.width) / view.frame.size.width
                let yProportion = CGFloat(cgImage.height) / view.frame.size.height
                if let screenPoint = jointProjections[jointName]?.point {
                    let projectedScreenPoint = CGPoint(x: screenPoint.x * xProportion, y: screenPoint.y * yProportion)
                    var pointsOfInterest = [CGPoint]()
                    for i in Int(screenPoint.x)...Int(view.frame.width)  {
                        pointsOfInterest.append(CGPoint(x: CGFloat(i) * xProportion, y: projectedScreenPoint.y))
                    }
                    let rightPoint = estimateMaxPoint(of: pointsOfInterest, in: cgImage)
                    pointsOfInterest.removeAll()
                    
                    for i in 0...Int(view.frame.width)/2 {
                        pointsOfInterest.append(CGPoint(x: CGFloat(i) * xProportion, y: projectedScreenPoint.y))
                    }
                    let leftPoint = estimateMaxPoint(of: pointsOfInterest.reversed(), in: cgImage)
                    
                    if let rightPoint = rightPoint, let leftPoint = leftPoint {
                        if jointName == .root {
                            checkSize(left: leftPoint, right: rightPoint)
                        }
                        let distanceBetweenPoints = rightPoint.distanceTo(leftPoint)
                        corePointsDistance[jointName] = distanceBetweenPoints
                        distancesTextView.text.append(contentsOf: "\(jointName.rawValue) -> 2D: \(distanceBetweenPoints.fomatted()); 3D \((distanceBetweenPoints * scaleProportion).fomatted())\n")
                    }
                    
                }
            }
        }
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if sceneState == .detectingStart, let segmentationBuffer = frame.segmentationBuffer {
            if let image = UIImage(pixelBuffer: segmentationBuffer)?.rotate(radians: .pi / 2) {
                segmentationImage.image = image
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let _ = anchor as? ARBodyAnchor else {continue}
            if sceneState == .trackingStart {
                    showAllJoints2D()
            }
        }
    }
}
