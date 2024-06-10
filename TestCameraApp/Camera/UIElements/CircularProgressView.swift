//
//  CircularProgressView.swift
//  TestCameraApp
//
//  Created by Gokul Murugan on 08/05/24.
//

import UIKit

class CircularProgressView: UIView {
    
    private var backgroundLayer = CAShapeLayer()
    private var progressLayer = CAShapeLayer()
    private var remainingTimeLabel = UILabel()
    var startedRecordingProgress:Bool = false
    private var totalTime: Int = 0
    private var currentTime: Int = 0
    private var timer: Timer?
    //var delegate: CountdownProgressDelegate?
    
    var progress: CGFloat {
        return CGFloat(currentTime) / CGFloat(totalTime)
    }
    
    var remainingTime: Int {
        return max(0, totalTime - currentTime)
    }
    
    init(isTrue:Bool = false, withBackgorundColor:CGColor = UIColorFromHex(hex: "8C8C8C").cgColor, withProgressColor:CGColor = UIColorFromHex(hex: "FFFFFF").cgColor, width:CGFloat = 100, height:CGFloat = 100, textColor:UIColor = .black, textSize:CGFloat = 16,lineWidth:CGFloat = 8) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false // Set this to false for Auto Layout compatibility
        startedRecordingProgress = isTrue
        setupUI(withBackgorundColor: withBackgorundColor, withProgressColor: withProgressColor, width: width, height: height, textColor: textColor, textSize: textSize, lineWidth: lineWidth)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI()
    }
    
    deinit {
        stopTimer()
    }
    
    private func setupUI(withBackgorundColor:CGColor = UIColorFromHex(hex: "E9E9FF").cgColor, withProgressColor:CGColor = UIColorFromHex(hex: "121ACE").cgColor, width:CGFloat = 100, height:CGFloat = 100, textColor:UIColor = .black, textSize:CGFloat = 16,lineWidth:CGFloat = 8) {
        
        let width: CGFloat = width
        let height: CGFloat = height
        
        // Create circular path
        let circularPath = UIBezierPath(arcCenter: CGPoint(x: width / 2, y: height / 2),
                                        radius: width / 2 - 10,
                                        startAngle: -CGFloat.pi / 2,
                                        endAngle: -CGFloat.pi / 2 + 2 * CGFloat.pi,
                                        clockwise: true)
        
        // Set the frame explicitly
        self.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        // Setup background layer
        backgroundLayer.path = circularPath.cgPath
        backgroundLayer.strokeColor = withBackgorundColor
        backgroundLayer.lineWidth = lineWidth
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineCap = .round
        layer.addSublayer(backgroundLayer)
        
        
        // Setup progress layer
        progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = withProgressColor
        progressLayer.lineWidth = lineWidth
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0.0 // Start from zero
        layer.addSublayer(progressLayer)
        
        if !startedRecordingProgress{
            // Setup remaining time label
            remainingTimeLabel.frame = bounds
            remainingTimeLabel.textAlignment = .center
            remainingTimeLabel.textColor = textColor
            remainingTimeLabel.font = UIFont(name: "Roboto-Bold", size: textSize)
            addSubview(remainingTimeLabel)
        }
    }
    
    private func updateProgress() {
        progressLayer.strokeEnd = progress
    }
    
    private func updateRemainingTime() {
        remainingTimeLabel.text = "00:\(remainingTime)"
    }
    
    func startTimer(with totalTime: Int) {
        stopTimer()
        
        self.totalTime = totalTime
        self.currentTime = 0
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
        
        updateProgress()
        updateRemainingTime()
    }
    
    @objc private func timerTick() {
        currentTime += 1
        
        /// this is the check to track current time
        /// and sending currnet time interval to camera viewcontroller
        /// so that user can get voice feedback over a certain time frame (setting to 10 seconds)
        if currentTime != 0 && currentTime < totalTime{
            //self.delegate?.currentCountdown(currentTime)
            //print("Countdown Check")
        }
        if currentTime >= totalTime {
            //print("Timer Check")
            stopTimer()
            /// this is checking if given time frame is finished
            /// if finished it will let know camera viewcontroller
            /// so that the feedback api called and user get feedback for there curent exercise
            //self.delegate?.didFinishSelectedTimeFrame()
        }
        
        
//
//        if unitsExercise == "seconds"{
//            if currentTime >= totalTime {
//                //print("Timer Check")
//                stopTimer()
//                /// this is checking if given time frame is finished
//                /// if finished it will let know camera viewcontroller
//                /// so that the feedback api called and user get feedback for there curent exercise
//                self.delegate?.didFinishSelectedTimeFrame()
//            }
//        } else {
//            if currentReps >= totalReps{
//                stopTimer()
//                self.delegate?.didFinishSelectedTimeFrame()
//            }
//        }
        
        
        
        
        
        
        updateProgress()
        updateRemainingTime()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}


public func UIColorFromHex(hex: String, alpha: CGFloat = 1.0) -> UIColor {
    
    var rgb: UInt64 = 0
    
    Scanner(string: hex).scanHexInt64(&rgb)
    
    let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
    let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
    let blue = CGFloat(rgb & 0x0000FF) / 255.0
    
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
}
