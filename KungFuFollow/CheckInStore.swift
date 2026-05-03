import Combine
import Foundation

struct CheckIn: Identifiable, Codable, Hashable {
    let id: UUID
    let routineID: String
    let routineTitle: String
    let practicedAt: Date
    let minutes: Int

    init(routineID: String, routineTitle: String, practicedAt: Date = .now, minutes: Int) {
        self.id = UUID()
        self.routineID = routineID
        self.routineTitle = routineTitle
        self.practicedAt = practicedAt
        self.minutes = minutes
    }
}

@MainActor
final class CheckInStore: ObservableObject {
    @Published private(set) var routines: [KungFuRoutine] = KungFuRoutine.samples
    @Published private(set) var checkIns: [CheckIn] = [] {
        didSet { save() }
    }
    @Published private(set) var syncMessage: String?

    private let storageKey = "kungfu.checkins.v1"
    private let apiClient = APIClient()

    init() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([CheckIn].self, from: data)
        else { return }

        checkIns = decoded.sorted { $0.practicedAt > $1.practicedAt }
    }

    func refresh() async {
        do {
            async let remoteRoutines = apiClient.fetchRoutines()
            async let remoteCheckIns = apiClient.fetchCheckIns()
            let fetchedRoutines = try await remoteRoutines
            let fetchedCheckIns = try await remoteCheckIns
            routines = fetchedRoutines
            checkIns = fetchedCheckIns.sorted { $0.practicedAt > $1.practicedAt }
            syncMessage = nil
        } catch {
            routines = KungFuRoutine.samples
            syncMessage = "后端暂不可用，当前展示本地示例数据。"
        }
    }

    var streakDays: Int {
        let calendar = Calendar.current
        let days = Set(checkIns.map { calendar.startOfDay(for: $0.practicedAt) })
        var cursor = calendar.startOfDay(for: .now)
        var streak = 0

        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return streak
    }

    func hasCheckedInToday(for routine: KungFuRoutine) -> Bool {
        let calendar = Calendar.current
        return checkIns.contains {
            $0.routineID == routine.id && calendar.isDateInToday($0.practicedAt)
        }
    }

    func complete(_ routine: KungFuRoutine) async {
        guard !hasCheckedInToday(for: routine) else { return }

        do {
            let remoteCheckIn = try await apiClient.createCheckIn(for: routine)
            checkIns.insert(remoteCheckIn, at: 0)
            syncMessage = nil
        } catch {
            let checkIn = CheckIn(routineID: routine.id, routineTitle: routine.title, minutes: routine.duration)
            checkIns.insert(checkIn, at: 0)
            syncMessage = "后端暂不可用，本次打卡已先保存在本机。"
        }
    }

    func addLocal(_ routine: KungFuRoutine) {
        guard !hasCheckedInToday(for: routine) else { return }
        let checkIn = CheckIn(routineID: routine.id, routineTitle: routine.title, minutes: routine.duration)
        checkIns.insert(checkIn, at: 0)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(checkIns) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
