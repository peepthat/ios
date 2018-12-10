//
//  CameraViewController.swift
//  Peep
//
//  Created by Regynald Augustin on 11/22/18.
//  Copyright © 2018 Regynald Augustin. All rights reserved.
//

import AVFoundation
import UIKit

class CameraViewController: UIViewController {

    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var cameraButton: UIButton!
    
    var captureSession: AVCaptureSession!
    
    // Inputs
    var rearCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    var currentCaptureDevice: AVCaptureDevice!
    
    // Outputs
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var capturedPhoto: AVCapturePhoto?
    
    let cameraToggleGestureRecognizer = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1920x1080
        
        rearCamera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
        if rearCamera == nil {
            // Device without dual rear cameras (iPhone XR, 8, 8 plus, etc.)
            rearCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
        
        frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        
        // Using rear camera is default
        currentCaptureDevice = frontCamera
        
        do {
            guard currentCaptureDevice != nil else { return }
            let input = try AVCaptureDeviceInput(device: currentCaptureDevice)
            
            stillImageOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
            cameraPreviewView.addGestureRecognizer(cameraToggleGestureRecognizer)
        } catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
        
        cameraToggleGestureRecognizer.numberOfTapsRequired = 2
        cameraToggleGestureRecognizer.addTarget(self, action: #selector(toggleCamera))
        
        setupCameraButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? ResultsViewController else { return }
        guard let imageData = capturedPhoto?.fileDataRepresentation() else { return }
        
        let image = UIImage(data: imageData)
        destination.capturedImage = image
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        cameraPreviewView.layer.addSublayer(videoPreviewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.cameraPreviewView.bounds
            }
        }
    }
    
    func setupCameraButton() {
        cameraButton.backgroundColor = .clear
        
        let outerBorder = CALayer()
        outerBorder.backgroundColor = UIColor.clear.cgColor
        outerBorder.borderColor = UIColor.white.cgColor
        outerBorder.borderWidth = 6.0
        outerBorder.bounds = cameraButton.bounds
        outerBorder.position = CGPoint(x: cameraButton.bounds.midX, y: cameraButton.bounds.midY)
        outerBorder.cornerRadius = cameraButton.frame.size.width / 2
        cameraButton.layer.insertSublayer(outerBorder, at: 1)
        
        let innerBorder = CALayer()
        innerBorder.borderColor = UIColor.gray.cgColor
        innerBorder.borderWidth = 0.5
        innerBorder.bounds = cameraButton.bounds
        innerBorder.position = CGPoint(x: cameraButton.bounds.midX, y: cameraButton.bounds.midY)
        innerBorder.cornerRadius = (cameraButton.frame.size.width - 6) / 2
        cameraButton.layer.insertSublayer(innerBorder, at: 0)
    }
    
    @objc func toggleCamera() {
        captureSession.beginConfiguration()
        
        let newCaptureDevice = (currentCaptureDevice.position == .back) ? frontCamera : rearCamera
        
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        
        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: newCaptureDevice!)
        } catch let error  {
            print("Error Unable to switch camera:  \(error.localizedDescription)")
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        currentCaptureDevice = newCaptureDevice
        captureSession.commitConfiguration()
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        capturedPhoto = photo
        performSegue(withIdentifier: Constants.ShowResultsSegue, sender: nil)
    }
}
