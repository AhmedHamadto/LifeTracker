import WidgetKit
import SwiftUI

@main
struct LifeTrackerWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MedicationsWidget()
        WorkoutsWidget()
    }
}
