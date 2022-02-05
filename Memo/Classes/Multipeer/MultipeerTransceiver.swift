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

import MultipeerConnectivity

internal protocol MultipeerTransceiverDelegate: AnyObject {

    func multipeerTransceiverDidReceivePayload(_ payload: Data)

    func multipeerTransceiverDidUpdateConnectionState(_ transceiver: MultipeerTransceiver)

}

internal final class MultipeerTransceiver: NSObject {

    // MARK: - Life Cycle

    init(session: MCSession, remotePeerID: MCPeerID) {
        self.session = session
        self.remotePeerID = remotePeerID

        super.init()

        session.delegate = self
    }

    // MARK: - Public Methods

    func send(payload: Data) throws {
        try session.send(payload, toPeers: [remotePeerID], with: .reliable)
    }

    // MARK: - Public Properties

    weak var delegate: MultipeerTransceiverDelegate?

    var hasActiveConnection: Bool {
        switch state {
        case .notConnected, .connecting:
            return false
        case .connected:
            return true
        @unknown default:
            fatalError("Unknown MPC session state")
        }
    }

    // MARK: - Private Properties

    private let session: MCSession

    private let remotePeerID: MCPeerID

    private var state: MCSessionState = .notConnected {
        didSet {
            switch (oldValue, state) {
            case (.connected, .connected):
                break // No-op. `hasActiveConnection` was and is true.

            case (.notConnected, .notConnected),
                 (.notConnected, .connecting),
                 (.connecting, .notConnected),
                 (.connecting, .connecting):
                break // No-op. `hasActiveConnection` was and is false.

            case (.notConnected, .connected),
                 (.connecting, .connected),
                 (.connected, .connecting),
                 (.connected, .notConnected):
                delegate?.multipeerTransceiverDidUpdateConnectionState(self)

            @unknown default:
                fatalError("Unknown MPC session state")
            }
        }
    }

}

extension MultipeerTransceiver: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        self.state = state
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        delegate?.multipeerTransceiverDidReceivePayload(data)
    }

    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        fatalError("Unexpectedly received stream")
    }

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        fatalError("Unexpectedly received resource")
    }

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {
        fatalError("Unexpectedly received resource")
    }

}
