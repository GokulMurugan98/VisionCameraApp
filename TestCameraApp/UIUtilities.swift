//
//  UIUtilities.swift
//  TestCameraApp
//
//  Created by Gokul Murugan on 03/05/24.
//

import UIKit
import MLKit
import AVFoundation

public class UIUtilities {
    
    // MARK: - Public
    
    public static func addCircle(
        atPoint point: CGPoint,
        to view: UIView,
        color: UIColor,
        radius: CGFloat
    ) {
        let divisor: CGFloat = 2.0
        let xCoord = point.x - radius / divisor
        let yCoord = point.y - radius / divisor
        let circleRect = CGRect(x: xCoord, y: yCoord, width: radius, height: radius)
        guard circleRect.isValid() else { return }
        let circleView = UIView(frame: circleRect)
        circleView.layer.cornerRadius = radius / divisor
        circleView.alpha = Constants.circleViewAlpha
        circleView.backgroundColor = color
        circleView.isAccessibilityElement = true
        circleView.accessibilityIdentifier = Constants.circleViewIdentifier
        view.addSubview(circleView)
    }
    
    /// Creates a pose overlay view for visualizing a given `pose`.
    ///
    /// - Parameters:
    ///   - pose: The pose which will be visualized.
    ///   - bounds: The bounds of the view to which this overlay will be added. The overlay view's
    ///         bounds will match this value.
    ///   - lineWidth: The width of the lines connecting the landmark dots.
    ///   - dotRadius: The radius of the landmark dots.
    ///   - positionTransformationClosure: Closure which transforms a landmark `position` to the
    ///         `UIView` `CGPoint` coordinate where it should be shown on-screen.
    /// - Returns: The pose overlay view.
    public static func createPoseOverlayView(
        forPose pose: Pose, inViewWithBounds bounds: CGRect, lineWidth: CGFloat, smallDotRadius: CGFloat,
        bigDotRadius: CGFloat,
        redLines:[String]?, greenLines:[String]?,
        positionTransformationClosure: (VisionPoint) -> CGPoint
        
    ) -> UIView {
        let overlayView = UIView(frame: bounds)
        
        let lowerBodyHeight: CGFloat =
        UIUtilities.distance(
            fromPoint: pose.landmark(ofType: PoseLandmarkType.leftAnkle).position,
            toPoint: pose.landmark(ofType: PoseLandmarkType.leftKnee).position)
        + UIUtilities.distance(
            fromPoint: pose.landmark(ofType: PoseLandmarkType.leftKnee).position,
            toPoint: pose.landmark(ofType: PoseLandmarkType.leftHip).position)
        
        // Pick arbitrary z extents to form a range of z values mapped to our colors. Red = close, blue
        // = far. Assume that the z values will roughly follow physical extents of the human body, but
        // apply an adjustment ratio to increase this color-coded z-range because this is not always the
        // case.
        let adjustmentRatio: CGFloat = 1.2
        let nearZExtent: CGFloat = -lowerBodyHeight * adjustmentRatio
        let farZExtent: CGFloat = lowerBodyHeight * adjustmentRatio
        let zColorRange: CGFloat = farZExtent - nearZExtent
        var nearZColor = UIColor.white
        var farZColor = UIColor.white
//        var red_lines_part:[String] = []
//        var green_lines_part:[String] = []
//        var red_lines:[[String]] = [[]]
//        var green_lines:[[String]] = [[]]
        //Assigning the data from Speaking bot delegate feedback to the desired variables
        
        //Appending the values that the function returns when the function returns the array of values if we pass a string
        //For eg: if feedback has "Right Upper Arm" the function return ["RightElbow", "RightShoulders"]
        // We are looping for each value in the array of feedback strings.
        // This is needed becaus for us to draw the required coloured line we need to check if the values are similar if not we can pring White color.
        
        
//        if let red = redLines{
//            red_lines_part = red
//            for red in red_lines_part{
//                red_lines.append(UIUtilities().returnPointsBasedOnBodyPart(bodyPartName: red))
//            }
//        }
//        
//        
//        
//        if let green = greenLines{
//            green_lines_part = green
//            for green in green_lines_part{
//                green_lines.append(UIUtilities().returnPointsBasedOnBodyPart(bodyPartName: green))
//            }
//        }
        
        
        
        
        
        
        
        for (startLandmarkType, endLandmarkTypesArray) in UIUtilities.poseConnections() {
            //Reassigning the color of the variables because if we didn't change it then it draws the previous color and won't prints white color.
            if farZColor != UIColor.white{
                farZColor = UIColor.white
            }
            if nearZColor != UIColor.white{
                nearZColor = UIColor.white
            }
            let startLandmark = pose.landmark(ofType: startLandmarkType)
            for endLandmarkType in endLandmarkTypesArray {
                let endLandmark = pose.landmark(ofType: endLandmarkType)
                let startLandmarkPoint = positionTransformationClosure(startLandmark.position)
                let endLandmarkPoint = positionTransformationClosure(endLandmark.position)
                
                let landmarkZRatio = (startLandmark.position.z - nearZExtent) / zColorRange
                let connectedLandmarkZRatio = (endLandmark.position.z - nearZExtent) / zColorRange
                
                //Looping through all the values in the red_lines variable and checking if this is the line we have to change the desired color accoring to feedback.
                
//                for x in red_lines{
//                    if x.contains(startLandmarkType.rawValue)  && x.contains(endLandmarkType.rawValue){
//                        farZColor = UIColor.red
//                        nearZColor = UIColor.red
//                    }
//                }
//                
//                
//                
//                for x in green_lines{
//                    if x.contains(startLandmarkType.rawValue)  && x.contains(endLandmarkType.rawValue){
//                        farZColor = UIColor.green
//                        nearZColor = UIColor.green
//                    }
//                }
                
                
                let startColor = UIUtilities.interpolatedColor(
                    fromColor: nearZColor, toColor: farZColor, ratio: landmarkZRatio)
                let endColor = UIUtilities.interpolatedColor(
                    fromColor: nearZColor, toColor: farZColor, ratio: connectedLandmarkZRatio)
                
                UIUtilities.addLineSegment(
                    fromPoint: startLandmarkPoint,
                    toPoint: endLandmarkPoint,
                    inView: overlayView,
                    colors: [startColor, endColor],
                    width: lineWidth)
            }
        }
        for landmark in pose.landmarks {
            let landmarkPoint = positionTransformationClosure(landmark.position)
            UIUtilities.addCircle(
                atPoint: landmarkPoint,
                to: overlayView,
                color: UIColor.gray.withAlphaComponent(0.5),
                radius: bigDotRadius
            )
            UIUtilities.addCircle(
                atPoint: landmarkPoint,
                to: overlayView,
                color: UIColor.white,
                radius: smallDotRadius
            )
        }
        return overlayView
    }
    
    
    //The function to convert the value from a string to MLKPoses type but as a String so that we can determine the color changes.
    private func returnPointsBasedOnBodyPart(bodyPartName:String) -> [String]{
        switch bodyPartName{
            //HEAD:
        case "Head":
            return ["Nose", "LefyEyeInner"]
            // LEFT BODY:
        case "Left Upper Arm":
            return ["LeftShoulder", "LeftElbow"]
        case "Left Lower Arm":
            return ["LeftElbow", "LeftWrist"]
        case "Left Body":
            return ["LeftShoulder", "LeftHip"]
        case "Left Thigh":
            return ["LeftHip", "LeftKnee"]
        case "Left Lower Leg":
            return ["LeftKnee", "LeftAnkle"]
        case "Left Forearm":
            return ["LeftWrist", "LeftThumb"]
        case "Left Pinky":
            return ["LeftWrist", "LeftPinky"]
        case "Left Index":
            return ["LeftWrist", "LeftIndex"]
        case "Left Index Pinky":
            return ["LeftIndex", "LeftPinky"]
        case "Left Ankle":
            return ["LeftAnkle", "LeftHeel"]
        case "Left Heel":
            return ["LeftHeel", "LeftFootIndex"]
            // Right BODY:
        case "Right Upper Arm":
            return ["RightShoulder", "RightElbow"]
        case "Right Lower Arm":
            return ["RightElbow", "RightWrist"]
        case "Right Body":
            return ["RightShoulder", "RightHip"]
        case "Right Thigh":
            return ["RightHip", "RightKnee"]
        case "Right Lower Leg":
            return ["RightKnee", "RightAnkle"]
        case "Right Forearm":
            return ["RightWrist", "RightThumb"]
        case "Right Pinky":
            return ["RightWrist", "RightPinky"]
        case "Right Index":
            return ["RightWrist", "RightIndex"]
        case "Right Index Pinky":
            return ["RightIndex", "RightPinky"]
        case "Right Ankle":
            return ["RightAnkle", "RightHeel"]
        case "Right Heel":
            return ["RightHeel", "RightFootIndex"]
        default:
            return [""]
        }
    }
    
    
    
