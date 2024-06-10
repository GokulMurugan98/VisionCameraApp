//
//  ViewController.swift
//  TestCameraApp
//
//  Created by Gokul Murugan on 02/05/24.
//

import UIKit
import AVFoundation
import MLKit

class VisionCameraViewController: UIViewController {
    
    //MARK: Simple Camera Variables
    
    //To Check Which Camer to use
    private var isUsingFrontCamera = false
    //Setting up preview layer
    private var previewLayer: AVCaptureVideoPreviewLayer!
    //Setting up Capture session
    private lazy var captureSession = AVCaptureSession()
    //Initializing session queue
    private lazy var sessionQueue = DispatchQueue(label: Constant.sessionQueueLabel)
    
    let shutterButton:UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        button.layer.cornerRadius = 50
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    let timerRepSelection:UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        button.layer.cornerRadius = 25
        button.layer.borderWidth = 3
        button.setImage(UIImage(systemName: "timer")?.withTintColor(.white), for: .normal)
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    let cameraSwitchButton:UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        button.layer.cornerRadius = 25
        button.layer.borderWidth = 3
        button.setImage(UIImage(systemName: "arrow.triangle.2.circlepath")?.withTintColor(.white), for: .normal)
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    var selectionForExercise:TimeOrRepSelection?
    
    
    //MARK: These Variable Should be define at the start while initializing.
    var typeOfExercise:String = "reps"
    var instructionLabel = "put your phone in vertical direction"
    var gifURL:String = "http://www.gifbin.com/bin/4802swswsw04.gif"
    var apiName:String = "lateral_raises"
    var muscleGroupForReps:[String] = [
        "SHOULDER",
        "HIP",
        "WRIST"
    ]
    var exerciseStartAngle:ExerciseAngles = ExerciseAngles(angle_1: [75,120], angle_2: [250,295])
    var exerciseEndAngle:ExerciseAngles = ExerciseAngles(angle_1: [0,35], angle_2: [325,360])
    var totalRepsToBeCompleted:String = "15"
    var caloriesBurnPerRep:Int = 2
    var repSpeedPerRep:Int = 4
    //MARK: Video rotation based on Portrait or Landscape
    var isPortrait:Bool = false
    
    
    //MARK: Vision Variables
    //    //Setting up the ImageView to display video
    //    private lazy var previewOverlayView: UIImageView = {
    //        precondition(isViewLoaded)
    //        let previewOverlayView = UIImageView(frame: .zero)
    //        previewOverlayView.contentMode = UIView.ContentMode.scaleAspectFill
    //        previewOverlayView.translatesAutoresizingMaskIntoConstraints = false
    //        return previewOverlayView
    //    }()
    //
    //Setting up the layer to show Lines over a person
    private lazy var annotationOverlayView: UIView = {
        precondition(isViewLoaded)
        let annotationOverlayView = UIView(frame: .zero)
        annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
        return annotationOverlayView
    }()
    
    /// Initialized when one of the pose detector rows are chosen. Reset to `nil` when neither are.
    private var poseDetector: PoseDetector? = nil
    //Last camera output is stored here
    private var lastFrame: CMSampleBuffer?
    
    //MARK: API Call Variables
    
    var viewModel:SpeakingBotViewModel?
    
    var cameraPoses = [[[String: Any]]]()
    
    var isPoseDetectionStart:Bool = false
    
    var cameraSwitchButtonUnChanged:Bool = true
    
    let poseTypeOrder: [PoseType] = [
        .Nose,
        .LeftEyeInner,
        .LeftEye,
        .LeftEyeOuter,
        .RightEyeInner,
        .RightEye,
        .RightEyeOuter,
        .LeftEar,
        .RightEar,
        .MouthLeft,
        .MouthRight,
        .LeftShoulder,
        .RightShoulder,
        .LeftElbow,
        .RightElbow,
        .LeftWrist,
        .RightWrist,
        .LeftPinkyFinger,
        .RightPinkyFinger,
        .LeftIndexFinger,
        .RightIndexFinger,
        .LeftThumb,
        .RightThumb,
        .LeftHip,
        .RightHip,
        .LeftKnee,
        .RightKnee,
        .LeftAnkle,
        .RightAnkle,
        .LeftHeel,
        .RightHeel,
        .LeftToe,
        .RightToe
    ]
    
