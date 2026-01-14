import SwiftUI

struct DiningHomeView: View {
    @State private var selectedHall: String? = nil
    
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    private let diningHalls: [DiningHallInfo] = [
        DiningHallInfo(
            name: "J2 Dining",
            breakfast: "7:00am - 10:00am",
            lunch: "11:00am - 2:00pm",
            dinner: "4:30pm - 9:00pm",
            color: .orange
        ),
        DiningHallInfo(
            name: "Kins Dining",
            breakfast: "7:00am - 10:00am",
            lunch: "11:00am - 2:00pm",
            dinner: "4:30pm - 9:00pm",
            color: .green
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // 🎓 헤더
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good Afternoon ☀️")
                        .font(.largeTitle.bold())
                    Text("Today is \(todayString)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // 🕓 운영 시간 카드 리스트
                VStack(spacing: 16) {
                    ForEach(diningHalls) { hall in
                        DiningInfoCard(hall: hall) {
                            selectedHall = hall.name
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
        .navigationDestination(item: $selectedHall) { hallName in
            let hallKey = mapHallNameToFirestoreKey(hallName)
            DiningMenuView(hall: hallKey)
        }
        .navigationTitle("UT Dining")
        .navigationBarTitleDisplayMode(.inline)
        
    }
}


// MARK: - Dining Hall Info Model
struct DiningHallInfo: Identifiable {
    let id = UUID()
    let name: String
    let breakfast: String
    let lunch: String
    let dinner: String
    let color: Color
}

// MARK: - Reusable Info Card
struct DiningInfoCard: View {
    let hall: DiningHallInfo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(hall.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Circle()
                        .fill(hall.color)
                        .frame(width: 10, height: 10)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("☕️ Breakfast:")
                        Spacer()
                        Text(hall.breakfast)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("🥗 Lunch:")
                        Spacer()
                        Text(hall.lunch)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("🍝 Dinner:")
                        Spacer()
                        Text(hall.dinner)
                            .foregroundColor(.gray)
                    }
                }
                .font(.caption)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Firestore 문서 이름 매핑 함수
func mapHallNameToFirestoreKey(_ name: String) -> String {
    switch name {
    case "J2 Dining":
        return "J2_JCL"
    case "Kins Dining":
        return "Kins"
    default:
        return name.replacingOccurrences(of: " ", with: "_")
    }
}
