//
//  DiningViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/15/25.
//

import Foundation
import FirebaseFirestore
//import FirebaseFirestoreSwift

class DiningViewModel: ObservableObject {
    @Published var menu: MealMenu? = nil
    @Published var errorMessage: String? = nil
    private var db = Firestore.firestore()
    
    func fetchMenu(hall: String) {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10) // "YYYY-MM-DD"
        let docId = "\(hall)_\(today)"
        
        db.collection("meals").document(String(docId)).getDocument { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
                return
            }
            
            if let snapshot = snapshot {
                if snapshot.exists {
                    do {
                        let data = try snapshot.data(as: MealMenu.self)
                        DispatchQueue.main.async {
                            self.menu = data
                            self.errorMessage = nil // 성공 시 에러 초기화
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.errorMessage = "Parse error: \(error.localizedDescription)"
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "🍳 Today's menu will be updated at 7 AM."
                    }
                }
            }
        }
    }
}
