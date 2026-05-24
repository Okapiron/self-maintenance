import Foundation
import SwiftData

@Model
final class MaintenanceLog {
    var id: UUID
    var performedAt: Date
    var amount: Int?
    var shopName: String
    var staffName: String
    var satisfaction: Int?
    var memo: String
    var createdAt: Date
    var updatedAt: Date
    var item: MaintenanceItem?

    init(
        id: UUID = UUID(),
        performedAt: Date,
        amount: Int? = nil,
        shopName: String = "",
        staffName: String = "",
        satisfaction: Int? = nil,
        memo: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        item: MaintenanceItem? = nil
    ) {
        self.id = id
        self.performedAt = performedAt
        self.amount = amount
        self.shopName = shopName
        self.staffName = staffName
        self.satisfaction = satisfaction
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.item = item
    }
}
