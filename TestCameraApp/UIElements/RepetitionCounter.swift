//
//  RepetitionCounter.swift
//  TestCameraApp
//
//  Created by Gokul Murugan on 09/05/24.
//

import MLKitPoseDetection
import MLKit

protocol RepetitionCountUIUpdateDelegate{
    func getRepCount(rep:String)
    func didCompletePoses()
}

struct ExerciseAngles:Codable{
    let angle_1:[Int]
    let angle_2:[Int]
}

class RepetitionCounter:UIView{
    var muscleGroup:[String]
    var startAngle:ExerciseAngles
    var endAngle:ExerciseAngles
    var totalReps:String
    var noOfReps:String = "0"
    var repDelegate:RepetitionCountUIUpdateDelegate?
    private var startIndicator:Bool = false
    var viewController:ViewController?
    init(muscleGroup: [String], startAngle: ExerciseAngles, endAngle: ExerciseAngles, totalReps: String, vc:ViewController) {
        self.muscleGroup = muscleGroup
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.totalReps = totalReps
        self.viewController = vc
        super.init(frame: .zero)
        setupDelegate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func calculateCount() {
        if Int(noOfReps)! >= Int(totalReps)!{
            //print("Completed")
            self.repDelegate?.didCompletePoses()
        } else {
            self.repDelegate?.getRepCount(rep:noOfReps)
            //print("\(noOfReps) / \(totalReps)")
        }
    }
    
    
}


//MARK: TO calculate the reps.
extension RepetitionCounter:PoseDataDelegate{
    
    //MARK: The function to calculate the repition based on poses in each frame
    func getPoses(pose: Pose) {
        let (left , right) = changeStringToLandmark(string: muscleGroup)
        
        let l1 = [pose.landmark(ofType: left[0]),pose.landmark(ofType: left[1]),pose.landmark(ofType: left[2])]
        
        let r1 = [pose.landmark(ofType: right[0]),pose.landmark(ofType:right[1]),pose.landmark(ofType: right[2])]
        
        //STEP 1:CHECK WHICH BODY SIDE IS CLOSER.. IS IT LEFT SIDE OR RIGHT SIDE
        //FOR THAT CALC ELBOW, SHOULDER, WRIST CHECK
        // IF RIGHT_ELBOW[Z] < LEFT_ELBOW[Z]:
        //PART_SELCTED = RIGHT
        //ELSE:
        //PART_SELECTED = 'LEFT'
        
        var leftCount = 0
        var rightCount = 0
        
        var selectedSide:[PoseLandmark] = []
        
        for i in 0..<l1.count{
            if l1[i].position.z < r1[i].position.z{
                leftCount += 1
            } else {
                rightCount += 1
            }
        }
        
        if leftCount > rightCount{
            selectedSide = l1
        } else {
            selectedSide = r1
        }
        
        //Step 2: Calculating the angle for the three selected points
        
        let angle = angleBetweenPoints(point1: CGPoint(x: selectedSide[0].position.x, y: selectedSide[0].position.y), point2: CGPoint(x: selectedSide[1].position.x, y: selectedSide[1].position.y), point3: CGPoint(x: selectedSide[2].position.x, y: selectedSide[2].position.y))
        
        //Create an array of the numbers from starting 2 angles and ending 2 angles. SO that we can check if the points is in between the range to increase the repcounter
        let startAngleRange1 = Array(stride(from: (startAngle.angle_1[0]), to: (startAngle.angle_1[1]), by: 1))
        let startAngleRange2 = Array(stride(from: (startAngle.angle_2[0]), to: (startAngle.angle_2[1]), by: 1))
        let endAngleRange1 = Array(stride(from: (endAngle.angle_1[0]), to: (endAngle.angle_1[1]), by: 1))
        let endAngleRange2 = Array(stride(from: (endAngle.angle_2[0]), to: (endAngle.angle_2[1]), by: 1))
        
        
        //Step3: CHECK THE CONDITIONS AND UPDATE THE GLOBAL VARIABLES
        if startIndicator && (endAngleRange1.contains(Int(angle)) || endAngleRange2.contains(Int(angle))) {
            noOfReps = "\(Int(noOfReps)!+1)"
            startIndicator = false
        }
        if !startIndicator {
            if startAngleRange1.contains(Int(angle)) || startAngleRange2.contains(Int(angle)) {
                startIndicator = true
            }
        }
        calculateCount()
    }
    