    //MARK: UI Elements Variables
    
    var countdown:CountdownViewController?
    var timer:Timer?
    var currentTime = 0
    
    //MARK: Sending poses to calculate Reps
    var repCounter:RepetitionCounter?
    var poseDelegate:PoseDataDelegate?
    var repsFromDelegate:String = "0"
    var accuracyFromDelegate:Double = 0.0
    var wrapperView = UIView()
    var repSpeed:VerticalProgressView?
    
    //MARK: Timer View controller for Exercise
    var exerciseTimeCounter:ExerciseCountdownViewController?
    var exerciseTime:Int = 30
    var accuracyStack = UIStackView()
    var calorieBurn:Int = 0
    
    
    //MARK: To Change color of the lines based on result from speaking bot
    var redColorLines:[String] = []
    var greenColorLines:[String] = []
    var changeInColor:Bool = false
    
    //MARK: The welcome Tag's varible
    var importantIcon = makeImageView(withImageName: UIConstants.importantIcon, width: 83, height: 30)
    var instructionStack = UIStackView()
    
    //MARK: When the user taps Record a GIF should be played
    
    var gifDisplayView:GifView?
    
    
}


//Camera Related Codes

extension VisionCameraViewController{
    //Adding Sub Views to the Main View
    override func viewDidLoad() {
        super.viewDidLoad()
        //MARK: Entry Point
        
        checkPermission()
        shutterButton.addTarget(self, action: #selector(recordPoses), for: .touchUpInside)
        timerRepSelection.addTarget(self, action: #selector(selectRepsOrTime), for: .touchUpInside)
        cameraSwitchButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        createInformationStack()
        // Register for device orientation changes
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    //Setting Up layers for the camera
    override func viewDidLayoutSubviews() {
        previewLayer.frame = view.bounds
        shutterButton.center = CGPoint(x: view.frame.size.width/2,
                                       y: isPortrait ? view.frame.size.height - 100 : view.frame.size.height - 65 )
        timerRepSelection.center = CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.minX + 50,
                                           y: isPortrait ? view.frame.size.height - 100 : view.frame.size.height - 65 )
        cameraSwitchButton.center = CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.maxX - 50,
                                            y: isPortrait ? view.frame.size.height - 100 : view.frame.size.height - 65 )
        
    }
    
    
    // MARK: - Orientation Handling
    @objc func orientationChanged() {
        guard let connection = previewLayer?.connection else {
            print("not working")
            return
        }
        
        if connection.isVideoOrientationSupported {
            if isPortrait {
                connection.videoOrientation = .portrait
            } else {
                connection.videoOrientation = .landscapeRight
            }
        }
    }
    
    //Checking Permission once the app lauches
    private func checkPermission(){
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) {[weak self] granted in
                guard granted else {return}
                guard let strongSelf = self else {return}
                //                DispatchQueue.main.async {
                //                    strongSelf.setupCamera()
                //                }
                strongSelf.setupView()
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            //            setupCamera()
            setupView()
        @unknown default:
            break
        }
    }
    
    
    
    
    
    
    
