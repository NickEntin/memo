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

struct TransceiverView: View {

    init(memoTransceiver: Memo.Transceiver) {
        transceiver = Transceiver(memoTransceiver: memoTransceiver)
    }

    @ObservedObject
    var transceiver: Transceiver

    @State
    private var input: String = ""

    @FocusState
    private var inputFieldFocused: Bool

    var body: some View {
        VStack {
            HStack {
                ScrollView {
                    HStack {
                        VStack(alignment: .leading) {
                            ForEach(transceiver.messages) { message in
                                Text(message.text)
                                    .padding()
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                }
                .padding()
            }
            TextField("Message", text: $input)
                .submitLabel(.send)
                .focused($inputFieldFocused)
                .onSubmit {
                    let payload = input.data(using: .utf8)!
                    input = ""
                    Task {
                        do {
                            try transceiver.memoTransceiver.send(payload: payload)
                        } catch {
                            transceiver.logError(error)
                        }
                    }
                    inputFieldFocused = true
                }
                .padding()
        }
    }

}

struct Message: Identifiable {

    var id: String

    var text: String

}

final class Transceiver: ObservableObject {

    init(memoTransceiver: Memo.Transceiver) {
        self.memoTransceiver = memoTransceiver
        memoTransceiver.addObserver(self)
    }

    let memoTransceiver: Memo.Transceiver

    @Published
    private(set) var messages: [Message] = []

    func logError(_ error: Error) {
        DispatchQueue.main.async {
            self.messages.append(.init(id: UUID().uuidString, text: "Error: \(error)"))
        }
    }

}

extension Transceiver: Memo.TransceiverObserver {

    func transceiver(_ transceiver: Memo.Transceiver, didReceivePayload payload: Data) {
        let message = String(data: payload, encoding: .utf8)!

        DispatchQueue.main.async {
            self.messages.append(Message(id: UUID().uuidString, text: message))
        }
    }

    func transceiverDidUpdateConnection(_ transceiver: Memo.Transceiver) {
        DispatchQueue.main.async {
            self.messages.append(Message(id: UUID().uuidString, text: "-- Connection Status Updated --"))
        }
    }

    func transceiverDidLoseConnection(_ transceiver: Memo.Transceiver) {
        DispatchQueue.main.async {
            self.messages.append(Message(id: UUID().uuidString, text: "-- Lost Connection --"))
        }
    }

}
