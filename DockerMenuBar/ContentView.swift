//
//  ContentView.swift
//  DockerMenuBar
//
//  Created by Mesut KURT on 14.09.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Docker MenuBar Uygulaması")
                .font(.title)
            Text("Bu uygulama menü çubuğunda çalışır.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
