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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.01)
        // add countdownView as subview
        view.addSubview(countdownView)
        
        // set up countdownView's appearance
        //countdownView.backgroundColor = .black.withAlphaComponent(0.5)
        countdownView.addSubview(countdownLabel)
        
        
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        countdownLabel.centerXAnchor.constraint(equalTo: countdownView.centerXAnchor).isActive = true
        countdownLabel.centerYAnchor.constraint(equalTo: countdownView.centerYAnchor).isActive = true
        countdownLabel.text = "10"
        countdownView.startTimer(with: 3)
        countdownLabel.textColor = UIColor.white
        countdownLabel.font = UIFont.boldSystemFont(ofSize: 20)
        
        // set up constraints for countdownView
        countdownView.translatesAutoresizingMaskIntoConstraints = false
        countdownView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        countdownView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
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