    //    //If the permission is granted then setting up camera and displaying the video.
    //    private func setupCamera(){
    //        let session = AVCaptureSession()
    //        if let device = AVCaptureDevice.default(for: .video){
    //            do {
    //                let input = try AVCaptureDeviceInput(device: device)
    //                if session.canAddInput(input){
    //                    session.addInput(input)
    //                }
    //
    //                if session.canAddOutput(output){
    //                    session.addOutput(output)
    //                }
    //                previewLayer.videoGravity = .resizeAspectFill
    //                previewLayer.session = session
    //
    //                session.startRunning()
    //                self.session = session
    //            }
    //            catch{
    //                print(error)
    //            }
    //        }
    //    }
    //This function is called when the shutter button is tapped
    @objc func recordPoses(){
        
        shutterButton.removeFromSuperview()
        timerRepSelection.removeFromSuperview()
        importantIcon.removeFromSuperview()
        instructionStack.removeFromSuperview()
        //MARK: GIF Should Be presented here
        playGif()
        
        
        countdown = CountdownViewController()
        countdown?.isWrapped = true
        if let countdown = countdown{
            countdown.modalPresentationStyle = .overFullScreen
            countdown.countdownDelegate = self
            present(countdown, animated: false)
        }
        
        
        
        if typeOfExercise == "reps"{
            repCounter = RepetitionCounter(muscleGroup: muscleGroupForReps, startAngle: exerciseStartAngle, endAngle: exerciseEndAngle, totalReps: totalRepsToBeCompleted, repSpeed: repSpeedPerRep, vc: self)
            repCounter?.repDelegate = self
        }
    }
    
    //This function is called when the shutter button is tapped
    @objc func selectRepsOrTime(){
        print("Reps / Timer Button Tapped")
        //MARK: Place where we draw the view for rep selection
        selectionForExercise = TimeOrRepSelection(type: typeOfExercise)
        selectionForExercise?.delegate = self
        if let selectionView = selectionForExercise{
            selectionView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(selectionView)
            NSLayoutConstraint.activate([
                selectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                selectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                selectionView.widthAnchor.constraint(equalToConstant: 300),
                selectionView.heightAnchor.constraint(equalToConstant: 250)
            ])
        }
    }
    
    @objc func switchCamera(){
        removeView()
        self.isUsingFrontCamera.toggle()
        setupView()
        
    }
    
}
//MARK: Functions needed for initial UI Setup
extension VisionCameraViewController{
    
    private func createInformationStack() {
        let mainStack = makeStackView(withOrientation: .horizontal)
        let imageIcon = makeImageView(withImageName: UIConstants.portraitIcon, width: 45, height: 45)
        let label = returnUIlabel(title: instructionLabel, fontSize: 16,color: .white)
        
        mainStack.addArrangedSubview(imageIcon)
        mainStack.addArrangedSubview(label)
        
        instructionStack.backgroundColor = .black.withAlphaComponent(0.6)
        instructionStack.layer.cornerRadius = 10
        // Make sure 'instructionStack' is defined and initialized correctly
        instructionStack.translatesAutoresizingMaskIntoConstraints = false
        importantIcon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(importantIcon)
        // Ensure 'self.view' is accessible and contains necessary elements, and 'importantIcon' is defined
        self.view.addSubview(instructionStack)
        // Make sure 'importantIcon' is defined
        instructionStack.addSubview(mainStack)
        
        
        NSLayoutConstraint.activate([
            importantIcon.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            importantIcon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
        ])
        
        
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: instructionStack.leadingAnchor, constant: 10),
            mainStack.trailingAnchor.constraint(equalTo: instructionStack.trailingAnchor, constant: -10),
            mainStack.topAnchor.constraint(equalTo: instructionStack.topAnchor, constant: 10),
            mainStack.bottomAnchor.constraint(equalTo: instructionStack.bottomAnchor, constant: -10),
            
            instructionStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,constant: 10),
            instructionStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,constant: -10),
            // Ensure 'importantIcon' is accessible and properly defined
            instructionStack.topAnchor.constraint(equalTo: importantIcon.bottomAnchor,constant: 20),
        ])
    }
    
    private func playGif(){
        self.gifDisplayView = GifView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height), gifUrlString: gifURL)
        if let gif = gifDisplayView{
            self.view.addSubview(gif)
        }
        
    }
}



//MARK: Functions needed for Vision Camera
extension VisionCameraViewController{
    
    //Base code to setup all the functionalities needed to record the lines over the person
    func setupView(){
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        //setUpPreviewOverlayView()
        setUpAnnotationOverlayView()
        setUpCaptureSessionOutput()
        setUpCaptureSessionInput()
    }
    
