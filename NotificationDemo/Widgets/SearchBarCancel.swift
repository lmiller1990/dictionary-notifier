//
//  SearchBarCancel.swift
//  NotificationDemo
//
//  Created by Lachlan Miller on 11/10/19.
//  Copyright © 2019 Lachlan Miller. All rights reserved.
//

import Foundation
import SwiftUI


struct SearchBarCancel: View {
    
    @Binding var text: String
    var onSearch: () -> Void
    
    func closeKeyboard() {
        UIApplication.shared.endEditing()
    }
    
    var body: some View {
        HStack {
            SearchBar(text: $text, onSearch: onSearch)

            Button(action: { self.closeKeyboard() }) {
                Text("Close")
                    .foregroundColor(.black)
            }
        }
    }
}
