//
//  CalendarViewController.swift
//  미국 에타
//
//  Created by Isaac Choi on 9/11/25.
//

import UIKit
import SwiftUI
import CalendarKit
<<<<<<< HEAD
=======
import FirebaseFirestore
import FirebaseAuth

>>>>>>> 755c2ac (Save my local work)

class CalendarViewController: UIViewController {
    // MARK: - State
    var customEvents: [EventModel] = [] {
        didSet { saveEvents() }
    }

    private let dayVC = DayViewController() // CalendarKit Day View
    private let container = UIView()

    private var currentTab: CalendarTab = .day
    private var selectedDate: Date = Date()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        view.backgroundColor = .systemBackground
        title = "Calendar"

        // Load saved events
        loadEvents()

        setupNavBar()
        setupContainer()
        showDayView() // default mode = Day
    }

    // MARK: - NavBar
    private func setupNavBar() {
        // + button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )

        // Segmented control (Day / Week / Month)
        let segmented = UISegmentedControl(items: ["Day", "Week", "Month"])
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        navigationItem.titleView = segmented
    }
    
    private func scheduleNotification(for event: EventModel) {
        guard let minutes = event.reminderMinutesBefore else { return }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = "\(event.title) starts soon" + (event.location != nil ? " at \(event.location!)" : "")
        content.sound = .default

        // 알림 시간 = 시작 시간 - minutes
        let triggerDate = event.startDate.addingTimeInterval(TimeInterval(-minutes * 60))
        if triggerDate < Date() { return } // 이미 지난 경우 무시

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: triggerDate.timeIntervalSinceNow,
            repeats: false
        )

        let request = UNNotificationRequest(identifier: event.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }

    // MARK: - Container setup
    private func setupContainer() {
        view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func modeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            // Always reset to today when coming back to Day tab
            selectedDate = Date()
            currentTab = .day
            showDayView()

        case 1:
            currentTab = .week
            showSwiftUIView(WeekGridView(events: customEvents))

        case 2:
            currentTab = .month
            showSwiftUIView(MonthGridView(events: customEvents))

        default:
            break
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Day 모드일 때도 selectedDate는 유지 (오늘로 리셋하지 않음)
        if currentTab == .day {
            if let state = dayVC.dayView.state {
                state.move(to: selectedDate)
            } else {
                dayVC.dayView.state = DayViewState(date: selectedDate)
            }
            dayVC.dayView.reloadData()
        }
    }

    
    private func showSwiftUIView<Content: View>(_ swiftUIView: Content) {
        // Remove existing child
        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        // Special case: MonthGridView with callback
        if let monthView = swiftUIView as? MonthGridView {
            let hosting = UIHostingController(
                rootView: MonthGridView(
                    events: customEvents,
                    onSelectDate: { date in
                        self.selectedDate = date
                        self.currentTab = .day

                        // Switch segmented control back to Day
                        if let seg = self.navigationItem.titleView as? UISegmentedControl {
                            seg.selectedSegmentIndex = 0
                        }
                        self.showDayView()
                    }
                )
            )
            addChild(hosting)
            container.addSubview(hosting.view)
            hosting.view.frame = container.bounds
            hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hosting.didMove(toParent: self)
            return
        }

        // Generic SwiftUI embedding
        let hosting = UIHostingController(rootView: swiftUIView)
        addChild(hosting)
        container.addSubview(hosting.view)
        hosting.view.frame = container.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hosting.didMove(toParent: self)
    }

    private func showDayView() {
        // Remove old child controllers
        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        dayVC.dayView.autoScrollToFirstEvent = false

        // ❌ don't reset to today
        // selectedDate = Date()

        if let state = dayVC.dayView.state {
            state.move(to: selectedDate)
        } else {
            dayVC.dayView.state = DayViewState(date: selectedDate)
        }

        dayVC.dayView.reloadData()

        addChild(dayVC)
        container.addSubview(dayVC.view)
        dayVC.view.frame = container.bounds
        dayVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dayVC.didMove(toParent: self)

        dayVC.delegate = self
        dayVC.dataSource = self

        DispatchQueue.main.async {
            self.dayVC.dayView.state?.move(to: self.selectedDate)
        }
    }


    
    // MARK: - Add Event
    @objc private func addTapped() {
        let now = Date()
        let comps = Calendar.current.dateComponents([.hour, .minute], from: now)

        // 📌 선택한 날짜(selectedDate)에 현재 시각(hour/minute) 반영
        let defaultStart = Calendar.current.date(
            bySettingHour: comps.hour ?? 9,
            minute: comps.minute ?? 0,
            second: 0,
            of: selectedDate
        ) ?? selectedDate

        let defaultEnd = Calendar.current.date(byAdding: .hour, value: 1, to: defaultStart) ?? defaultStart

        let addView = AddEventView(
            startDate: defaultStart,
            endDate: defaultEnd
        ) { newEvent in
            self.customEvents.append(newEvent)
            self.saveEvents()
            self.scheduleNotification(for: newEvent)
            self.dayVC.dayView.reloadData()
        }

        let hosting = UIHostingController(rootView: addView)
        hosting.modalPresentationStyle = .formSheet
        present(hosting, animated: true)
    }

    // MARK: - Persistence
    private func saveEvents() {
        if let data = try? JSONEncoder().encode(customEvents) {
            UserDefaults.standard.set(data, forKey: "savedEvents")
        }
    }

    private func loadEvents() {
<<<<<<< HEAD
        if let data = UserDefaults.standard.data(forKey: "savedEvents"),
           let decoded = try? JSONDecoder().decode([EventModel].self, from: data) {
            customEvents = decoded
        }
=======
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Load own events
        db.collection("users").document(uid).collection("events")
            .addSnapshotListener { snapshot, error in
                if let docs = snapshot?.documents {
                    let decoded = docs.compactMap { try? $0.data(as: EventModel.self) }
                    self.customEvents = decoded
                }
            }
        
        // Load accepted shared events (linked)
        db.collection("shares")
            .whereField("toUser", isEqualTo: uid)
            .whereField("status", isEqualTo: "accepted")
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                
                for doc in docs {
                    let data = doc.data()
                    let fromUser = data["fromUser"] as? String ?? ""
                    let eventId = data["eventId"] as? String ?? ""
                    
                    db.collection("users").document(fromUser)
                      .collection("events").document(eventId)
                      .addSnapshotListener { eventSnap, error in
                          if let eventData = try? eventSnap?.data(as: EventModel.self) {
                              if !self.customEvents.contains(where: { $0.id == eventData.id }) {
                                  self.customEvents.append(eventData)
                              } else {
                                  if let idx = self.customEvents.firstIndex(where: { $0.id == eventData.id }) {
                                      self.customEvents[idx] = eventData
                                  }
                              }
                          }
                      }
                }
            }
