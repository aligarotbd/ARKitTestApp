//
//  Recorder.swift
//  SnapChatClone
//
//  Created by Dima on 11.08.2020.
//  Copyright © 2020 chi. All rights reserved.
//

import ARKit
import Foundation
import AVFoundation
import UIKit
import Photos

class ScreenRecorderService {

    private var timer: Timer?
    private var view : ARSCNView?
    private var frames = [Int : UIImage]()
    private var currentFrameIndex = 0
    private var urls = [URL]()
    private(set) var recording = false
    private var writeQueue: DispatchQueue?
    
    func start(view: ARSCNView) {
        self.view = view
        self.recording = true
        
        timer = Timer.scheduledTimer(timeInterval: 1/15, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        frames.removeAll()
        urls.removeAll()
        currentFrameIndex = 0
        
        writeQueue = DispatchQueue.global(qos: .userInitiated)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        
        while !frames.values.isEmpty {
            sleep(1)
        }
        
        recording = false
    }
    
    @objc private func update() {
        if recording, let view = self.view {
            let snapshot = view.snapshot()
            frames[currentFrameIndex] = snapshot
            let snapshotIndex = currentFrameIndex
            currentFrameIndex += 1
            writeQueue?.async {
                
                guard let data = snapshot.jpegData(compressionQuality: 0.3) else {
                    return
                }
                let url = URL(fileURLWithPath: "\(ImagesToVideoUtils.path)/tempimage\(self.urls.count + 1).png")
                
                try? data.write(to: url)
                
                self.urls.append(url)
                self.frames.removeValue(forKey: snapshotIndex)
            }
        }
    }
    
    func saveAsVideo() {
        generateVideoUrl(complete: { (fileURL:URL) in
            
            self.saveVideo(url: fileURL, complete: {saved in
                print("Video is saved \(saved)")
            })
        })
    }
    
    private func generateVideoUrl(complete: @escaping(_:URL)->()) {
        guard let image = try? UIImage(data: Data(contentsOf: urls[0])) else {
            return
        }
        
        let settings = ImagesToVideoUtils.videoSettings(codec: AVVideoCodecType.jpeg.rawValue /*AVVideoCodecH264*/, width: (image.cgImage?.width)!, height: (image.cgImage?.height)!)
        let movieMaker = ImagesToVideoUtils(videoSettings: settings)
        
        movieMaker.frameTime = CMTimeMake(value: 1, timescale: Int32(60 / 5))
        movieMaker.createMovieFrom(urls: urls) { (fileURL:URL) in
            complete(fileURL)
        }
    }
    
    private func saveVideo(url: URL, complete:@escaping(_:Bool)->()) {
        PHPhotoLibrary.requestAuthorization { (status) -> Void in
                switch (status) {
                case .authorized:
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    }) { saved, error in
                        complete(saved)
                    }
                    
                default:
                    print("Restricted")
                }
        }
    }
}


typealias CXEMovieMakerCompletion = (URL) -> Void
typealias CXEMovieMakerUIImageExtractor = (AnyObject) -> UIImage?


public class ImagesToVideoUtils: NSObject {
    
    static let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
    static let tempPath = path + "/exprotvideo.mp4"
    static let fileURL = URL(fileURLWithPath: tempPath)
    
    var frameTime: CMTime!
    
    private var assetWriter: AVAssetWriter!
    private var writeInput: AVAssetWriterInput!
    private var bufferAdapter: AVAssetWriterInputPixelBufferAdaptor!
    private var videoSettings: [String : Any]!
    
    var completionBlock: ((URL) -> Void)?
    var movieMakerUIImageExtractor: ((AnyObject) -> UIImage?)?
    
    public class func videoSettings(codec:String, width:Int, height:Int) -> [String: Any]{
        let videoSettings:[String: Any] = [AVVideoCodecKey: AVVideoCodecType.jpeg, //AVVideoCodecH264,
                                           AVVideoWidthKey: width,
                                           AVVideoHeightKey: height]
        return videoSettings
    }
    
