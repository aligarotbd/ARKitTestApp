//
//  SceneHandler.swift
//  SnapChatClone
//
//  Created by Dima on 12.08.2020.
//  Copyright © 2020 chi. All rights reserved.
//

import ARKit

class SceneHandler: NSObject, ARSCNViewDelegate {
    
    var view: ARSCNView?
    
    private lazy var recorder = ScreenRecorderService()
    
    func startRecord() {
        guard let view = view else {
            return
        }
        
        recorder.start(view: view)
    }
    
    func stopRecord() {
        recorder.stop()
        recorder.saveAsVideo()
    }
    
    func updateFeatures(for node: SCNNode, using anchor: ARFaceAnchor) {
        
        let leftEyePosition = SCNVector3(anchor.leftEyeTransform.columns.3.x, anchor.leftEyeTransform.columns.3.y, anchor.leftEyeTransform.columns.3.z)
        let leftEyeNode = node.childNode(withName: leftEyeName, recursively: true)
        leftEyeNode?.position = leftEyePosition
        
        let rightEyePosition = SCNVector3(anchor.rightEyeTransform.columns.3.x, anchor.rightEyeTransform.columns.3.y, anchor.rightEyeTransform.columns.3.z)
        let rightEyeNode = node.childNode(withName: rightEyeName, recursively: true)
        rightEyeNode?.position = rightEyePosition
        
        let leftEyeScaleX = leftEyeNode?.scale.x ?? 1.0
        let leftEyeBlinkValue = anchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
        leftEyeNode?.scale = SCNVector3(leftEyeScaleX, 1.0 - leftEyeBlinkValue, 1.0)
        
        let rightEyeScaleX = rightEyeNode?.scale.x ?? 1.0
        let rightEyeBlinkValue = anchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
        rightEyeNode?.scale = SCNVector3(rightEyeScaleX, 1.0 - rightEyeBlinkValue, 1.0)
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let device: MTLDevice!
        device = MTLCreateSystemDefaultDevice()
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return nil
        }
        let faceGeometry = ARSCNFaceGeometry(device: device)
        let node = SCNNode(geometry: faceGeometry)
        //        node.geometry?.firstMaterial?.fillMode = .fill
        node.geometry?.firstMaterial?.transparency = 0.0
        
        let leftEyeNode = MaskNode(with: eyeImageName)
        leftEyeNode.name = leftEyeName
        node.addChildNode(leftEyeNode)
        
        let rightEyeNode = MaskNode(with: eyeImageName)
        rightEyeNode.name = rightEyeName
        node.addChildNode(rightEyeNode)
        
        updateFeatures(for: node, using: faceAnchor)
        
        return node
    }
    
    func renderer(
        _ renderer: SCNSceneRenderer,
        didUpdate node: SCNNode,
        for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
                return
        }
        
        faceGeometry.update(from: faceAnchor.geometry)
        updateFeatures(for: node, using: faceAnchor)
    }
}
