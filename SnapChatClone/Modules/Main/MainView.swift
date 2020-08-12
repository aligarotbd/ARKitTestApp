//
//  MainView.swift
//  SnapChatClone
//
//  Created by Dima on 11.08.2020.
//  Copyright © 2020 chi. All rights reserved.
//

import SwiftUI
import ReplayKit
import UIKit
import ARKit

let leftEyeName = "leftEye"
let rightEyeName = "rightEye"
let eyeImageName = "eye"

struct MainView: View {
        
    let sceneHandler = SceneHandler()
    let recorderService = ScreenRecorderService()

    @State var presentingModal = false
    @State var isStartRecord = false
    
    var body: some View {
        ZStack {
            SceneView(handler: sceneHandler)
                .edgesIgnoringSafeArea([.all])
            VStack {
                Spacer()
                Button(action: {
                    if self.isStartRecord {
                        self.stopRecording()
                    } else {
                        self.startRecording()
                    }
                    self.isStartRecord = !self.isStartRecord
                }) {
                    recordButton()
                }
            }
        }
    }
    
    private func recordButton() -> some View {
        let size: CGFloat = isStartRecord ? 40 : 60
        
        return Circle()
        .fill(Color.red)
        .frame(width: size, height: size)
        .cornerRadius(self.isStartRecord ? 0 : 40)
        .padding(isStartRecord ? 10 : 0)
        .overlay(
            RoundedRectangle(cornerRadius: 50)
                .stroke(Color.white, lineWidth: 5)
                        .frame(width: 70, height: 70))
    }
    
    func startRecording() {
        sceneHandler.startRecord()
    }
    
    func stopRecording() {
        sceneHandler.stopRecord()
    }
}
