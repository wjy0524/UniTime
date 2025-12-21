//
//  ChatService.swift
//  Quad-2025-project
//
//  Created by Isaac Choi on 12/20/25.
//

import FirebaseFunctions
import Foundation

class ChatService {
    private let functions = Functions.functions()
    
    func sendMessage(_ message: String) async throws -> String {
        let result = try await functions.httpsCallable("chat").call(["message": message])
        
        if let data = result.data as? [String: Any],
           let reply = data["reply"] as? String {
            return reply
        }
        
        throw NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
    }
}