    func removeView(){
        previewLayer.removeFromSuperlayer()
        previewLayer = nil
        annotationOverlayView.removeFromSuperview()
        captureSession.stopRunning()
        captureSession = AVCaptureSession()
    }
    
    //Start the video camera View
    private func startSession() {
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            strongSelf.captureSession.startRunning()
        }
    }
    
    //Start the video camera View
    private func stopSession() {
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            strongSelf.captureSession.stopRunning()
        }
    }
    
    
    //    //Adding the previewlayer (ImageView) to the view
    //    private func setUpPreviewOverlayView() {
    //        view.addSubview(previewOverlayView)
    //        NSLayoutConstraint.activate([
    //            previewOverlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    //            previewOverlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    //            previewOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    //            previewOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    //        ])
    //    }
    
    //Adding the AnnotationLayer (Lines Layer) to the view
    private func setUpAnnotationOverlayView() {
        view.addSubview(annotationOverlayView)
        NSLayoutConstraint.activate([
            annotationOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            annotationOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            annotationOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            annotationOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    
    
    private func setUpCaptureSessionOutput() {
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            strongSelf.captureSession.beginConfiguration()
            // When performing latency tests to determine ideal capture settings,
            // run the app in 'release' mode to get accurate performance metrics
            strongSelf.captureSession.sessionPreset = AVCaptureSession.Preset.medium
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
            ]
            output.alwaysDiscardsLateVideoFrames = true
            let outputQueue = DispatchQueue(label: Constant.videoDataOutputQueueLabel)
            output.setSampleBufferDelegate(strongSelf, queue: outputQueue)
            guard strongSelf.captureSession.canAddOutput(output) else {
                print("Failed to add capture session output.")
                return
            }
            strongSelf.captureSession.addOutput(output)
            strongSelf.captureSession.commitConfiguration()
        }
    }
    
    
    private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if #available(iOS 10.0, *) {
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .unspecified
            )
            return discoverySession.devices.first { $0.position == position }
        }
        return nil
    }
    
    
    private func setUpCaptureSessionInput() {
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            let cameraPosition: AVCaptureDevice.Position = strongSelf.isUsingFrontCamera ? .front : .back
            guard let device = strongSelf.captureDevice(forPosition: cameraPosition) else {
                print("Failed to get capture device for camera position: \(cameraPosition)")
                return
            }
            do {
                strongSelf.captureSession.beginConfiguration()
                let currentInputs = strongSelf.captureSession.inputs
                for input in currentInputs {
                    strongSelf.captureSession.removeInput(input)
                }
                
                let input = try AVCaptureDeviceInput(device: device)
                guard strongSelf.captureSession.canAddInput(input) else {
                    print("Failed to add capture session input.")
                    return
                }
                strongSelf.captureSession.addInput(input)
                strongSelf.captureSession.commitConfiguration()
                DispatchQueue.main.sync {
                    strongSelf.startSession()
                    strongSelf.orientationChanged()
                    strongSelf.view.addSubview(strongSelf.shutterButton)
                    strongSelf.view.addSubview(strongSelf.timerRepSelection)
                    strongSelf.view.addSubview(strongSelf.cameraSwitchButton)
                    strongSelf.cameraSwitchButtonUnChanged.toggle()
                }
            } catch {
                print("Failed to create capture device input: \(error.localizedDescription)")
            }
        }
    }
    
    
    private func detectPose(in image: MLImage, width: CGFloat, height: CGFloat) {
        if let poseDetector = self.poseDetector {
            var poses: [Pose] = []
            var detectionError: Error?
            do {
                poses = try poseDetector.results(in: image)
            } catch let error {
                detectionError = error
            }
            weak var weakSelf = self
            DispatchQueue.main.async {
                guard let strongSelf = weakSelf else {
                    print("Self is nil!")
                    return
                }
                strongSelf.removeDetectionAnnotations()
                if let detectionError = detectionError {
                    print("Failed to detect poses with error: \(detectionError.localizedDescription).")
                    return
                }
                guard !poses.isEmpty else {
                    //print("Pose detector returned no results.")
                    return
                }
                
                // Pose detected. Currently, only single person detection is supported.
                poses.forEach { pose in
                    let poseOverlayView = UIUtilities.createPoseOverlayView(
                        forPose: pose,
                        inViewWithBounds: strongSelf.annotationOverlayView.bounds,
                        lineWidth: Constant.lineWidth,
                        smallDotRadius: Constant.smallDotRadius,
                        bigDotRadius: Constant.bigDotRadius,
                        redLines: strongSelf.redColorLines,
                        greenLines: strongSelf.greenColorLines,
                        positionTransformationClosure: { (position) -> CGPoint in
                            return strongSelf.normalizedPoint(
                                fromVisionPoint: position, width: width, height: height)
                        }
                    )
                    strongSelf.annotationOverlayView.addSubview(poseOverlayView)
                    if strongSelf.isPoseDetectionStart{
                        strongSelf.getPoseData(pose: pose)
                        strongSelf.poseDelegate?.getPoses(pose: pose)
                    }
                }
            }
        }
    }
    
    
    private func removeDetectionAnnotations() {
        for annotationView in annotationOverlayView.subviews {
            annotationView.removeFromSuperview()
        }
    }
    
    //    private func updatePreviewOverlayViewWithLastFrame() {
    //        guard let lastFrame = lastFrame,
    //              let imageBuffer = CMSampleBufferGetImageBuffer(lastFrame)
    //        else {
    //            return
    //        }
    //        //self.updatePreviewOverlayViewWithImageBuffer(imageBuffer)
    //        self.removeDetectionAnnotations()
    //    }
    
    //    private func updatePreviewOverlayViewWithImageBuffer(_ imageBuffer: CVImageBuffer?) {
    //        guard let imageBuffer = imageBuffer else {
    //            return
    //        }
    //        let orientation: UIImage.Orientation = isUsingFrontCamera ? .leftMirrored : .right
    //        let image = UIUtilities.createUIImage(from: imageBuffer, orientation: orientation)
    //        previewOverlayView.image = image
    //    }
    //
    private func normalizedPoint(
        fromVisionPoint point: VisionPoint,
        width: CGFloat,
        height: CGFloat
    ) -> CGPoint {
        let cgPoint = CGPoint(x: point.x, y: point.y)
        var normalizedPoint = CGPoint(x: cgPoint.x / width, y: cgPoint.y / height)
        normalizedPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
        return normalizedPoint
    }
    
}