    //MARK: To change the set of arrays from string to PoseLandmarkType
    //This function will be used to change the parts to consider to get angles and comapre from String to LandmarkType
    private func changeStringToLandmark(string:[String]) -> ([PoseLandmarkType],[PoseLandmarkType]){
        var leftLandmarkTypes:[PoseLandmarkType] = []
        var rightLandmarkTypes:[PoseLandmarkType] = []
        for item in string{
            switch item{
            case "SHOULDER":
                leftLandmarkTypes.append(.leftShoulder)
                rightLandmarkTypes.append(.rightShoulder)
                
            case "ELBOW":
                leftLandmarkTypes.append(.leftElbow)
                rightLandmarkTypes.append(.rightElbow)
                
            case "WRIST":
                leftLandmarkTypes.append(.leftWrist)
                rightLandmarkTypes.append(.rightWrist)
                
            case "EYE":
                leftLandmarkTypes.append(.leftEye)
                rightLandmarkTypes.append(.rightEye)
                leftLandmarkTypes.append(.leftEyeInner)
                rightLandmarkTypes.append(.rightEyeInner)
                leftLandmarkTypes.append(.leftEyeOuter)
                rightLandmarkTypes.append(.rightEyeOuter)
                
            case "EAR":
                leftLandmarkTypes.append(.leftEar)
                rightLandmarkTypes.append(.rightEar)
                
            case "MOUTH":
                leftLandmarkTypes.append(.mouthLeft)
                rightLandmarkTypes.append(.mouthRight)
                
            case "FINGER":
                leftLandmarkTypes.append(.leftIndexFinger)
                rightLandmarkTypes.append(.rightIndexFinger)
                leftLandmarkTypes.append(.leftPinkyFinger)
                rightLandmarkTypes.append(.rightPinkyFinger)
                leftLandmarkTypes.append(.leftThumb)
                rightLandmarkTypes.append(.rightThumb)
                
            case "HIP":
                leftLandmarkTypes.append(.leftHip)
                rightLandmarkTypes.append(.rightHip)
                
            case "KNEE":
                leftLandmarkTypes.append(.leftKnee)
                rightLandmarkTypes.append(.rightKnee)
                
            case "ANKLE":
                leftLandmarkTypes.append(.leftAnkle)
                rightLandmarkTypes.append(.rightAnkle)
                
            case "FOOT":
                leftLandmarkTypes.append(.leftHeel)
                rightLandmarkTypes.append(.rightHeel)
                leftLandmarkTypes.append(.leftToe)
                rightLandmarkTypes.append(.rightToe)
                
            default:
                print("Unknown case detected: \(item)")
            }
        }
        return (leftLandmarkTypes, rightLandmarkTypes)
    }
    
    //MARK: A Function to calculate the angle between 3 points.
    private func angleBetweenPoints(point1: CGPoint, point2: CGPoint, point3: CGPoint) -> Double {
        // Calculate vectors representing two sides of the triangle
        let vector1 = CGVector(dx: point1.x - point2.x, dy: point1.y - point2.y)
        let vector2 = CGVector(dx: point3.x - point2.x, dy: point3.y - point2.y)
        
        // Calculate dot product and magnitudes
        let dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy
        let magnitude1 = sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy)
        let magnitude2 = sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy)
        
        // Calculate the angle in radians
        let angleInRadians = acos(dotProduct / (magnitude1 * magnitude2))
        
