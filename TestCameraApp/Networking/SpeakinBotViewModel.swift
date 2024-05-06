//
//  SpeakinBotViewModel.swift
//  TestCameraApp
//
//  Created by Gokul Murugan on 03/05/24.

import Foundation
import AVFoundation

struct EndPoint {
    var path: String
    var queryItems: [URLQueryItem] = []
}

extension EndPoint{
    var url: URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = "52.25.229.242"
        components.port = 8000
        components.path = "/" + path
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            preconditionFailure(
                "Invalid URL components: \(components)"
            )
        }
        
        return url
    }
}

class SpeakingBotViewModel{
    let postData:[String:Any]
    let apiName:String
    lazy var synthesizer = AVSpeechSynthesizer()
    var speechUtterance:AVSpeechUtterance?
    init(postData: [String : Any], apiName:String) {
        self.postData = postData
        self.apiName = apiName
    }
    
    func sendFeedback(){
        print("sending feedback")
        guard let urlString = URL(string: "http://52.25.229.242:8000/feedback/\(apiName)/") else {
            print("Url Creation Error")
            return
        }
        print(urlString)
        var request = URLRequest(url: urlString)
        request.httpMethod = "POST"
        guard let jsonData = try? JSONSerialization.data(withJSONObject: postData) else {
            print("JSON Data Creation Error")
            return
        }
        request.httpBody = jsonData
        request.addValue("Token 0f9af22e67ff1923b61d9fb214a80f7541f7f306", forHTTPHeaderField: "Authorization")
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            //            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            //            if let responseJSON = responseJSON as? [String: Any] {
            //                print(responseJSON)
            //            }
            do{
                let decodedData = try JSONDecoder().decode(Feedback.self, from: data)
                for feedbackResult in decodedData.data.result {
                    if feedbackResult.messageType == "negative" {
                        //self.speak(text: feedbackResult.voiceTitle)
                    }
                    
                    print("\(feedbackResult.messageType) : \(feedbackResult.voiceTitle)")
                }
            } catch{
                print(error)
            }
        }
        task.resume()
        
        
    }
    
    private func speak(text: String) {
        speechUtterance = AVSpeechUtterance(string: text)
        DispatchQueue.global(qos: .background).sync{
            synthesizer.speak(speechUtterance ?? AVSpeechUtterance(string: "Negative"))
        }
        
    }
    
}
