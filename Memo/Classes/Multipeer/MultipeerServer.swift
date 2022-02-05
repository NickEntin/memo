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

internal protocol MultipeerServerDelegate: AnyObject {

    func multipeerServer(
        _ multipeerServer: MultipeerServer,
        didConnectTransceiver transceiver: MultipeerTransceiver,
        forClient clientToken: UUID,
        named name: String
    )

    func multipeerServer(
        _ multipeerServer: MultipeerServer,
        didEncounterError error: Error
    )

}

internal final class MultipeerServer: NSObject {

    // MARK: - Life Cycle

    init(deviceToken: UUID, serverName: String, bonjourServiceName: String) {
        self.deviceToken = deviceToken
        self.serverName = serverName

        self.serverPeerID = MCPeerID(displayName: serverName)
        self.browser = MCNearbyServiceBrowser(peer: serverPeerID, serviceType: bonjourServiceName)

        super.init()

        browser.delegate = self
    }

    // MARK: - Internal Methods

    func start() {
        browser.startBrowsingForPeers()
    }

    func stop() {
        browser.stopBrowsingForPeers()
    }

    // MARK: - Internal Properties

    weak var delegate: MultipeerServerDelegate?

    // MARK: - Private Properties

    private let deviceToken: UUID

    private let serverName: String

    private let serverPeerID: MCPeerID

    private let browser: MCNearbyServiceBrowser

}

extension MultipeerServer: MCNearbyServiceBrowserDelegate {

    enum Error: Swift.Error {

        case incompleteDiscoveryInfo

        case invalidInvitationContext

    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer clientPeerID: MCPeerID,
        withDiscoveryInfo discoveryInfo: [String : String]?
    ) {
        guard let clientInfo = MultipeerDiscoveryInfo(discoveryInfo) else {
            delegate?.multipeerServer(self, didEncounterError: Error.incompleteDiscoveryInfo)
            return
        }

        guard Compatibility.canConnectToRemote(protocolVersion: clientInfo.memoProtocolVersion) else {
            return
        }

        let session = MCSession(peer: serverPeerID)

        let invitationContext = MultipeerInvitationContext(
            deviceToken: deviceToken,
            memoProtocolVersion: Compatibility.currentProtocolVersion
        )
        let encoder = JSONEncoder()

        let context: Data
        do {
            context = try encoder.encode(invitationContext)
        } catch {
            delegate?.multipeerServer(self, didEncounterError: Error.invalidInvitationContext)
            return
        }

        browser.invitePeer(clientPeerID, to: session, withContext: context, timeout: 30)

        let transceiver = MultipeerTransceiver(session: session, remotePeerID: clientPeerID)
        delegate?.multipeerServer(
            self,
            didConnectTransceiver: transceiver,
            forClient: clientInfo.deviceToken,
            named: clientPeerID.displayName
        )
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // TODO: Propogate this to delegate?
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Swift.Error) {
        delegate?.multipeerServer(self, didEncounterError: error)
    }

}
