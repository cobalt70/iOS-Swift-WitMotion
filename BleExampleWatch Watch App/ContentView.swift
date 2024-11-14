//
//  ContentView.swift
//  BleExampleWatch Watch App
//
//  Created by Giwoo Kim on 11/14/24.
//

import SwiftUI
import CoreBluetooth
import WitSDKWatch

struct ContentView: View {
    var appContext:AppContext = AppContext()
    
    var body: some View {
        ScrollView {
            
            
            VStack {
                ConnectView(appContext)
                
                HomeView(appContext)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