    /// Returns the distance between two 3D points.
    ///
    /// - Parameters:
    ///   - fromPoint: The starting point.
    ///   - toPoint: The end point.
    /// - Returns: The distance.
    private static func distance(fromPoint: Vision3DPoint, toPoint: Vision3DPoint) -> CGFloat {
        let xDiff = fromPoint.x - toPoint.x
        let yDiff = fromPoint.y - toPoint.y
        let zDiff = fromPoint.z - toPoint.z
        return CGFloat(sqrt(xDiff * xDiff + yDiff * yDiff + zDiff * zDiff))
    }
    
    // MARK: - Private
    
    /// Returns the minimum subset of all connected pose landmarks. Each key represents a start
    /// landmark, and each value in the key's value array represents an end landmark which is
    /// connected to the start landmark. These connections may be used for visualizing the landmark
    /// positions on a pose object.
    private static func poseConnections() -> [PoseLandmarkType: [PoseLandmarkType]] {
        struct PoseConnectionsHolder {
            static var connections: [PoseLandmarkType: [PoseLandmarkType]] = [
                //                PoseLandmarkType.leftEar: [PoseLandmarkType.leftEyeOuter],
                //                PoseLandmarkType.leftEyeOuter: [PoseLandmarkType.leftEye],
                //                PoseLandmarkType.leftEye: [PoseLandmarkType.leftEyeInner],
                //                PoseLandmarkType.leftEyeInner: [PoseLandmarkType.nose],
                //                PoseLandmarkType.nose: [PoseLandmarkType.rightEyeInner],
                //                PoseLandmarkType.rightEyeInner: [PoseLandmarkType.rightEye],
                //                PoseLandmarkType.rightEye: [PoseLandmarkType.rightEyeOuter],
                //                PoseLandmarkType.rightEyeOuter: [PoseLandmarkType.rightEar],
                //                PoseLandmarkType.mouthLeft: [PoseLandmarkType.mouthRight],
                PoseLandmarkType.leftShoulder: [
                    PoseLandmarkType.rightShoulder,
                    PoseLandmarkType.leftHip,
                ],
                PoseLandmarkType.rightShoulder: [
                    PoseLandmarkType.rightHip,
                    PoseLandmarkType.rightElbow,
                ],
                PoseLandmarkType.rightWrist: [
                    PoseLandmarkType.rightElbow,
                    PoseLandmarkType.rightThumb,
                    PoseLandmarkType.rightIndexFinger,
                    PoseLandmarkType.rightPinkyFinger,
                ],
                PoseLandmarkType.leftHip: [PoseLandmarkType.rightHip, PoseLandmarkType.leftKnee],
                PoseLandmarkType.rightHip: [PoseLandmarkType.rightKnee],
                PoseLandmarkType.rightKnee: [PoseLandmarkType.rightAnkle],
                PoseLandmarkType.leftKnee: [PoseLandmarkType.leftAnkle],
                PoseLandmarkType.leftElbow: [PoseLandmarkType.leftShoulder],
                PoseLandmarkType.leftWrist: [
                    PoseLandmarkType.leftElbow, PoseLandmarkType.leftThumb,
                    PoseLandmarkType.leftIndexFinger,
                    PoseLandmarkType.leftPinkyFinger,
                ],
                PoseLandmarkType.leftAnkle: [PoseLandmarkType.leftHeel, PoseLandmarkType.leftToe],
                PoseLandmarkType.rightAnkle: [PoseLandmarkType.rightHeel, PoseLandmarkType.rightToe],
                PoseLandmarkType.rightHeel: [PoseLandmarkType.rightToe],
                PoseLandmarkType.leftHeel: [PoseLandmarkType.leftToe],
                PoseLandmarkType.rightIndexFinger: [PoseLandmarkType.rightPinkyFinger],
                PoseLandmarkType.leftIndexFinger: [PoseLandmarkType.leftPinkyFinger],
            ]
        }
        return PoseConnectionsHolder.connections
    }
    
