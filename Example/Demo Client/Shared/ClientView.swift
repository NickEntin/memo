//
//  Copyright 2022 Nick Entin
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Memo
import SwiftUI

struct ClientView: View {

    init() {
        client = Client()
    }

    @ObservedObject
    var client: Client

    var body: some View {
        VStack {
            ScrollView {
                // Without this `HStack` the spacer below will resolve to zero-width. Setting the `VStack`'s frame to a
                // max width of infinity doesn't seem to work here either.
                HStack {
                    VStack(alignment: .leading) {
                        ForEach(client.messages) { message in
                            Text(message.text)
                                .padding([.top, .bottom])
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }
            }
            .padding()
            // Without another modifier, the scroll view will cause the entire screen to scroll (including the other
            // scroll view). Adding a background color (anything other than `.clear` seems to work) will make it
            // scroll as expected.
            .background(Color.systemBackground)
            ScrollView {
                HStack {
                    VStack(alignment: .leading) {
                        ForEach(client.availableTransceivers) { transceiver in
                            NavigationLink(transceiver.transceiver.name) {
                                TransceiverView(memoTransceiver: transceiver.transceiver)
                                    .padding([.top, .bottom])
                            }
                        }
                    }
                    Spacer()
                }
            }
            .padding()
        }
    }

}

extension Color {

    #if os(iOS)
    static let systemBackground: Color = .init(uiColor: .systemBackground)
    #elseif os(macOS)
    static let systemBackground: Color = .init(NSColor.windowBackgroundColor)
    #endif

}

struct StatusMessage: Identifiable {

    var id: String

    var text: String

}

struct AvailableTransceiver: Identifiable {

    var id: String

    var transceiver: Memo.Transceiver

}

final class Client: ObservableObject {

    init() {
        memoClient = Memo.Client(config: .memoDemo)
        memoClient.delegate = self

        Task {
            memoClient.startSearchingForConnections()
            messages.append(StatusMessage(id: UUID().uuidString, text: "Searching for Connection"))
        }
    }

    deinit {
        memoClient.stopSearchingForConnections()
    }

    let memoClient: Memo.Client

    @Published
    private(set) var messages: [StatusMessage] = []

    @Published
    private(set) var availableTransceivers: [AvailableTransceiver] = []

}

extension Client: Memo.ClientDelegate {

    func clientDidUpdateAvailableTransceivers(client: Memo.Client) {
        DispatchQueue.main.async {
            self.availableTransceivers = client.availableTransceivers.map { transceiver in
                return AvailableTransceiver(id: transceiver.deviceToken.uuidString, transceiver: transceiver)
            }
        }
    }

    func client(_ client: Memo.Client, didEncounterError error: Swift.Error) {
        DispatchQueue.main.async {
            self.messages.append(StatusMessage(id: UUID().uuidString, text: "Error: \(error)"))
        }
    }

}

extension Config {

    static let memoDemo: Config = .init(
        bonjourServiceName: "memo"
    )

}
