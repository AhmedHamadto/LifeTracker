import Foundation
import UserNotifications

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            isAuthorized = granted
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Medication Reminders

    func scheduleMedicationReminders(for medication: Medication) async {
        guard isAuthorized else {
            _ = await requestAuthorization()
            guard isAuthorized else { return }
        }

        // Cancel existing reminders for this medication
        await cancelMedicationReminders(for: medication.id)

        // Schedule new reminders for each time
        for (index, time) in medication.times.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Time for \(medication.name)"
            content.body = "Take \(medication.dosageDisplay)"
            if let instructions = medication.instructions {
                content.body += "\n\(instructions)"
            }
            content.sound = .default
            content.categoryIdentifier = "MEDICATION_REMINDER"
            content.userInfo = [
                "medicationId": medication.id.uuidString,
                "type": "medication"
            ]

            var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)

            // Set up repeating based on frequency
            switch medication.frequency {
            case .daily, .twiceDaily, .threeTimesDaily, .fourTimesDaily:
                // Daily at this time
                break
            case .weekly:
                dateComponents.weekday = Calendar.current.component(.weekday, from: medication.startDate)
            case .biweekly:
                // For biweekly, we'll need custom handling
                break
            case .monthly:
                dateComponents.day = Calendar.current.component(.day, from: medication.startDate)
            case .asNeeded:
                // Don't schedule for as-needed medications
                return
            }

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(medication.id.uuidString)-\(index)",
                content: content,
                trigger: trigger
            )

            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelMedicationReminders(for medicationId: UUID) async {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()

        let identifiersToRemove = pendingRequests
            .filter { $0.identifier.hasPrefix(medicationId.uuidString) }
            .map { $0.identifier }

        center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
    }

    func scheduleRefillReminder(for medication: Medication) async {
        guard isAuthorized,
              let remaining = medication.remainingCount,
              let reminderDays = medication.refillReminderDays else { return }

        let dosesPerDay = max(1, medication.times.count)
        let daysRemaining = remaining / dosesPerDay

        guard daysRemaining <= reminderDays else { return }

        let content = UNMutableNotificationContent()
        content.title = "Refill Reminder"
        content.body = "\(medication.name) is running low. \(remaining) doses remaining."
        content.sound = .default
        content.categoryIdentifier = "REFILL_REMINDER"
        content.userInfo = [
            "medicationId": medication.id.uuidString,
            "type": "refill"
        ]

        // Schedule for tomorrow morning
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "refill-\(medication.id.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule refill notification: \(error)")
        }
    }

    // MARK: - Document Expiry Reminders

    func scheduleExpiryReminder(for document: Document) async {
        guard isAuthorized,
              let expiryDate = document.expiryDate else { return }

        // Cancel existing reminder
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["expiry-\(document.id.uuidString)"]
        )

        // Schedule reminder 30 days before expiry
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -30, to: expiryDate),
              reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Document Expiring Soon"
        content.body = "\(document.title) expires on \(expiryDate.formatted(date: .abbreviated, time: .omitted))"
        content.sound = .default
        content.userInfo = [
            "documentId": document.id.uuidString,
            "type": "expiry"
        ]

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "expiry-\(document.id.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule expiry notification: \(error)")
        }
    }

    // MARK: - Notification Categories

    func registerNotificationCategories() {
        let takenAction = UNNotificationAction(
            identifier: "TAKEN",
            title: "Mark as Taken",
            options: .foreground
        )

        let skipAction = UNNotificationAction(
            identifier: "SKIP",
            title: "Skip",
            options: .destructive
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze 15 min",
            options: []
        )

        let medicationCategory = UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [takenAction, skipAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let refillCategory = UNNotificationCategory(
            identifier: "REFILL_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            medicationCategory,
            refillCategory
        ])
    }
}
