//
//  GifView.swift
//  TestCameraApp
//
//  Created by Gokul Murugan on 20/05/24.
//

import UIKit

class GifView: UIView {
    let gifUrlString: String?
    private let gifImageView = UIImageView()
    
    private let wrapperStack = UIStackView()
    init(frame: CGRect, gifUrlString: String?) {
        self.gifUrlString = gifUrlString
        super.init(frame: frame)
        setupView()
        loadGif()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        let mainStack = makeStackView(withOrientation: .vertical)
        let uiLabel = returnUIlabel(title: "How to do:", fontSize: 15,color: .gray, textAlignment: .left)
        mainStack.addArrangedSubview(uiLabel)
        mainStack.addArrangedSubview(gifImageView)
        gifImageView.translatesAutoresizingMaskIntoConstraints = false
        gifImageView.contentMode = .scaleAspectFill
        gifImageView.clipsToBounds = true
        wrapperStack.backgroundColor = .white
        wrapperStack.layer.cornerRadius = 15
        wrapperStack.addSubview(mainStack)
        self.addSubview(wrapperStack)
        wrapperStack.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            gifImageView.heightAnchor.constraint(equalToConstant: self.bounds.size.height / 2),
            gifImageView.widthAnchor.constraint(equalToConstant: self.bounds.size.width/1.5),
            
            mainStack.leadingAnchor.constraint(equalTo: wrapperStack.leadingAnchor, constant: 10),
            mainStack.trailingAnchor.constraint(equalTo: wrapperStack.trailingAnchor, constant: -10),
            mainStack.topAnchor.constraint(equalTo: wrapperStack.topAnchor, constant: 10),
            mainStack.bottomAnchor.constraint(equalTo: wrapperStack.bottomAnchor, constant: -10),
            
            
            wrapperStack.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            wrapperStack.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    
    func loadGif() {
        guard let gifUrlString = gifUrlString, let url = URL(string: gifUrlString) else {
            print("Invalid GIF URL string.")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error loading GIF data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received for URL: \(gifUrlString)")
                return
            }
            
            let animatedImage = UIImage.gifImageWithData(data)
            DispatchQueue.main.async {
                self?.gifImageView.image = animatedImage
            }
        }.resume()
    }
}


extension UIImage {
    
    public class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("Unable to create image source from data.")
            return nil
        }
        
        return UIImage.animatedImageWithSource(source)
    }
    
    public class func gifImageWithURL(_ gifUrl: String) -> UIImage? {
        guard let url = URL(string: gifUrl) else {
            print("Invalid URL string: \(gifUrl)")
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else {
            print("Unable to load data from URL: \(gifUrl)")
            return nil
        }
        
        return gifImageWithData(data)
    }
    
    private class func delayForImageAtIndex(_ index: Int, source: CGImageSource) -> Double {
        var delay = 0.1
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)
        
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        if let delayValue = delayObject as? Double, delayValue > 0 {
            delay = delayValue
        }
        
        return delay
    }
    
    private class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()
        
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
            
            let delaySeconds = UIImage.delayForImageAtIndex(i, source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Convert to ms
        }
        
        let duration: Int = delays.reduce(0, +)
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()
        
        for i in 0..<count {
            let frame = UIImage(cgImage: images[i])
            let frameCount = delays[i] / gcd
            
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        return UIImage.animatedImage(with: frames, duration: Double(duration) / 1000.0)
    }
    
    private class func gcdForArray(_ array: [Int]) -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for value in array {
            gcd = UIImage.gcdForPair(value, gcd)
        }
        
        return gcd
    }
    
    private class func gcdForPair(_ a: Int, _ b: Int) -> Int {
        var a = a
        var b = b
        if a < b {
            swap(&a, &b)
        }
        
        while b != 0 {
            let remainder = a % b
            a = b
            b = remainder
        }
        
        return a
    }
}