    /// Returns a color interpolated between to other colors.
    ///
    /// - Parameters:
    ///   - fromColor: The start color of the interpolation.
    ///   - toColor: The end color of the interpolation.
    ///   - ratio: The ratio in range [0, 1] by which the colors should be interpolated. Passing 0
    ///         results in `fromColor` and passing 1 results in `toColor`, whereas passing 0.5 results
    ///         in a color that is half-way between `fromColor` and `startColor`. Values are clamped
    ///         between 0 and 1.
    /// - Returns: The interpolated color.
    private static func interpolatedColor(
        fromColor: UIColor, toColor: UIColor, ratio: CGFloat
    ) -> UIColor {
        var fromR: CGFloat = 0
        var fromG: CGFloat = 0
        var fromB: CGFloat = 0
        var fromA: CGFloat = 0
        fromColor.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        
        var toR: CGFloat = 0
        var toG: CGFloat = 0
        var toB: CGFloat = 0
        var toA: CGFloat = 0
        toColor.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let clampedRatio = max(0.0, min(ratio, 1.0))
        
        let interpolatedR = fromR + (toR - fromR) * clampedRatio
        let interpolatedG = fromG + (toG - fromG) * clampedRatio
        let interpolatedB = fromB + (toB - fromB) * clampedRatio
        let interpolatedA = fromA + (toA - fromA) * clampedRatio
        
        return UIColor(
            red: interpolatedR, green: interpolatedG, blue: interpolatedB, alpha: interpolatedA)
    }
    
