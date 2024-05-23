//
//  VerticalProgressView.swift
//  TestCameraApp
//
//  Created by Gokul Murugan on 17/05/24.
//

import UIKit

class VerticalProgressView: UIView {
    var progressView = UIProgressView()
    let progressViewBackground = UIView()
    var progress:Float = 0.0
    var wrapperStack = UIView()
    var seconds = returnUIlabel(title: "2.5", fontSize: 36)
    var secondsValue = "2.5"
    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        
        wrapperStack.backgroundColor = .white
        let completeStack = makeStackView(withOrientation: .vertical, spacing: 15)

        // To create speed label
        let labelStack = makeStackView(withOrientation: .horizontal)
        let speedImage = makeImageView(withImageName: "repSpeed", width: 11.25, height: 9.33)
        let labelName = returnUIlabel(title: "Rep Speed", fontSize: 10)
        labelStack.addArrangedSubview(speedImage)
        labelStack.addArrangedSubview(labelName)
        completeStack.addArrangedSubview(labelStack)

        // Configure background view
        progressViewBackground.backgroundColor = .white
        progressViewBackground.layer.cornerRadius = 10
        progressViewBackground.layer.borderWidth = 1
        progressViewBackground.layer.borderColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        progressViewBackground.layer.shadowColor = UIColor.black.withAlphaComponent(0.4).cgColor
        progressViewBackground.layer.shadowOpacity = 0.5
        progressViewBackground.layer.shadowOffset = .init(width: 3, height: 3)
        progressViewBackground.layer.shadowRadius = 5

        // Set up the shadow path for progressViewBackground after the layout is finalized
        DispatchQueue.main.async {[weak self] in
            let shadowRect = self?.progressViewBackground.bounds
            let shadowPath = UIBezierPath(roundedRect: shadowRect!, cornerRadius: 10).cgPath
            self?.progressViewBackground.layer.shadowPath = shadowPath
        }
        
        let mainHorizontalStack = makeStackView(withOrientation: .horizontal,distribution: .fillProportionally)
        // Setting up progress view properties
        progressView.progress = progress
        updateProgressTintColor()
        progressView.trackTintColor = .white
        progressView.layer.cornerRadius = 5
        progressView.clipsToBounds = true
        progressViewBackground.addSubview(progressView)

        // Rotate the progress view by 90 degrees
        progressView.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        
        // Add background view to the main stack view
        mainHorizontalStack.addArrangedSubview(progressViewBackground)
        

        // Make stack view to add HIGH and LOW labels
        let highLabel = returnUIlabel(title: "High", fontSize: 10, color: .gray)
        highLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        let lowLabel = returnUIlabel(title: "Low", fontSize: 10, color: .gray)
        lowLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))

        let highLowStack = makeStackView(withOrientation: .vertical,distribution: .fillEqually, spacing: 30)
        highLowStack.addArrangedSubview(lowLabel)
        highLowStack.addArrangedSubview(highLabel)
        mainHorizontalStack.addArrangedSubview(highLowStack)

        completeStack.addArrangedSubview(mainHorizontalStack)

        let secondsStack = makeStackView(withOrientation: .horizontal,distribution: .fillProportionally,spacing: 2)
        seconds = returnUIlabel(title: secondsValue, fontSize: 36)
        let staticSeconds = returnUIlabel(title: "sec", fontSize: 10)
        secondsStack.addArrangedSubview(seconds)
        secondsStack.addArrangedSubview(staticSeconds)
        completeStack.addArrangedSubview(secondsStack)

        wrapperStack.addSubview(completeStack)
        wrapperStack.layer.cornerRadius = 20
        addSubview(wrapperStack)

        // Set up constraints for background view
        progressViewBackground.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        completeStack.translatesAutoresizingMaskIntoConstraints = false
        wrapperStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // Constraints for progressViewBackground
            progressViewBackground.widthAnchor.constraint(equalToConstant: 20),
            progressViewBackground.heightAnchor.constraint(equalToConstant: 100),

            // Constraints for progressView
            progressView.centerXAnchor.constraint(equalTo: progressViewBackground.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: progressViewBackground.centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 90),
            progressView.heightAnchor.constraint(equalToConstant: 10),

            // Constraints for completeStack
            completeStack.leadingAnchor.constraint(equalTo: wrapperStack.leadingAnchor, constant: 15),
            completeStack.trailingAnchor.constraint(equalTo: wrapperStack.trailingAnchor, constant: -15),
            completeStack.topAnchor.constraint(equalTo: wrapperStack.topAnchor, constant: 15),
            completeStack.bottomAnchor.constraint(equalTo: wrapperStack.bottomAnchor, constant: -15),

            // Constraints for wrapperStack
            wrapperStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            wrapperStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            wrapperStack.topAnchor.constraint(equalTo: topAnchor),
            wrapperStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            wrapperStack.widthAnchor.constraint(equalToConstant: 105),
            wrapperStack.heightAnchor.constraint(equalToConstant: 200),
        ])
    }

    private func updateProgressTintColor() {
        if progressView.progress <= 0.8 && progressView.progress > 0.6 {
            progressView.progressTintColor = UIColor(red: 234/255.0, green: 158/255.0, blue: 35/255.0, alpha: 1)
        } else if progressView.progress <= 0.6 && progressView.progress > 0.4 {
            progressView.progressTintColor = UIColor(red: 54/255.0, green: 188/255.0, blue: 115/255.0, alpha: 1)
        } else {
            progressView.progressTintColor = UIColor(red: 166/255.0, green: 69/255.0, blue: 69/255.0, alpha: 1)
        }
    }

    func updateProgress(_ progress: Float, seconds:String) {
        self.progress = progress
        secondsValue = seconds
        DispatchQueue.main.async {[weak self] in
            self?.wrapperStack.removeFromSuperview()
            self?.wrapperStack = UIStackView()
            self?.setupUI()
            self?.updateProgressTintColor()
        }
    }
}
