//
//  ViewController.swift
//  CoreMLExample
//
//  Created by Chihiro on 2018/01/31.
//  Copyright © 2018 chicn. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    // Connect UI to code
    // @IBOutlet weak var classificationText: UILabel!
    // @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var cameraView: UIView!

    private var requests = [VNRequest]()
    private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        guard
            let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: backCamera)
            else { return session }
        session.addInput(input)
        return session
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.cameraView?.layer.addSublayer(self.cameraLayer)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MyQueue"))
        self.captureSession.addOutput(videoOutput)
        self.captureSession.startRunning()
        setupVision()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.cameraLayer.frame = self.cameraView?.bounds ?? .zero
    }

    func setupVision() {
        guard let visionModel = try? VNCoreMLModel(for: MtcnnFaceDetector().model)
            else { fatalError("Can't load VisionML model") }
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: handleClassifications)
        //classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
        self.requests = [classificationRequest]
    }

    func handleClassifications(request: VNRequest, error: Error?) {
        guard let observations = request.results
            else { print("no results: \(error!)"); return }
        let classifications = observations[0...4]
            .flatMap({ $0 as? VNClassificationObservation })
            .filter({ $0.confidence > 0.3 })
            .sorted(by: { $0.confidence > $1.confidence })
            .map {
                (prediction: VNClassificationObservation) -> String in
                return "\(round(prediction.confidence * 100 * 100)/100)%: \(prediction.identifier)"
        }
//        DispatchQueue.main.async {
//            print(classifications.joined(separator: "###"))
//            self.classificationText.text = classifications.joined(separator: "\n")
//        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        var requestOptions:[VNImageOption : Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:cameraIntrinsicData]
        }

        //let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: 1, options: requestOptions)
        //let orientation = CGImagePropertyOrientation(rawValue: 1)
        //let imageRequestHandler = VNImageRequestHandler(CVPixelBuffer: pixelBuffer, orientation: Int32(orientation.rawBalue))
        let imageRequestHandler = VNImageRequestHandler(CVPielBuffer: pixelBuffer, options: requestOptions)
        //Argument labels '(CVPielBuffer:, options:)' do not match any available overloads
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


extension UIImage {

}
