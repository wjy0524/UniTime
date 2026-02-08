//
//  AddGradeItemView.swift
//  Quad-2025-project
//
//  Sheet for adding/editing a grade item
//  Created by Isaac Choi
//

import SwiftUI

struct AddGradeItemView: View {
    @ObservedObject var viewModel: GradeCalViewModel
    let courseId: UUID
    var preselectedCategory: GradeCategory = .assignments
    var itemToEdit: GradeItem? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var scoreReceived = ""
    @State private var scoreTotal = "100"
    @State private var weight = ""
    @State private var category: GradeCategory = .assignments
    @State private var showWeightError = false
    
    private var isEditing: Bool { itemToEdit != nil }
    
    private var isValid: Bool {
        !name.isEmpty &&
        Double(scoreTotal) != nil &&
        Double(weight) != nil &&
        (Double(scoreTotal) ?? 0) > 0 &&
        (Double(weight) ?? 0) > 0 &&
        (Double(weight) ?? 0) <= 100
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Item Name
                Section {
                    TextField("Item name (e.g., Midterm 1)", text: $name)
                } header: {
                    Text("Name")
                }
                
                // Category
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(GradeCategory.allCases) { cat in
                            HStack {
                                Image(systemName: cat.iconName)
                                Text(cat.rawValue)
                            }
                            .tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Category")
                }
                
                // Score
                Section {
                    HStack {
                        TextField("Score (leave empty if not graded)", text: $scoreReceived)
                            .keyboardType(.decimalPad)
                        
                        Text("/")
                            .foregroundColor(.secondary)
                        
                        TextField("Total", text: $scoreTotal)
                            .keyboardType(.decimalPad)
                    }
                    
                    if let received = Double(scoreReceived),
                       let total = Double(scoreTotal),
                       total > 0 {
                        HStack {
                            Text("Percentage")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f%%", (received / total) * 100))
                                .fontWeight(.medium)
                        }
                    }
                } header: {
                    Text("Score")
                } footer: {
                    Text("Leave score empty for upcoming assignments the AI can predict")
                }
                
                // Weight
                Section {
                    HStack {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                        
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                    
                    if let course = viewModel.getCourse(by: courseId) {
                        HStack {
                            Text("Remaining weight")
                                .foregroundColor(.secondary)
                            Spacer()
                            
                            let remaining = isEditing
                                ? course.remainingWeight + (itemToEdit?.weight ?? 0)
                                : course.remainingWeight
                            
                            Text(String(format: "%.1f%%", remaining))
                                .fontWeight(.medium)
                                .foregroundColor(remaining > 0 ? .green : .red)
                        }
                    }
                } header: {
                    Text("Weight")
                } footer: {
                    Text("How much this item counts toward your final grade")
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Grade Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Add") {
                        saveItem()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                category = preselectedCategory
                
                if let item = itemToEdit {
                    name = item.name
                    if let score = item.scoreReceived {
                        scoreReceived = String(format: "%.1f", score)
                    }
                    scoreTotal = String(format: "%.1f", item.scoreTotal)
                    weight = String(format: "%.1f", item.weight)
                    category = item.category
                }
            }
            .alert("Weight Exceeded", isPresented: $showWeightError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Total weight would exceed 100%. Please adjust the weight.")
            }
        }
    }
    
    private func saveItem() {
        guard let scoreTotalNum = Double(scoreTotal),
              let weightNum = Double(weight) else { return }
        
        let scoreReceivedNum = Double(scoreReceived)
        
        if !viewModel.canAddWeight(weightNum, to: courseId, excluding: itemToEdit?.id) {
            showWeightError = true
            return
        }
        
        if isEditing, var item = itemToEdit {
            item.name = name
            item.scoreReceived = scoreReceivedNum
            item.scoreTotal = scoreTotalNum
            item.weight = weightNum
            item.category = category
            
            viewModel.updateGradeItem(item, in: courseId)
        } else {
            let item = GradeItem(
                name: name,
                scoreReceived: scoreReceivedNum,
                scoreTotal: scoreTotalNum,
                weight: weightNum,
                category: category
            )
            
            viewModel.addGradeItem(item, to: courseId)
        }
        
        dismiss()
    }
}

#Preview {
    AddGradeItemView(viewModel: GradeCalViewModel(), courseId: UUID())
}
