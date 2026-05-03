import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var checkIns: CheckInStore
    private let routines = KungFuRoutine.samples

    var body: some View {
        TabView {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HeroHeader(streak: checkIns.streakDays)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("今日跟练")
                                .font(.title2.bold())

                            ForEach(routines) { routine in
                                NavigationLink(value: routine) {
                                    RoutineCard(
                                        routine: routine,
                                        checkedIn: checkIns.hasCheckedInToday(for: routine)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("功夫跟练")
                .navigationDestination(for: KungFuRoutine.self) { routine in
                    PracticeView(routine: routine)
                }
            }
            .tabItem {
                Label("练功", systemImage: "figure.martial.arts")
            }

            CheckInHistoryView()
                .tabItem {
                    Label("打卡", systemImage: "checkmark.seal")
                }
        }
    }
}

private struct HeroHeader: View {
    let streak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("稳住下盘")
                        .font(.largeTitle.weight(.black))
                    Text("跟着短视频练动作，完成后记录今日功课。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("\(streak)")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                    Text("连练")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 74, height: 74)
                .background(.white, in: RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 10) {
                MetricPill(title: "3 套", subtitle: "精选套路")
                MetricPill(title: "6-10 分钟", subtitle: "碎片练习")
                MetricPill(title: "可分享", subtitle: "打卡战绩")
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.red.opacity(0.18), Color.orange.opacity(0.12), Color.teal.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
    }
}

private struct MetricPill: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.footnote.bold())
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct RoutineCard: View {
    let routine: KungFuRoutine
    let checkedIn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [routine.tint.opacity(0.88), .black.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("\(routine.duration) 分钟")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(8)
            }
            .frame(width: 112, height: 148)

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(routine.style)
                        .font(.caption.bold())
                        .foregroundStyle(routine.tint)
                    Text(routine.level)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if checkedIn {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                }

                Text(routine.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(routine.focus)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "figure.martial.arts")
                    Text("\(routine.moves.count) 个动作")
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .padding(.leading, 2)
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 172, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct CheckInHistoryView: View {
    @EnvironmentObject private var checkIns: CheckInStore
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(checkIns.streakDays) 天")
                                .font(.largeTitle.bold())
                            Text("当前连续打卡")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "flame.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.orange)
                    }
                    .padding(.vertical, 10)
                }

                Section("最近记录") {
                    if checkIns.checkIns.isEmpty {
                        ContentUnavailableView("还没有打卡", systemImage: "figure.martial.arts", description: Text("完成一次跟练后，这里会记录你的练功日。"))
                    } else {
                        ForEach(checkIns.checkIns) { checkIn in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(checkIn.routineTitle)
                                        .font(.headline)
                                    Text(dateFormatter.string(from: checkIn.practicedAt))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(checkIn.minutes) 分钟")
                                    .font(.footnote.bold())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("打卡")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CheckInStore())
}
