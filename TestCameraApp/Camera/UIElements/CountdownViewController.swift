//
//  CountdownViewController.swift
//  TestCameraApp
//
//  Created by Gokul Murugan on 07/05/24.
//

import UIKit

protocol CountdownDelegate {
    func didFinishCountdown()
}

class CountdownViewController: UIViewController {
    
    var timer: Timer?
    let countdownLabel = UILabel()
    let countdownView = CircularProgressView(isTrue: true)
    var gifURLString:String = ""
    var countdownDelegate: CountdownDelegate?
    let wrapperView = UIStackView()
    var isWrapped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.01)
        // add countdownView as subview
        
        if isWrapped{
            wrapperView.layer.cornerRadius = 15
            wrapperView.backgroundColor = .gray.withAlphaComponent(0.5)
            wrapperView.addSubview(countdownView)
            view.addSubview(wrapperView)
            wrapperView.translatesAutoresizingMaskIntoConstraints = false
            wrapperView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            wrapperView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            
            countdownView.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 10).isActive = true
            countdownView.topAnchor.constraint(equalTo: wrapperView.topAnchor, constant: 10).isActive = true
            countdownView.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -10).isActive = true
            countdownView.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: -10).isActive = true
            
            
            
        }else {
            view.addSubview(countdownView)
            countdownView.translatesAutoresizingMaskIntoConstraints = false
            countdownView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            countdownView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
        
        
        // set up countdownView's appearance
        //countdownView.backgroundColor = .black.withAlphaComponent(0.5)
        countdownView.addSubview(countdownLabel)
        
        
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        countdownLabel.centerXAnchor.constraint(equalTo: countdownView.centerXAnchor).isActive = true
        countdownLabel.centerYAnchor.constraint(equalTo: countdownView.centerYAnchor).isActive = true
        countdownLabel.text = "10"
        countdownView.startTimer(with: 2)
        countdownLabel.textColor = UIColor.white
        countdownLabel.font = UIFont.boldSystemFont(ofSize: 20)
        
        // set up constraints for countdownView
       
        countdownView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        countdownView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        countdownView.layer.cornerRadius = 15
        countdownView.layer.shadowRadius = 5

        // start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.countdownView.remainingTime == 1 {
                self.timer?.invalidate()
                self.dismiss(animated: false) {
                    self.countdownDelegate?.didFinishCountdown()
                }
            } else {
                let currentTime = countdownView.remainingTime - 1
                self.countdownLabel.text = "\(currentTime)"
            }
        }
    }
}
