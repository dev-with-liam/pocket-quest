import Foundation

struct Move: Identifiable, Equatable {
    let player: Player
    let index: Int

    var id: Int { index }
}