    /// Adds a gradient-colored line segment subview in a given `view`.
    ///
    /// - Parameters:
    ///   - fromPoint: The starting point of the line, in the view's coordinate space.
    ///   - toPoint: The end point of the line, in the view's coordinate space.
    ///   - inView: The view to which the line should be added as a subview.
    ///   - colors: The colors that the gradient should traverse over. Must be non-empty.
    ///   - width: The width of the line segment.
    private static func addLineSegment(
        fromPoint: CGPoint, toPoint: CGPoint, inView: UIView, colors: [UIColor], width: CGFloat
    ) {
        let viewWidth = inView.bounds.width
        let viewHeight = inView.bounds.height
        if viewWidth == 0.0 || viewHeight == 0.0 {
            return
        }
        let path = UIBezierPath()
        path.move(to: fromPoint)
        path.addLine(to: toPoint)
        let lineMaskLayer = CAShapeLayer()
        lineMaskLayer.path = path.cgPath
        lineMaskLayer.strokeColor = UIColor.black.cgColor
        lineMaskLayer.fillColor = nil
        lineMaskLayer.opacity = 1.0
        lineMaskLayer.lineWidth = width
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: fromPoint.x / viewWidth, y: fromPoint.y / viewHeight)
        gradientLayer.endPoint = CGPoint(x: toPoint.x / viewWidth, y: toPoint.y / viewHeight)
        gradientLayer.frame = inView.bounds
        var CGColors = [CGColor]()
        for color in colors {
            CGColors.append(color.cgColor)
        }
        if CGColors.count == 1 {
            // Single-colored lines must still supply a start and end color for the gradient layer to
            // render anything. Just add the single color to the colors list again to fulfill this
            // requirement.
            CGColors.append(colors[0].cgColor)
        }
        gradientLayer.colors = CGColors
        gradientLayer.mask = lineMaskLayer
        
        let lineView = UIView(frame: inView.bounds)
        lineView.layer.addSublayer(gradientLayer)
        lineView.isAccessibilityElement = true
        lineView.accessibilityIdentifier = Constants.lineViewIdentifier
        inView.addSubview(lineView)
    }
    
    /// Converts an image buffer to a `UIImage`.
    ///
    /// @param imageBuffer The image buffer which should be converted.
    /// @param orientation The orientation already applied to the image.
    /// @return A new `UIImage` instance.
    public static func createUIImage(
        from imageBuffer: CVImageBuffer,
        orientation: UIImage.Orientation
    ) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: Constants.originalScale, orientation: orientation)
    }
    
    
    public static func imageOrientation(
        fromDevicePosition devicePosition: AVCaptureDevice.Position = .back
    ) -> UIImage.Orientation {
        var deviceOrientation = UIDevice.current.orientation
        if deviceOrientation == .faceDown || deviceOrientation == .faceUp
            || deviceOrientation
            == .unknown
        {
            deviceOrientation = currentUIOrientation()
        }
        switch deviceOrientation {
        case .portrait:
            return devicePosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return devicePosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return devicePosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return devicePosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .up
        @unknown default:
            fatalError()
        }
    }
    
    private static func currentUIOrientation() -> UIDeviceOrientation {
        let deviceOrientation = { () -> UIDeviceOrientation in
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:
                return .landscapeRight
            case .landscapeRight:
                return .landscapeLeft
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .portrait, .unknown:
                return .portrait
            @unknown default:
                fatalError()
            }
        }
        guard Thread.isMainThread else {
            var currentOrientation: UIDeviceOrientation = .portrait
            DispatchQueue.main.async {
                currentOrientation = deviceOrientation()
            }
            return currentOrientation
        }
        return deviceOrientation()
    }
    
}

// MARK: - Extension

extension CGRect {
    /// Returns a `Bool` indicating whether the rectangle's values are valid`.
    func isValid() -> Bool {
        return
        !(origin.x.isNaN || origin.y.isNaN || width.isNaN || height.isNaN || width < 0 || height < 0)
    }
}

// MARK: - Constants

private enum Constants {
    static let circleViewAlpha: CGFloat = 0.7
    static let circleViewIdentifier = "MLKit Circle View"
    static let lineViewIdentifier = "MLKit Line View"
    static let originalScale: CGFloat = 1.0
}
