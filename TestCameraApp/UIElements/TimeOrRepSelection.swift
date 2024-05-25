//
//  TimeOrRepSelection.swift
//  TestCameraApp
//
//  Created by Gokul Murugan on 25/05/24.
//

import UIKit

protocol SelectionDelegate{
    func selectedInput(input:String?)
}


class TimeOrRepSelection: UIView {
    
    var delegate:SelectionDelegate?
    let type:String
    var wrapperView:UIView = UIView()
    let completeStack = makeStackView(withOrientation: .vertical,alignment: .leading,distribution: .equalSpacing)
    var titleName:String
    let timer = ["20", "40", "60", "80"]
    let reps = ["8", "10", "12", "15"]
    init(type: String) {
        self.type = type
        if type == "reps"{
            titleName = "Select a repetition"
        } else {
            titleName = "Select a timer"
        }
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(){
        wrapperView.backgroundColor = .white
        wrapperView.layer.cornerRadius = 15
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        
        //Adding Label to the view
        let titleLabel = returnUIlabel(title: titleName, fontSize: 14,color: .black,weight: .bold)
        completeStack.addArrangedSubview(titleLabel)
        
        if type == "reps"{
            makeLables(with: reps, typeOfSelection: "Reps")
        } else {
            makeLables(with: timer, typeOfSelection: "Sec")
        }
        
        wrapperView.addSubview(completeStack)
        addSubview(wrapperView)
        NSLayoutConstraint.activate([
            completeStack.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor,constant: 25),
            completeStack.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor,constant: -10),
            completeStack.topAnchor.constraint(equalTo: wrapperView.topAnchor,constant: 30),
            completeStack.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor,constant: -30),
            
            wrapperView.leadingAnchor.constraint(equalTo: leadingAnchor),
            wrapperView.trailingAnchor.constraint(equalTo: trailingAnchor),
            wrapperView.topAnchor.constraint(equalTo: topAnchor),
            wrapperView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func makeLables(with type:[String], typeOfSelection:String){
        for (index, item) in type.enumerated() {
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapFunction))
            let label = returnUIlabel(title: "🔘 \(item) \(typeOfSelection)", fontSize: 14,color: .black, weight: .medium)
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(tap)
            label.accessibilityIdentifier = "\(item)"
            completeStack.addArrangedSubview(label)
        }
    }
    
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        delegate?.selectedInput(input: sender.view?.accessibilityIdentifier)
    }
    
}
