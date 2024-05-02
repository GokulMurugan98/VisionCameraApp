//
//  ViewController.swift
//  TestCameraApp
//
//  Created by Gokul Murugan on 02/05/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    //MARK: Simple Camera Variables
    //Capture Session
    var session:AVCaptureSession?
    //Photo Output
    let output = AVCapturePhotoOutput()
    //Preview Layer
    let previewLayer = AVCaptureVideoPreviewLayer()
    //Shutter Button
    let shutterButtuon:UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        button.layer.cornerRadius = 50
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    //MARK: Vision Variables

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.layer.addSublayer(previewLayer)
        view.addSubview(shutterButtuon)
        checkPermission()
        shutterButtuon.addTarget(self, action: #selector(recordPoses), for: .touchUpInside)
        
    }
}


//Camera Functions

extension ViewController{
    
    override func viewDidLayoutSubviews() {
        previewLayer.frame = view.bounds
        shutterButtuon.center = CGPoint(x: view.frame.size.width/2,
                                        y: view.frame.size.height - 100)
    }
    
    private func checkPermission(){
        
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) {[weak self] granted in
                guard granted else {return}
                guard let strongSelf = self else {return}
                DispatchQueue.main.async {
                    strongSelf.setupCamera()
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setupCamera()
        @unknown default:
            break
        }
        
        
    }
    
    private func setupCamera(){
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video){
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input){
                    session.addInput(input)
                }
                
                if session.canAddOutput(output){
                    session.addOutput(output)
                }
                
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                
                session.startRunning()
                self.session = session
            }
            catch{
                print(error)
            }
        }
    }
    
    @objc func recordPoses(){
        print("Shutter Button Tapped")
       
    }
}

