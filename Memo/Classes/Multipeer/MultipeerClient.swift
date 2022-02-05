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

internal protocol MultipeerClientDelegate: AnyObject {

    func multipeerClient(
        _ client: MultipeerClient,
        didConnectTransceiver transceiver: MultipeerTransceiver,
        forServer serverToken: UUID,
        named serverName: String
    )

    func multipeerClient(
        _ client: MultipeerClient,
        didEncounterError error: Error
    )

}

internal final class MultipeerClient: NSObject {

    // MARK: - Life Cycle

    init(deviceToken: UUID, clientName: String, bonjourServiceName: String) {
        self.deviceToken = deviceToken
        self.clientName = clientName

        let discoveryInfo = MultipeerDiscoveryInfo(
            deviceToken: deviceToken,
            memoProtocolVersion: Compatibility.currentProtocolVersion
        )

        self.clientPeerID = MCPeerID(displayName: clientName)
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: clientPeerID,
            discoveryInfo: discoveryInfo.toDictionary(),
            serviceType: bonjourServiceName
        )

        super.init()

        advertiser.delegate = self
    }

    // MARK: - Internal Properties

    weak var delegate: MultipeerClientDelegate?

    // MARK: - Private Properties

    private let deviceToken: UUID

    private let clientName: String

    private let clientPeerID: MCPeerID

    private let advertiser: MCNearbyServiceAdvertiser

    // MARK: - Internal Methods

    func start() {
        advertiser.startAdvertisingPeer()
    }

    func stop() {
        advertiser.stopAdvertisingPeer()
    }

}

extension MultipeerClient: MCNearbyServiceAdvertiserDelegate {

    enum Error: Swift.Error {

        case invalidInvitationContext

    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer serverPeerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        let decoder = JSONDecoder()
        guard
            let context = context,
            let invitationContext = try? decoder.decode(MultipeerInvitationContext.self, from: context)
        else {
            delegate?.multipeerClient(self, didEncounterError: Error.invalidInvitationContext)
            return
        }

        guard Compatibility.canConnectToRemote(protocolVersion: invitationContext.memoProtocolVersion) else {
            invitationHandler(false, nil)
            return
        }

        let session = MCSession(peer: clientPeerID)

        invitationHandler(true, session)

        let transceiver = MultipeerTransceiver(session: session, remotePeerID: serverPeerID)
        
        delegate?.multipeerClient(
            self,
            didConnectTransceiver: transceiver,
            forServer: invitationContext.deviceToken,
            named: serverPeerID.displayName
        )
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Swift.Error) {
        delegate?.multipeerClient(self, didEncounterError: error)
    }

}
