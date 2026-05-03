import Foundation
import SwiftUI

struct KungFuRoutine: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let style: String
    let level: String
    let duration: Int
    let focus: String
    let coachNote: String
    let videoURL: URL
    let tintName: String
    let moves: [MoveCue]

    var tint: Color {
        switch tintName {
        case "orange":
            return .orange
        case "teal":
            return .teal
        default:
            return .red
        }
    }

    static func == (lhs: KungFuRoutine, rhs: KungFuRoutine) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct MoveCue: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let seconds: Int
    let tip: String
}

extension KungFuRoutine {
    static let samples: [KungFuRoutine] = [
        KungFuRoutine(
            id: "shaolin-foundation",
            title: "少林五步拳入门",
            style: "少林",
            level: "新手",
            duration: 8,
            focus: "步型、冲拳、收势",
            coachNote: "脚下先稳，拳路再快。每个动作结束时停半拍，确认重心在脚底。",
            videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4")!,
            tintName: "red",
            moves: [
                MoveCue(id: "ready", name: "抱拳预备", seconds: 30, tip: "肩放松，眼看正前方"),
                MoveCue(id: "bow-punch", name: "弓步冲拳", seconds: 45, tip: "前膝对脚尖，后腿蹬直"),
                MoveCue(id: "horse-block", name: "马步架打", seconds: 45, tip: "膝盖外开，腰背立住"),
                MoveCue(id: "rest-step", name: "歇步盖打", seconds: 40, tip: "下沉时不要塌腰"),
                MoveCue(id: "close", name: "收势调息", seconds: 20, tip: "吸气收拳，呼气落掌")
            ]
        ),
        KungFuRoutine(
            id: "wingchun-chain",
            title: "咏春日字冲拳",
            style: "咏春",
            level: "基础",
            duration: 6,
            focus: "中线、连击、节奏",
            coachNote: "肘沉住，拳沿中线走。速度可以慢，路线要准。",
            videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4")!,
            tintName: "orange",
            moves: [
                MoveCue(id: "stance", name: "二字钳羊马", seconds: 35, tip: "膝内扣，尾骨微收"),
                MoveCue(id: "tan-sau", name: "摊手定位", seconds: 30, tip: "手腕放平，肘不外飞"),
                MoveCue(id: "center-punch", name: "日字冲拳", seconds: 60, tip: "拳从胸前中线送出"),
                MoveCue(id: "chain-punch", name: "三拳连击", seconds: 50, tip: "后一拳贴着前一拳走"),
                MoveCue(id: "relax", name: "还原放松", seconds: 20, tip: "手臂轻抖，恢复呼吸")
            ]
        ),
        KungFuRoutine(
            id: "tai-chi-flow",
            title: "太极云手跟练",
            style: "太极",
            level: "舒缓",
            duration: 10,
            focus: "呼吸、转腰、重心",
            coachNote: "像推开一扇很重的门。手慢，腰带，脚跟稳。",
            videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4")!,
            tintName: "teal",
            moves: [
                MoveCue(id: "open", name: "开步起势", seconds: 40, tip: "膝微屈，呼吸拉长"),
                MoveCue(id: "left-cloud", name: "左云手", seconds: 55, tip: "腰先转，手随后"),
                MoveCue(id: "right-cloud", name: "右云手", seconds: 55, tip: "掌心保持柔和"),
                MoveCue(id: "shift", name: "重心转换", seconds: 45, tip: "脚掌贴地移动"),
                MoveCue(id: "close", name: "合太极", seconds: 25, tip: "气沉丹田，慢慢收回")
            ]
        )
    ]
}
