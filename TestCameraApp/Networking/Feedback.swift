//
//  Feedback.swift
//  TestCameraApp
//
//  Created by Gokul Murugan on 03/05/24.
//

import Foundation

// MARK: - Feedback Model
struct Feedback:Codable {
    let success: Bool
    let data: DataClass
    let message: String
}
// MARK: - DataClass
struct DataClass: Codable {
    let result: [ResultValue]
    let finalScore: Int?
    let accuracy: Double?
    let totalScore, repsIdentified: Int?
    let bodyPartsColor: BodyPartsColor?


    enum CodingKeys: String, CodingKey {
        case result
        case finalScore = "final_score"
        case accuracy
        case totalScore = "total_score"
        case repsIdentified = "reps_identified"
        case bodyPartsColor = "body_parts_color"
    }
}

// MARK: - BodyPartsColor
struct BodyPartsColor: Codable {
    let red: [String]
    let green: [String]
}

// MARK: - Result
struct ResultValue: Codable {
    let messageType, text, voiceTitle, messageTitle: String
    let score: Int

    enum CodingKeys: String, CodingKey {
        case messageType = "message_type"
        case text
        case voiceTitle = "voice_title"
        case messageTitle = "message_title"
        case score
    }
}
