import Foundation
import SwiftUI


struct OptionsView: View {
    @Binding var dismissFlag: Bool
    var frequenciesInHours: [Int]
    var handleUpdate: (_ notificationIntervals: [NotificationInterval]) -> Void
    
    @State private var notificationDurations: [Int] = [3, 12, 24]
    @State private var notificationUnits: [String] = ["hours", "hours", "hours"]

    @State var selection1: Int = 1
    
    func saveNotificationFrequency() {
        let updatedNotificationIntervals: [NotificationInterval] = [0, 1, 2].map { index in
            if notificationUnits[index] == "days" {
                return NotificationInterval(
                    duration: notificationDurations[index] * 24,
                    unit: "hours"
                )
            }
            
            return NotificationInterval(
                duration: notificationDurations[index],
                unit: "hours"
            )
        }
       
        handleUpdate(updatedNotificationIntervals)
    }
    
    func handleAppear() {
        for (index, hours) in self.frequenciesInHours.enumerated() {
            if hours > 24 {
                self.notificationUnits[index] = String("days")
                self.notificationDurations[index] = hours / 24
            } else {
                self.notificationDurations[index] = hours
            }
        }
    }
    
    var body: some View {
        VStack {
            Text("Notification: \(self.selection1). When: \(self.notificationDurations[self.selection1]) \(self.notificationUnits[self.selection1])")
            Picker(selection: self.$selection1, label: Text("Notification")) {
                ForEach(1..<4) {
                    Text("\($0)").tag($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            GeometryReader { geometry in
            
                HStack(spacing: 0 as CGFloat) {
                    Picker(selection: self.$notificationDurations[self.selection1], label: Text("Duration")) {
                        ForEach(0..<25) {
                            Text("\($0)").tag($0)
                        }
                    }
                    .frame(maxWidth: (geometry.size.width / 2) as CGFloat)
                         .clipped()
                        .border(Color.red)
                    
                    Picker(selection: self.$notificationUnits[self.selection1], label: Text("Time")) {
                        ForEach(["hours", "days"], id: \.self) {
                            Text("\($0)")
                        }
                    }
                    .frame(maxWidth: (geometry.size.width / 2) as CGFloat)
                        .clipped()
                        .border(Color.blue)
                }
            }
            
            Button(action: self.saveNotificationFrequency) {
                Text("Save")
            }
        }
        .onAppear {
            self.handleAppear()
        }
    }
}
