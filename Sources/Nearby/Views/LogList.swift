//
//  LogList.swift
//  Nearby
//
//  Created by Ben Gottlieb on 3/29/25.
//

import SwiftUI

public struct LogList: View {
    var logs = NearbyLog.UI.instance
    
    public init() { }
    public var body: some View {
        let events = logs.events
        ScrollViewReader { reader in
            List {
                ForEach(events.indices, id: \.self) { idx in
                    Text(events[idx].text)
                        .foregroundStyle(Color.green)
                        .listRowBackground(Color.clear)
                        .id(idx)
                }
            }
            .onChange(of: events.count) {
                reader.scrollTo(events.count - 1, anchor: .bottom)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.black)
    }
}