    public init(videoSettings: [String: Any]) {
        super.init()
        

        if(FileManager.default.fileExists(atPath: ImagesToVideoUtils.tempPath)){
            guard (try? FileManager.default.removeItem(atPath: ImagesToVideoUtils.tempPath)) != nil else {
                print("remove path failed")
                return
            }
        }
        
        
        self.assetWriter = try! AVAssetWriter(url: ImagesToVideoUtils.fileURL, fileType: AVFileType.mov)
        
        self.videoSettings = videoSettings
        self.writeInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        assert(self.assetWriter.canAdd(self.writeInput), "add failed")
        
        self.assetWriter.add(self.writeInput)
        let bufferAttributes:[String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB)]
        self.bufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.writeInput, sourcePixelBufferAttributes: bufferAttributes)
        self.frameTime = CMTimeMake(value: 1, timescale: 5)
    }
    
    func createMovieFrom(urls: [URL], withCompletion: @escaping CXEMovieMakerCompletion){
        self.createMovieFromSource(images: urls as [AnyObject], extractor:{(inputObject:AnyObject) ->UIImage? in
            return UIImage(data: try! Data(contentsOf: inputObject as! URL))}, withCompletion: withCompletion)
    }
    
    func createMovieFrom(images: [UIImage], withCompletion: @escaping CXEMovieMakerCompletion){
        self.createMovieFromSource(images: images, extractor: {(inputObject:AnyObject) -> UIImage? in
            return inputObject as? UIImage}, withCompletion: withCompletion)
    }
    
    func createMovieFromSource(images: [AnyObject], extractor: @escaping CXEMovieMakerUIImageExtractor, withCompletion: @escaping CXEMovieMakerCompletion){
        self.completionBlock = withCompletion
        
        self.assetWriter.startWriting()
        self.assetWriter.startSession(atSourceTime: CMTime.zero)
        
        let mediaInputQueue = DispatchQueue(label: "mediaInputQueue")
        var i = 0
        let frameNumber = images.count
        
        self.writeInput.requestMediaDataWhenReady(on: mediaInputQueue){
            while(true){
                if(i >= frameNumber){
                    break
                }
                
                if (self.writeInput.isReadyForMoreMediaData){
                    var sampleBuffer:CVPixelBuffer?
                    autoreleasepool {
                        let img = extractor(images[i])
                        if img == nil{
                            i += 1
                            //continue
                        }
                        sampleBuffer = self.newPixelBufferFrom(cgImage: img!.cgImage!)
                    }
                    if (sampleBuffer != nil){
                        if(i == 0){
                            self.bufferAdapter.append(sampleBuffer!, withPresentationTime: CMTime.zero)
                        }else{
                            let value = i - 1
                            let lastTime = CMTimeMake(value: Int64(value), timescale: self.frameTime.timescale)
                            let presentTime = CMTimeAdd(lastTime, self.frameTime)
                            self.bufferAdapter.append(sampleBuffer!, withPresentationTime: presentTime)
                        }
                        i = i + 1
                    }
                }
            }
            self.writeInput.markAsFinished()
            self.assetWriter.finishWriting {
                DispatchQueue.main.sync {
                    self.completionBlock!(ImagesToVideoUtils.fileURL)
                }
            }
        }
    }
    
    func newPixelBufferFrom(cgImage:CGImage) -> CVPixelBuffer? {
        let options:[String: Any] = [kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true]
        var pxbuffer:CVPixelBuffer?
        let frameWidth = self.videoSettings[AVVideoWidthKey] as! Int
        let frameHeight = self.videoSettings[AVVideoHeightKey] as! Int
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, frameWidth, frameHeight, kCVPixelFormatType_32ARGB, options as CFDictionary?, &pxbuffer)
        assert(status == kCVReturnSuccess && pxbuffer != nil, "newPixelBuffer failed")
        
        CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pxdata = CVPixelBufferGetBaseAddress(pxbuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata, width: frameWidth, height: frameHeight, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        assert(context != nil, "context is nil")
        
        context!.concatenate(CGAffineTransform.identity)
        context!.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pxbuffer
    }
}