extension VisionCameraViewController:AVCaptureVideoDataOutputSampleBufferDelegate{
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        if isPortrait{
            return .portrait
        } else {
            return .landscape
        }
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer from sample buffer.")
            return
        }
        // Evaluate `self.currentDetector` once to ensure consistency throughout this method since it
        // can be concurrently modified from the main thread.
        //        let activeDetector = self.currentDetector
        //        resetManagedLifecycleDetectors(activeDetector: activeDetector)
        
        
        if self.poseDetector == nil {
            self.poseDetector = PoseDetector.poseDetector(options: AccuratePoseDetectorOptions())
            //self.poseDetector = PoseDetector.poseDetector(options: PoseDetectorOptions())
        }
        lastFrame = sampleBuffer
        let visionImage = VisionImage(buffer: sampleBuffer)
        let orientation = UIUtilities.imageOrientation(
            fromDevicePosition: isUsingFrontCamera ? .front : .back
        )
        visionImage.orientation = orientation
        guard let inputImage = MLImage(sampleBuffer: sampleBuffer) else {
            print("Failed to create MLImage from sample buffer.")
            return
        }
        inputImage.orientation = orientation
        let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
        detectPose(in: inputImage, width: imageWidth, height: imageHeight)
    }
}

extension VisionCameraViewController{
    
