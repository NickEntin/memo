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

struct ContentView: View {

    init() {
        server = Server()
    }

    @ObservedObject
    var server: Server

    var body: some View {
        ScrollView {
            HStack {
                VStack(alignment: .leading) {
                    ForEach(server.messages) { message in
                        if let deviceToken = message.clientToken {
                            Text(deviceToken)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .padding([.leading, .trailing, .top])
                            Text(message.text)
                                .padding([.leading, .trailing, .bottom])
                                .lineLimit(1)
                        } else {
                            Text(message.text)
                                .padding()
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding()
    }

}

struct Message: Identifiable {

    var id: String

    var clientToken: String?

    var text: String

}

final class Server: ObservableObject {

    init() {
        memoServer = Memo.Server(config: .memoDemo)
        memoServer.delegate = self

        Task {
            memoServer.start()
            messages.append(Message(id: UUID().uuidString, text: "-- Server Started --"))
        }
    }

    deinit {
        memoServer.stop()
    }

    let memoServer: Memo.Server

    @Published
    private(set) var messages: [Message] = []

}

extension Server: Memo.ServerDelegate {

    func server(_ server: Memo.Server, didReceiveIncomingConnection transceiver: Transceiver) {
        transceiver.addObserver(self)
    }

    func server(_ server: Memo.Server, didEncounterError error: Error) {
        messages.append(Message(id: UUID().uuidString, text: "Error: \(error.localizedDescription)"))
    }

}

extension Server: Memo.TransceiverObserver {

    func transceiver(_ transceiver: Transceiver, didReceivePayload payload: Data) {
        let message = String(data: payload, encoding: .utf8)!

        DispatchQueue.main.async {
            self.messages.append(Message(id: UUID().uuidString, clientToken: transceiver.deviceToken.uuidString, text: message))
        }

        Task {
            do {
                try transceiver.send(payload: "Message received!".data(using: .utf8)!)
            } catch let error {
                print("Failed to send message received: \(error)")
            }
        }
    }

    func transceiverDidUpdateConnection(_ transceiver: Transceiver) {
        DispatchQueue.main.async {
            self.messages.append(Message(id: UUID().uuidString, clientToken: nil, text: "-- Connection Status Updated --"))
        }
    }

    func transceiverDidLoseConnection(_ transceiver: Transceiver) {
        DispatchQueue.main.async {
            self.messages.append(Message(id: UUID().uuidString, clientToken: nil, text: "-- Lost Connection --"))
        }
    }

}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        ContentView()
    }

}

extension Config {

    static let memoDemo: Config = .init(
        bonjourServiceName: "memo"
    )

}