>>>>>>> 755c2ac (Save my local work)
    }
}

// MARK: - EventDataSource
extension CalendarViewController: EventDataSource {
    func eventsForDate(_ date: Date) -> [EventDescriptor] {
        var events: [Event] = []
        let calendar = Calendar.current
        let eventDay = calendar.startOfDay(for: date)

        for model in customEvents {
            // Skip if excluded
            if model.excludedDates.contains(eventDay) { continue }

            let weekday = calendar.component(.weekday, from: eventDay)
            let startDay = calendar.startOfDay(for: model.startDate)
            let endDay = model.repeatEndDate.map { calendar.startOfDay(for: $0) }

            let isSingle = calendar.isDate(model.startDate, inSameDayAs: eventDay)
                && model.repeatDays.isEmpty
                && (endDay == nil || eventDay <= endDay!)

            let isRepeating = model.repeatDays.contains(weekday)
                && eventDay >= startDay
                && (endDay == nil || eventDay <= endDay!)

            if isSingle || isRepeating {
                let event = Event()
                event.text = model.title + (model.location != nil ? " @ \(model.location!)" : "")
                // shift time of day to match this date
                let startTime = calendar.dateComponents([.hour, .minute], from: model.startDate)
                let endTime   = calendar.dateComponents([.hour, .minute], from: model.endDate)
                let newStart  = calendar.date(bySettingHour: startTime.hour ?? 0,
                                              minute: startTime.minute ?? 0,
                                              second: 0,
                                              of: eventDay)!
                let newEnd    = calendar.date(bySettingHour: endTime.hour ?? 0,
                                              minute: endTime.minute ?? 0,
                                              second: 0,
                                              of: eventDay)!

                event.dateInterval = DateInterval(start: newStart, end: newEnd)
                event.color = model.color
                event.userInfo = model.id
                events.append(event)
            }
        }

        return events
    }
}