    private func getPoseData(pose: Pose) {
        let keyPoints = mapBasedOnEnumSequence(frames: pose.landmarks)
        var tempData = [[String: Any]]()
        for index in 0..<keyPoints.count {
            let data: [String: Any] = [
                // "type": keyPoints[index].type.rawValue,
                "zza": index,
                "zzb": ["zza": keyPoints[index].position.x, "zzb":keyPoints[index].position.y, "zzc": keyPoints[index].position.z],
                // "zzc": ["x": keyPoints[index].position.x, "y":keyPoints[index].position.y],
                "zzd": trim(keyPoints[index].inFrameLikelihood)
            ]
            tempData.append(data)
        }
        // print("Temp Data: \(tempData)")
        cameraPoses.append(tempData)
    }
    
    private func trim(_ number: Float) -> Decimal {
        let fourDecimalString = String(format: "%.4f", number)
        let fourDecimalFloat = Decimal(string: fourDecimalString)
        return fourDecimalFloat ?? 0
    }
    
    private func mapBasedOnEnumSequence(frames: [PoseLandmark]) -> [PoseLandmark] {
        
        return frames.sorted { (item1, item2) -> Bool in
            guard let poseType1 = PoseType(rawValue: item1.type.rawValue),
                  let poseType2 = PoseType(rawValue: item2.type.rawValue),
                  let index1 = poseTypeOrder.firstIndex(of: poseType1),
                  let index2 = poseTypeOrder.firstIndex(of: poseType2) else {
                return false
            }
            return index1 < index2
        }
    }
    
    private func sendPoses(){
        let completedData: [String: Any] = ["complete_data": cameraPoses,
                                            "final_stats": ["duration": 10,
                                                            "reps":  0,
                                                            "calories_burned":  0,
                                                            "accuracy_score": 40,
                                                            "is_final": true,"saved_video":""]]
        cameraPoses = []
        //      print(completedData)
        viewModel = SpeakingBotViewModel(postData: completedData, apiName: apiName)
        viewModel?.delegate = self
        viewModel?.sendFeedback()
    }
}

enum PoseType: String {
    case Nose
    case LeftEyeInner
    case LeftEye
    case LeftEyeOuter
    case RightEyeInner
    case RightEye
    case RightEyeOuter
    case LeftEar
    case RightEar
    case MouthLeft
    case MouthRight
    case LeftShoulder
    case RightShoulder
    case LeftElbow
    case RightElbow
    case LeftWrist
    case RightWrist
    case LeftPinkyFinger
    case RightPinkyFinger
    case LeftIndexFinger
    case RightIndexFinger
    case LeftThumb
    case RightThumb
    case LeftHip
    case RightHip
    case LeftKnee
    case RightKnee
    case LeftAnkle
    case RightAnkle
    case LeftHeel
    case RightHeel
    case LeftToe
    case RightToe
}

private enum Constant {
    static let videoDataOutputQueueLabel = "com.google.mlkit.visiondetector.VideoDataOutputQueue"
    static let sessionQueueLabel = "com.google.mlkit.visiondetector.SessionQueue"
    static let smallDotRadius: CGFloat = 8.0
    static let bigDotRadius: CGFloat = 15.0
    static let lineWidth: CGFloat = 2.0
    static let originalScale: CGFloat = 1.0
}

//MARK: Countdown Delegate
extension VisionCameraViewController:CountdownDelegate{
    func didFinishCountdown() {
        gifDisplayView?.removeFromSuperview()
        isPoseDetectionStart = true
        if typeOfExercise == "reps"{
            //            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
            //            timer?.fire()
            exerciseTimeCounter = ExerciseCountdownViewController()
            repSpeed = VerticalProgressView()
            setupRepCounterUI()
            if let ex = exerciseTimeCounter{
                ex.modalPresentationStyle = .overFullScreen
                ex.countdownDelegate = self
                present(ex, animated: false)
                ex.startTimer(with: 90)
            }
        } else {
            exerciseTimeCounter = ExerciseCountdownViewController()
            setupTimeCounterUI()
            if let ex = exerciseTimeCounter{
                ex.modalPresentationStyle = .overFullScreen
                ex.countdownDelegate = self
                present(ex, animated: false)
                ex.startTimer(with: exerciseTime)
            }
        }
    }
    
