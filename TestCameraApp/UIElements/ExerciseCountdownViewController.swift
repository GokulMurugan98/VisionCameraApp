//
//  ExerciseCountdownViewController.swift
//  TestCameraApp
//
//  Created by Gokul Murugan on 15/05/24.
//

import UIKit

protocol ExerciseCountdownDelegate{
    func didFinishExerciseTimerCountdown()
    func currentCountDown(seconds:Int)
}

class ExerciseCountdownViewController: UIViewController {
    
    var timer: Timer?
    let countdownLabel = UILabel()
    let countdownView = CircularProgressView(isTrue: true,width: 75, height: 75,lineWidth: 5)
    var time:Int = 0
    var countdownDelegate: ExerciseCountdownDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.01)
        // add countdownView as subview
        let wrapperView = makeStackView(withOrientation: .vertical)
        let mainStack = makeStackView(withOrientation: .vertical)
        let imageView = makeImageView(withImageName: "timer", width: 20, height: 20)
        let label = returnUIlabel(title: "Timer", fontSize: 16)
        let horizontalStack = makeStackView(withOrientation: .horizontal)
        horizontalStack.addArrangedSubview(imageView)
        horizontalStack.addArrangedSubview(label)
        
        
        mainStack.addArrangedSubview(horizontalStack)
        mainStack.addArrangedSubview(countdownView)
        
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor).isActive = true
        horizontalStack.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor).isActive = true
        horizontalStack.topAnchor.constraint(equalTo: mainStack.topAnchor).isActive = true
        horizontalStack.bottomAnchor.constraint(equalTo: countdownView.topAnchor).isActive = true
        
        
        mainStack.layer.cornerRadius = 10
        mainStack.backgroundColor = .black.withAlphaComponent(0.5)
        wrapperView.addSubview(mainStack)
        view.addSubview(wrapperView)
        
        
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor,constant: 10).isActive = true
        mainStack.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor,constant: 10).isActive = true
        mainStack.topAnchor.constraint(equalTo: wrapperView.topAnchor,constant: 10).isActive = true
        mainStack.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor,constant: 10).isActive = true
        
        // set up countdownView's appearance
        //countdownView.backgroundColor = .black.withAlphaComponent(0.5)
        countdownView.addSubview(countdownLabel)
        
        
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        countdownLabel.centerXAnchor.constraint(equalTo: countdownView.centerXAnchor).isActive = true
        countdownLabel.centerYAnchor.constraint(equalTo: countdownView.centerYAnchor).isActive = true
        
        
        countdownLabel.textColor = UIColor.white
        countdownLabel.font = UIFont.boldSystemFont(ofSize: 18)
        
        // set up constraints for countdownView
        countdownView.translatesAutoresizingMaskIntoConstraints = false
        countdownView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,constant: -20).isActive = true
        countdownView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 20).isActive = true
        countdownView.widthAnchor.constraint(equalToConstant: 75).isActive = true
        countdownView.heightAnchor.constraint(equalToConstant: 75).isActive = true
        countdownView.layer.cornerRadius = 15
        countdownView.layer.shadowRadius = 5

        
    }
    
    
    func startTimer(with time:Int){
        countdownView.startTimer(with: time)
        countdownLabel.text = "\(time)"
        // start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.countdownView.remainingTime == 1 {
                self.timer?.invalidate()
                self.countdownDelegate?.didFinishExerciseTimerCountdown()
                
            } else {
                let currentTime = countdownView.remainingTime - 1
                self.countdownLabel.text = "\(currentTime)"
                self.countdownDelegate?.currentCountDown(seconds: currentTime)
            }
        }
        
    }
}