        // Convert the angle to degrees
        let angleInDegrees = (angleInRadians * 180 / .pi).truncatingRemainder(dividingBy: 360)
        
        
        return angleInDegrees
    }
    
}

//MARK: To crate the view to display the Rep Counter
extension RepetitionCounter{
    private func setupDelegate(){
        self.viewController?.poseDelegate = self
    }
}

enum ActivityType{
    case Accuracy, Calories, Reps, Timer
}



public func makeStackView(withOrientation axis: NSLayoutConstraint.Axis,
                          alignment: UIStackView.Alignment = .fill,
                          distribution: UIStackView.Distribution = .fill,
                          spacing: CGFloat? = nil) -> UIStackView {
    let stackView = UIStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = axis
    stackView.distribution = distribution
    stackView.alignment = alignment
    stackView.spacing = spacing ?? 0.0
    
    return stackView
}

public func makeImageView(withImageName name: String,
                          width: CGFloat,
                          height: CGFloat, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImageView {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    if UIImage(systemName: name) == nil {
        imageView.image = UIImage(named: name)
    } else {
        imageView.image = UIImage(systemName: name)
    }
    imageView.heightAnchor.constraint(equalToConstant: height).isActive = true
    imageView.widthAnchor.constraint(equalToConstant: width).isActive = true
    imageView.contentMode = contentMode
    imageView.isUserInteractionEnabled = true
    return imageView
}

public func returnUIlabel(title:String, fontSize:CGFloat, color:UIColor = .darkGray ) -> UIView{
    let valueLabel = UILabel()
    valueLabel.translatesAutoresizingMaskIntoConstraints = false
    valueLabel.text = title
    valueLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
    valueLabel.textColor = color
    valueLabel.textAlignment = .center
    return valueLabel
}

public func addAllViewsTogether(mainStach:UIStackView, horizontalStack1:UIStackView, horizontalStack2:UIStackView, mainValue:String?, subValue:String?, iconName:String, iconTitle:String, colorforText:UIColor, subFontSize: CGFloat = 10){
    let icon = makeImageView(withImageName: iconName, width: 15, height: 15,contentMode: .scaleAspectFit)
    icon.tintColor = colorforText
    let view1 = returnUIlabel(title: iconTitle,fontSize: 10, color: colorforText)
    
    horizontalStack1.addArrangedSubview(icon)
    horizontalStack1.addArrangedSubview(view1)
    horizontalStack1.backgroundColor = .none
    let horizontalStack2 = makeStackView(withOrientation: .horizontal,alignment: .fill, spacing: 2)
    
    if let mainValue = mainValue, let subFont = subValue{
        let view2 = returnUIlabel(title: mainValue,fontSize: 36, color: colorforText)
        horizontalStack2.addArrangedSubview(view2)
        let view3 = returnUIlabel(title: subFont,fontSize: subFontSize, color: colorforText)
        horizontalStack2.addArrangedSubview(view3)
    } else{
        horizontalStack2.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
    horizontalStack2.backgroundColor = .none
    mainStach.layer.cornerRadius = 10
    mainStach.addArrangedSubview(horizontalStack1)
    mainStach.addArrangedSubview(horizontalStack2)
    
    NSLayoutConstraint.activate([
        view1.trailingAnchor.constraint(equalTo: horizontalStack1.trailingAnchor, constant: -10),
        icon.trailingAnchor.constraint(equalTo: view1.leadingAnchor, constant: 5)
    ])
    
    
    NSLayoutConstraint.activate([
        horizontalStack1.topAnchor.constraint(equalTo: mainStach.topAnchor, constant: 5),
        horizontalStack2.leadingAnchor.constraint(equalTo: mainStach.leadingAnchor, constant: 5),
        horizontalStack2.trailingAnchor.constraint(equalTo: mainStach.trailingAnchor, constant: -15),
    ])
    
    
}