    @objc func timerFired(){
        currentTime += 1
        //        if currentTime > 30{
        //            timer?.invalidate()
        //            timer = nil
        //            isPoseDetectionStart = false
        //        } else
        if (currentTime%10) == 0 {
            sendPoses()
        }
        //        else {
        //            //print(currentTime)
        //        }
    }
}

protocol PoseDataDelegate{
    func getPoses(pose:Pose)
}

//MARK: Repcounter UI
extension VisionCameraViewController:RepetitionCountUIUpdateDelegate{
    func updateRepSpeed(with speed: Float, secondsTaken: Int) {
        if let repSpeed = repSpeed{
            if speed >= 0 && speed < 1 {
                repSpeed.updateProgress(speed, seconds: "\(secondsTaken)")
            } else {
                repSpeed.updateProgress(1, seconds: "\(secondsTaken)")
            }
        }
    }
    
    func getRepCount(rep: String) {
        if rep != repsFromDelegate{
            repsFromDelegate = rep
            //MARK: Place where calorie Burn is calculated
            calorieBurnCalculator(reps: Int(rep)!)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {return}
                self.removeStack()
                self.wrapperView = UIView()
                self.setupRepCounterUI(with: self.repsFromDelegate)
            }
        }
    }
    
    func didCompletePoses() {
        timer?.invalidate()
        timer = nil
        exerciseTimeCounter?.stopTimer()
        exerciseTimeCounter?.countdownView.stopTimer()
        isPoseDetectionStart = false
        //MARK: Send one last time all the pose data
        sendPoses()
    }
    
    func removeStack(){
        wrapperView.removeFromSuperview()
    }
    
    func setupRepCounterUI(with reps: String = "0") {
        guard let repSpeed = repSpeed else { return }
        
        // Add repSpeed to the main view and set its constraints
        view.addSubview(repSpeed)
        repSpeed.translatesAutoresizingMaskIntoConstraints = false
        
        // Create the main stack view
        let stack = makeStackView(withOrientation: .vertical, distribution: .equalSpacing)
        stack.backgroundColor = .clear
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // Create the exercise data views
        let repCounter = exerciseDataView(for: .Reps, mainValueToDisplay: "\(reps)", addedValue: "/ \(totalRepsToBeCompleted)")
        updateAccuracy(with: accuracyFromDelegate)
        let caloriesView = exerciseDataView(for: .Calories, mainValueToDisplay: "\(calorieBurn)", addedValue: "cal")
        
        // Add the exercise data views to the stack view
        stack.addArrangedSubview(repCounter)
        stack.addArrangedSubview(accuracyStack)
        stack.addArrangedSubview(caloriesView)
        
        // Set spacing between the views
        stack.setCustomSpacing(5, after: repCounter)
        stack.setCustomSpacing(5, after: accuracyStack)
        
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        wrapperView.layer.cornerRadius = 10
        wrapperView.backgroundColor = .black.withAlphaComponent(0.4)
        wrapperView.addSubview(stack)
        
        // Add the wrapper view to the main view
        view.addSubview(wrapperView)
        
        // Activate constraints
        NSLayoutConstraint.activate([
            // Constrain the stack view to the wrapper view with padding
            stack.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: wrapperView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: -10),
            
            // Constrain the wrapper view to the safe area layout guide
            wrapperView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            wrapperView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        
        // Set constraints for repSpeed based on orientation
        if isPortrait {
            NSLayoutConstraint.activate([
                repSpeed.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
                repSpeed.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                repSpeed.widthAnchor.constraint(equalToConstant: 105),
                repSpeed.heightAnchor.constraint(equalToConstant: 200)
            ])
        } else {
            NSLayoutConstraint.activate([
                repSpeed.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
                repSpeed.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
                repSpeed.widthAnchor.constraint(equalToConstant: 105),
                repSpeed.heightAnchor.constraint(equalToConstant: 200)
            ])
        }
    }
    
    func updateAccuracy(with accuracy:Double){
        accuracyStack = exerciseDataView(for: .Accuracy, mainValueToDisplay: String(format: "%.0f", accuracy), addedValue: "%")
    }
    
    
    func exerciseDataView(for activity: ActivityType, mainValueToDisplay: String?, addedValue: String?) -> UIStackView {
        let stack = makeStackView(withOrientation: .vertical)
        let horizontalStack1 = makeStackView(withOrientation: .horizontal, spacing: 2)
        stack.heightAnchor.constraint(equalToConstant: 90).isActive = true
        stack.widthAnchor.constraint(equalToConstant: 100).isActive = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        switch activity {
        case .Accuracy:
            addAllViewsTogether(mainStack: stack, horizontalStack1: horizontalStack1, mainValue: mainValueToDisplay, subValue: addedValue, iconName: "scope", iconTitle: "Accuracy", colorforText: .white)
            if let mainValue = mainValueToDisplay, let intValue = Int(mainValue), intValue > 0 && intValue <= 40 {
                stack.backgroundColor = UIColor(red: 166/255, green: 69/255, blue: 69/255, alpha: 1)
            } else if let mainValue = mainValueToDisplay, let intValue = Int(mainValue), intValue > 40 && intValue < 75 {
                stack.backgroundColor = UIColor(red: 201/255, green: 147/255, blue: 65/255, alpha: 1)
            } else {
                stack.backgroundColor = UIColor(red: 91/255, green: 142/255, blue: 120/255, alpha: 1)
            }
            
        case .Calories:
            addAllViewsTogether(mainStack: stack, horizontalStack1: horizontalStack1, mainValue: mainValueToDisplay, subValue: addedValue, iconName: "flame", iconTitle: "Calories Burn", colorforText: .darkGray)
            stack.backgroundColor = .white
            
        case .Reps:
            addAllViewsTogether(mainStack: stack, horizontalStack1: horizontalStack1, mainValue: mainValueToDisplay, subValue: addedValue, iconName: "arrow.circlepath", iconTitle: "Rep Count", colorforText: .white, subFontSize: 18)
            stack.backgroundColor = .none
        }
        
        return stack
    }
    
    func calorieBurnCalculator(reps:Int){
        self.calorieBurn = reps*caloriesBurnPerRep
    }
}

