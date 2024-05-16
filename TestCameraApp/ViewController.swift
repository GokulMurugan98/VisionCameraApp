//
//  ViewController.swift
//  TestCameraApp
//
//  Created by Gokul Murugan on 02/05/24.
//

import UIKit
import AVFoundation
import MLKit

class ViewController: UIViewController {
    
    //MARK: Simple Camera Variables
    
    //To Check Which Camer to use
    private var isUsingFrontCamera = false
    //Setting up preview layer
    private var previewLayer: AVCaptureVideoPreviewLayer!
    //Setting up Capture session
    private lazy var captureSession = AVCaptureSession()
    //Initializing session queue
    private lazy var sessionQueue = DispatchQueue(label: Constant.sessionQueueLabel)
    
    let shutterButtuon:UIButton = {
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
    
    
    //MARK: The Variable which defined if it is a Rep based or timer based exercise
    let typeOfExercise:String = "timer"
    
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
    var reps:String = "0"
    let wrapperView = UIView()
    var stack = UIStackView()
    
    //MARK: Timer View controller for Exercise
    var exerciseTimeCounter:ExerciseCountdownViewController?
    var exerciseTime:Int = 30
    var accuracyStack = UIStackView()
}


//Camera Related Codes

extension ViewController{
    //Adding Sub Views to the Main View
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //        view.layer.addSublayer(previewLayer)
        //        view.addSubview(shutterButtuon)
        checkPermission()
        shutterButtuon.addTarget(self, action: #selector(recordPoses), for: .touchUpInside)
        timerRepSelection.addTarget(self, action: #selector(selectRepsOrTime), for: .touchUpInside)
        
       
        
    }
    //Setting Up layers for the camera
    override func viewDidLayoutSubviews() {
        previewLayer.frame = view.bounds
        shutterButtuon.center = CGPoint(x: view.frame.size.width/2,
                                        y: view.frame.size.height - 100)
        timerRepSelection.center = CGPoint(x: view.safeAreaInsets.left+50,
                                        y: view.frame.size.height - 100)
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
        print("Shutter Button Tapped")
        shutterButtuon.removeFromSuperview()
        timerRepSelection.removeFromSuperview()
        countdown = CountdownViewController()
        if let countdown = countdown{
            countdown.modalPresentationStyle = .overFullScreen
            countdown.countdownDelegate = self
            present(countdown, animated: false)
        }
        if typeOfExercise == "reps"{
            repCounter = RepetitionCounter(muscleGroup: [
                "SHOULDER",
                "HIP",
                "WRIST"
            ], startAngle: ExerciseAngles(angle_1: [75,120], angle_2: [250,295]), endAngle: ExerciseAngles(angle_1: [0,35], angle_2: [325,360]), totalReps: "15", vc: self)
            repCounter?.repDelegate = self
        }
    }
    
    //This function is called when the shutter button is tapped
    @objc func selectRepsOrTime(){
        print("Reps / Timer Button Tapped")
        
    }
}

//MARK: Functions needed for Vision Camera
extension ViewController{
    
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
                    strongSelf.view.addSubview(strongSelf.shutterButtuon)
                    strongSelf.view.addSubview(strongSelf.timerRepSelection)
                    
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
                        positionTransformationClosure: { (position) -> CGPoint in
                            return strongSelf.normalizedPoint(
                                fromVisionPoint: position, width: width, height: height)
                        }
                    )
                    strongSelf.annotationOverlayView.addSubview(poseOverlayView)
                    if strongSelf.isPoseDetectionStart{
                        strongSelf.getPoseData(pose: pose)
                        print("sending pose data")
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

extension ViewController:AVCaptureVideoDataOutputSampleBufferDelegate{
    
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

extension ViewController{
    
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
        viewModel = SpeakingBotViewModel(postData: completedData, apiName: "lateral_raises")
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
extension ViewController:CountdownDelegate{
    func didFinishCountdown() {
        isPoseDetectionStart = true
        if typeOfExercise == "reps"{
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
            timer?.fire()
        } else {
            exerciseTimeCounter = ExerciseCountdownViewController()
            if let ex = exerciseTimeCounter{
                ex.modalPresentationStyle = .overFullScreen
                ex.countdownDelegate = self
                present(ex, animated: false)
                ex.startTimer(with: exerciseTime)
            }
        }
        addWrapperView()
        if typeOfExercise == "reps"{
            setupRepCounterUI()
        } else {
            setupTimeCounterUI()
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
extension ViewController:RepetitionCountUIUpdateDelegate{
    func getRepCount(rep: String) {
        if rep != reps{
            reps = rep
            removeStack()
            setupRepCounterUI()
        }
    }
    
    func didCompletePoses() {
        timer?.invalidate()
        timer = nil
        isPoseDetectionStart = false
        //MARK: Send one last time all the pose data
        sendPoses()
    }
    
    func addWrapperView(){
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        wrapperView.layer.cornerRadius = 10
        wrapperView.backgroundColor = .black.withAlphaComponent(0.4)
    }
    
    func removeStack(){
        stack.removeFromSuperview()
    }
    
    func setupRepCounterUI(){
        
        // Create a wrapper view for the stack view
         // Set the background color of the wrapper view
        
        // Add the stack view to the wrapper view
        stack = makeStackView(withOrientation: .vertical, distribution: .fill, spacing: 5)
        stack.backgroundColor = .clear
        
        
        let repCounter = exerciseDataView(for: .Reps, mainValueToDisplay: reps, addedValue: "/ 15")
        let accuracy = exerciseDataView(for: .Accuracy, mainValueToDisplay: "20", addedValue: "%")
        let calories = exerciseDataView(for: .Calories, mainValueToDisplay: "88", addedValue: "cal")
        stack.addArrangedSubview(repCounter)
        stack.addArrangedSubview(accuracy)
        stack.addArrangedSubview(calories)
        
        wrapperView.addSubview(stack)
        
        // Add the wrapper view to the main view
        self.view.addSubview(wrapperView)
        
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
        
        
    }
    
    func exerciseDataView(for Activity:ActivityType, mainValueToDisplay:String?, addedValue:String?) -> UIStackView{
        
        let stack = makeStackView(withOrientation: .vertical)
        let horizontalStack1 = makeStackView(withOrientation: .horizontal, spacing: 2)
        let horizontalStack2 = makeStackView(withOrientation: .horizontal, spacing: 2)
        stack.heightAnchor.constraint(equalToConstant: 90).isActive = true
        stack.widthAnchor.constraint(equalToConstant: 100).isActive = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        switch Activity{
            
        case .Accuracy:
            addAllViewsTogether(mainStach: stack, horizontalStack1: horizontalStack1, horizontalStack2: horizontalStack2, mainValue: mainValueToDisplay, subValue: addedValue, iconName: "scope", iconTitle: "Accuracy", colorforText: .white)
            if Int(mainValueToDisplay!)! > 0 && Int(mainValueToDisplay!)! <= 40{
                stack.backgroundColor = UIColor(red: 166/255, green: 69/255, blue: 69/255, alpha: 1)
            } else if Int(mainValueToDisplay!)! > 40 && Int(mainValueToDisplay!)! < 75{
                stack.backgroundColor = UIColor(red: 201/255, green: 147/255, blue: 65/255, alpha: 1)
            } else {
                stack.backgroundColor = UIColor(red: 91/255, green: 142/255, blue: 120/255, alpha: 1)
            }
            
        case .Calories:
            addAllViewsTogether(mainStach: stack, horizontalStack1: horizontalStack1, horizontalStack2: horizontalStack2, mainValue: mainValueToDisplay, subValue: addedValue, iconName: "flame", iconTitle: "Calories Burn", colorforText: .darkGray)
            stack.backgroundColor = .white
            
        case .Reps:
            addAllViewsTogether(mainStach: stack, horizontalStack1: horizontalStack1, horizontalStack2: horizontalStack2, mainValue: mainValueToDisplay, subValue: addedValue, iconName: "arrow.circlepath", iconTitle: "Rep Count", colorforText: .white, subFontSize: 18)
            stack.backgroundColor = .none
            
        case .Timer:
            addAllViewsTogether(mainStach: stack, horizontalStack1: horizontalStack1, horizontalStack2: horizontalStack2, mainValue: mainValueToDisplay, subValue: addedValue, iconName: "clock.arrow.circlepath", iconTitle: "Timer", colorforText: .white, subFontSize: 18)
            stack.backgroundColor = .none
            
        }
        return stack
    }
}

//MARK: Time Counter UI and Delegate

extension ViewController:ExerciseCountdownDelegate{
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
    
    
    func setupTimeCounterUI(){
        
        accuracyStack = exerciseDataView(for: .Accuracy, mainValueToDisplay: "20", addedValue: "%")
        accuracyStack.translatesAutoresizingMaskIntoConstraints = false
        // Add the wrapper view to the main view
        self.view.addSubview(accuracyStack)
        
        NSLayoutConstraint.activate([
            accuracyStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            accuracyStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 10)
        
        
        
        ])
    }
}

