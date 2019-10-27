import Foundation
import SwiftUI


struct OptionsView: View {
    var units: [String] = ["minutes", "hours"]
    
    @Binding var dismissFlag: Bool
    var frequenciesInHours: [Int]
    @State private var notificationDurations: [String] = ["3", "12", "24"]
    @State private var notificationUnits: [String] = ["hours", "hours", "hours"]

    @State var selection1: Int = 1
    
    func saveNotificationFrequency() {
        // ...
    }
    
    func handleAppear() {
        print("Appearing with:", frequenciesInHours)
        for (index, hours) in self.frequenciesInHours.enumerated() {
            self.notificationDurations[index] = String(hours)
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
                            Text("\($0)").tag("\($0)")
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
