//
//  MainScreen.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 2/24/26.
//

import SwiftUI

struct MainScreen: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                NavigationLink {
                    
                } label: {
                    Text("Central")
                        .padding(12)
                        .foregroundStyle(Color.systemBackground)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                        )
                }
                
                NavigationLink {
                    
                } label: {
                    Text("Peripheral")
                        .padding(12)
                        .foregroundStyle(Color.systemBackground)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(Color.orange)
                        )
                }

            }
        }
    }
}

#Preview {
    MainScreen()
}
