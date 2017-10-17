//
//  ARCalendar.swift
//  MeetingScheduleAR
//
//  Created by ernie.cheng on 9/28/17.
//  Copyright © 2017 ernie.cheng. All rights reserved.
//

import ARKit
class ARCalendar: SCNNode {
    
    func loadModal() {
        guard let virtualObjectScene = SCNScene(named: "art.scnassets/realCalBG.scn") else {return}
        let wrapperNode = SCNNode()
        // get all the nodes in the asset and add it into the wrapperNode
        for child in virtualObjectScene.rootNode.childNodes {
            wrapperNode.addChildNode(child)
        }
        addChildNode(wrapperNode)
    }
}
