import AVKit
import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var checkIns: CheckInStore
    let routine: KungFuRoutine

    @State private var elapsed = 0
    @State private var isPracticing = false
    @State private var showCompletion = false
    @State private var player: AVPlayer

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(routine: KungFuRoutine) {
        self.routine = routine
        _player = State(initialValue: AVPlayer(url: routine.videoURL))
    }

    private var totalSeconds: Int {
        max(routine.moves.reduce(0) { $0 + $1.seconds }, 1)
    }

    private var progress: Double {
        min(Double(elapsed) / Double(totalSeconds), 1)
    }

    private var currentMove: MoveCue {
        var cursor = 0
        for move in routine.moves {
            cursor += move.seconds
            if elapsed < cursor {
                return move
            }
        }
        return routine.moves.last ?? MoveCue(name: "收势", seconds: 1, tip: "调整呼吸")
    }

    private var shareText: String {
        "我刚完成了「\(routine.title)」\(routine.duration) 分钟功夫跟练，今日打卡完成。"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VideoPlayer(player: player)
                    .aspectRatio(9.0 / 16.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .topLeading) {
                        Text(routine.style)
                            .font(.caption.bold())
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(.black.opacity(0.62), in: Capsule())
                            .foregroundStyle(.white)
                            .padding(12)
                    }

                VStack(alignment: .leading, spacing: 12) {
                    Text(routine.title)
                        .font(.title2.bold())

                    Text(routine.coachNote)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ProgressView(value: progress)
                        .tint(routine.tint)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentMove.name)
                                .font(.headline)
                            Text(currentMove.tip)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(timeText)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .monospacedDigit()
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                }

                HStack(spacing: 12) {
                    Button {
                        isPracticing.toggle()
                        if isPracticing {
                            player.play()
                        } else {
                            player.pause()
                        }
                    } label: {
                        Label(isPracticing ? "暂停" : "开始跟练", systemImage: isPracticing ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(routine.tint)

                    Button {
                        finishPractice()
                    } label: {
                        Label("完成", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                MoveList(routine: routine, elapsed: elapsed)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("跟练")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .onReceive(timer) { _ in
            guard isPracticing else { return }
            if elapsed < totalSeconds {
                elapsed += 1
            } else {
                finishPractice()
            }
        }
        .sheet(isPresented: $showCompletion) {
            CompletionSheet(routine: routine, shareText: shareText)
                .presentationDetents([.medium])
        }
    }

    private var timeText: String {
        let remaining = max(totalSeconds - elapsed, 0)
        return "\(remaining / 60):\(String(format: "%02d", remaining % 60))"
    }

    private func finishPractice() {
        isPracticing = false
        player.pause()
        elapsed = totalSeconds
        checkIns.add(routine)
        showCompletion = true
    }
}

private struct MoveList: View {
    let routine: KungFuRoutine
    let elapsed: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("动作拆解")
                .font(.headline)

            ForEach(Array(routine.moves.enumerated()), id: \.element.id) { index, move in
                let start = routine.moves.prefix(index).reduce(0) { $0 + $1.seconds }
                let isActive = elapsed >= start && elapsed < start + move.seconds

                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.footnote.bold())
                        .frame(width: 28, height: 28)
                        .background(isActive ? routine.tint : Color(.tertiarySystemGroupedBackground), in: Circle())
                        .foregroundStyle(isActive ? .white : .secondary)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(move.name)
                            .font(.subheadline.bold())
                        Text(move.tip)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(move.seconds)秒")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

private struct CompletionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let routine: KungFuRoutine
    let shareText: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 58))
                .foregroundStyle(.green)

            VStack(spacing: 6) {
                Text("今日功课完成")
                    .font(.title2.bold())
                Text("你完成了「\(routine.title)」\(routine.duration) 分钟跟练。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            ShareLink(item: shareText) {
                Label("分享打卡", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(routine.tint)

            Button("继续练") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
    }
}

#Preview {
    NavigationStack {
        PracticeView(routine: KungFuRoutine.samples[0])
            .environmentObject(CheckInStore())
    }
}
