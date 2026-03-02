//
//  PeripheralDetailScreen.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 3/1/26.
//

import SwiftUI

struct PeripheralDetailScreen: View {
    @FocusState private var notesIsFocused
    @State private var notes: String = ""
    let profile: PeripheralProfile

    var body: some View {
        List {
            Section("Name") {
                Text(profile.name)
                    .foregroundStyle(Color.secondary)
            }
            
            Section("RSSI") {
                Text(String(profile.rssi))
                    .foregroundStyle(Color.secondary)
            }
            
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(height: 200)
                    .focused($notesIsFocused)
            }
        }
        .navigationTitle("Peripheral")
        .onAppear {
            notesIsFocused = true
        }
    }
}

#Preview {
    NavigationStack {
        PeripheralDetailScreen(profile: PeripheralProfile.sample)
    }
}
