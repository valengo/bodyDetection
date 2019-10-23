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

class ViewController: UIViewController {
    
    enum SceneState {
        case looking
        case detectingStart
        case dectingEnd
        case trackingStart
    }
    
    var sceneState: SceneState = .looking
    
    @IBOutlet weak var stateMessage: UILabel!
    @IBOutlet var arView: ARView!
    @IBOutlet weak var segmentationImage: UIImageView!
    @IBOutlet weak var startRecordingStateImage: UIImageView!
    @IBOutlet weak var stopRecordingStateImage: UIImageView!
    
    var segmentationBuffer: CVPixelBuffer?
    var estimatedDepthData: CVPixelBuffer?
    var frameSegmentationImage: UIImage?
    
    var jointDots = [CAShapeLayer]()
    
    let characterAnchor = AnchorEntity()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        arView.session.delegate = self
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }
        detectBody()
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
        toggleCamera()
        setStateMessage()
    }
    
    func detectJoints() {
        arView.session.run(ARBodyTrackingConfiguration())
        arView.scene.addAnchor(characterAnchor)
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
    
    @IBAction func showAllJoints2D() {
        guard let anchors = arView.session.currentFrame?.anchors else {return}
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor,
                let frame = arView.session.currentFrame {
                
                hideAllJoints2D()
                
                let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                
                for transform in bodyAnchor.skeleton.jointModelTransforms {
                    let position = bodyPosition + simd_make_float3(transform.columns.3)
                    let projection = frame.camera.projectPoint([position.x, position.y, bodyPosition.z], orientation: .portrait, viewportSize: view.bounds.size)
                    let shapeLayer = CAShapeLayer();
                    shapeLayer.path = UIBezierPath(ovalIn: CGRect(x: CGFloat(projection.x), y: CGFloat(projection.y), width: 10, height: 10)).cgPath;
                    shapeLayer.fillColor = UIColor.green.cgColor
                    view.layer.addSublayer(shapeLayer)
                    jointDots.append(shapeLayer)
                }
            }
        }
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if sceneState == .detectingStart, let segmentationBuffer = frame.segmentationBuffer {
            if let image = UIImage(pixelBuffer: segmentationBuffer) {
                self.segmentationImage.image = image.rotate(radians: .pi / 2)
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