// MARK: - DayViewDelegate
extension CalendarViewController: DayViewDelegate {
    func dayViewDidSelectEventView(_ eventView: EventView) {
        guard let event = eventView.descriptor as? Event,
              let eventID = event.userInfo as? UUID,
              let model = customEvents.first(where: { $0.id == eventID }) else { return }

        let alert = UIAlertController(
            title: event.text,
            message: nil,
            preferredStyle: .actionSheet
        )

        // 📝 Edit 버튼
        alert.addAction(UIAlertAction(title: "Edit", style: .default) { _ in
            let editView = AddEventView(
                title: model.title,
                location: model.location ?? "",
                startDate: model.startDate,
                endDate: model.endDate,
                color: Color(model.color),
                repeatDays: model.repeatDays,
                reminderMinutesBefore: model.reminderMinutesBefore,
                repeatEndDate: model.repeatEndDate,
                onSave: { updated in
                    if let idx = self.customEvents.firstIndex(where: { $0.id == eventID }) {
                        self.customEvents[idx] = updated
                        self.saveEvents()
                        self.dayVC.dayView.reloadData()
                    }
                }
            )
            let hosting = UIHostingController(rootView: editView)
            hosting.modalPresentationStyle = .formSheet
            self.present(hosting, animated: true)
        })

        // ❌ Delete 버튼
<<<<<<< HEAD
        // ❌ Delete 버튼
=======
>>>>>>> 755c2ac (Save my local work)
        if !model.repeatDays.isEmpty {
            // 반복 이벤트 → ask choice
            alert.addAction(UIAlertAction(title: "Delete This Event Only", style: .destructive) { _ in
                if let idx = self.customEvents.firstIndex(where: { $0.id == eventID }) {
                    var updated = self.customEvents[idx]

                    // 👇 Add current day into excludedDates
                    let dayToDelete = Calendar.current.startOfDay(for: self.selectedDate)
                    updated.excludedDates.append(dayToDelete)

                    self.customEvents[idx] = updated
                    self.saveEvents()
                    self.dayVC.dayView.reloadData()
                }
            })

            alert.addAction(UIAlertAction(title: "Delete All Future Events", style: .destructive) { _ in
                if let idx = self.customEvents.firstIndex(where: { $0.id == eventID }) {
                    var updated = self.customEvents[idx]
                    updated.repeatEndDate = Calendar.current.date(byAdding: .day, value: -1, to: self.selectedDate)
                    self.customEvents[idx] = updated
                    self.saveEvents()
                    self.dayVC.dayView.reloadData()
                }
            })
        } else {
            // 단일 이벤트 → 그냥 삭제
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                self.customEvents.removeAll { $0.id == eventID }
                self.saveEvents()
                self.dayVC.dayView.reloadData()
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
<<<<<<< HEAD
=======
        
        // ✉️ Share 버튼
        alert.addAction(UIAlertAction(title: "Share this schedule", style: .default) { _ in
            self.promptShare(for: model)
        })

>>>>>>> 755c2ac (Save my local work)
    }



    func dayViewDidLongPressEventView(_ eventView: EventView) {
        // optional: maybe open edit view
    }

    func dayView(dayView: DayView, didTapTimelineAt date: Date) {
        print("Tapped timeline at \(date)")
    }

    func dayView(dayView: DayView, didLongPressTimelineAt date: Date) {
        print("Long pressed timeline at \(date)")
    }

    func dayViewDidBeginDragging(dayView: DayView) {
        print("Began dragging")
    }

    func dayViewDidTransitionCancel(dayView: DayView) {
        print("Transition cancelled")
    }

    func dayView(dayView: DayView, willMoveTo date: Date) {
        print("Will move to \(date)")
    }

    func dayView(dayView: DayView, didMoveTo date: Date) {
        selectedDate = date
        print("Did move to \(date)")
    }

    func dayView(dayView: DayView, didUpdate event: EventDescriptor) {
        print("Updated event: \(event.text ?? "")")
    }
    
<<<<<<< HEAD
=======
    private func promptShare(for event: EventModel) {
        let alert = UIAlertController(title: "Share Schedule",
                                      message: "Enter recipient's email:",
                                      preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "example@utexas.edu"
            textField.keyboardType = .emailAddress
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Send", style: .default) { _ in
            guard let email = alert.textFields?.first?.text, !email.isEmpty,
                  let user = Auth.auth().currentUser else { return }
            
            let db = Firestore.firestore()
            
            // 🔑 Lookup recipient UID by email
            db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                if let doc = snapshot?.documents.first {
                    let recipientUid = doc.documentID
                    
                    let shareData: [String: Any] = [
                        "fromUser": user.uid,
                        "toUser": recipientUid,
                        "eventId": event.id.uuidString,
                        "status": "pending",
                        "createdAt": Timestamp(date: Date())
                    ]
                    
                    db.collection("shares").addDocument(data: shareData) { error in
                        if let error = error {
                            print("Failed to share: \(error)")
                        } else {
                            print("Share request sent to \(email)")
                        }
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
>>>>>>> 755c2ac (Save my local work)
}