//MARK: Time Counter UI and Delegate

extension VisionCameraViewController:ExerciseCountdownDelegate{
    func didFinishExerciseTimerCountdown() {
        isPoseDetectionStart = false
        //MARK: Send one last time all the pose data
        sendPoses()
    }
    
    func currentCountDown(seconds: Int) {
        if (seconds%10) == 0 {
            sendPoses()
        }
    }
    
    
    func setupTimeCounterUI(accuracy:Double = 0.0){
        
        updateAccuracy(with: accuracy)
        accuracyStack.translatesAutoresizingMaskIntoConstraints = false
        // Add the wrapper view to the main view
        self.view.addSubview(accuracyStack)
        
        NSLayoutConstraint.activate([
            accuracyStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            accuracyStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 10)
        ])
    }
}

//MARK: Speaking Bot Delegate

extension VisionCameraViewController:SpeakingBotDelegate{
    func updateColorsForBodyPart(bodyParts: BodyPartsColor) {
        self.redColorLines = bodyParts.red
        self.greenColorLines = bodyParts.green
    }
    
    func updateAccuracy(with accuracy: Double?) {
        if accuracy != nil && accuracyFromDelegate != accuracy{
            accuracyFromDelegate = accuracy!
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {return}
                
                if  self.typeOfExercise == "reps"{
                    self.removeStack()
                    self.setupRepCounterUI(with: repsFromDelegate)
                    
                } else {
                    self.accuracyStack.removeFromSuperview()
                    setupTimeCounterUI(accuracy: accuracyFromDelegate)
                }
            }
        }
    }
}


//MARK: Selection View Delegate

extension VisionCameraViewController:SelectionDelegate{
    func selectedInput(input: String?) {
        if let input = input{
            if typeOfExercise == "reps"{
                totalRepsToBeCompleted = input
            } else {
                exerciseTime = Int(input)!
            }
            
            selectionForExercise?.removeFromSuperview()
            selectionForExercise = nil
            print("\(totalRepsToBeCompleted)")
        }
        
    }
}
