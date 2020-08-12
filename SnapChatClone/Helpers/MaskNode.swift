//
//  MaskNode.swift
//  SnapChatClone
//
//  Created by Dima on 10.08.2020.
//  Copyright © 2020 chi. All rights reserved.
//

import SceneKit

class MaskNode: SCNNode {
    
    init(with name: String, width: CGFloat = 0.045, height: CGFloat = 0.03) {
        super.init()
        
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents =  UIImage(named: name)
        plane.firstMaterial?.isDoubleSided = true
        
        geometry = plane
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

