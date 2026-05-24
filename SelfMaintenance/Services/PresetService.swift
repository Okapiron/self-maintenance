import Foundation

struct MaintenancePreset: Identifiable, Hashable {
    let id: String
    let name: String
    let carePart: CarePart
    let intervalValue: Int
    let intervalUnit: IntervalUnit
}

enum PresetService {
    static let presets: [MaintenancePreset] = [
        .init(id: "hair_salon", name: "美容院", carePart: .hair, intervalValue: 6, intervalUnit: .week),
        .init(id: "eyebrow_salon", name: "眉毛サロン", carePart: .eyeArea, intervalValue: 4, intervalUnit: .week),
        .init(id: "lash_lift", name: "まつパ", carePart: .eyeArea, intervalValue: 6, intervalUnit: .week),
        .init(id: "ophthalmology", name: "眼科", carePart: .eyes, intervalValue: 12, intervalUnit: .month),
        .init(id: "dentist", name: "歯科", carePart: .teeth, intervalValue: 2, intervalUnit: .month),
        .init(id: "whitening", name: "ホワイトニング", carePart: .teeth, intervalValue: 4, intervalUnit: .month),
        .init(id: "nail", name: "ネイル", carePart: .hands, intervalValue: 4, intervalUnit: .week),
        .init(id: "cosmetic_dermatology", name: "美容皮膚科", carePart: .faceBody, intervalValue: 2, intervalUnit: .month),
        .init(id: "hair_removal", name: "脱毛", carePart: .faceBody, intervalValue: 2, intervalUnit: .month),
        .init(id: "esthetic", name: "エステ", carePart: .faceBody, intervalValue: 2, intervalUnit: .month),
        .init(id: "massage", name: "マッサージ", carePart: .body, intervalValue: 4, intervalUnit: .month),
        .init(id: "seitai", name: "整体", carePart: .body, intervalValue: 2, intervalUnit: .month),
        .init(id: "health_checkup", name: "健康診断", carePart: .body, intervalValue: 12, intervalUnit: .month)
    ]
}
