//
//  SceneView.swift
//  SnapChatClone
//
//  Created by Dima on 12.08.2020.
//  Copyright © 2020 chi. All rights reserved.
//

import ARKit
import SwiftUI

struct SceneView: UIViewRepresentable {
    
    private var handler: SceneHandler
    
    init(handler: SceneHandler) {
        self.handler = handler
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        let configuration = ARFaceTrackingConfiguration()
        uiView.session.run(configuration)
    }
    
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.delegate = handler
        
        handler.view = sceneView
        
        return sceneView
    }
}
