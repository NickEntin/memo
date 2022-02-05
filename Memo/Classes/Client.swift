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

import Foundation

public protocol ClientDelegate: AnyObject {

    func clientDidUpdateAvailableTransceivers(client: Client)

    func client(_ client: Client, didEncounterError error: Error)

}

public final class Client {

    // MARK: - Life Cycle

    public init(name: String = deviceName(), deviceToken: UUID = .init(), config: Config) {
        self.multipeerClient = MultipeerClient(
            deviceToken: deviceToken,
            clientName: name,
            bonjourServiceName: config.bonjourServiceName
        )

        multipeerClient.delegate = self
    }

    // MARK: - Public Properties

    public weak var delegate: ClientDelegate?

    public var availableTransceivers: [Transceiver] {
        return transceiversByDeviceToken.values.filter { $0.hasActiveConnection }
    }

    // MARK: - Public Methods

    public func startSearchingForConnections() {
        multipeerClient.start()
    }

    public func stopSearchingForConnections() {
        multipeerClient.stop()
    }

    // MARK: - Public Static Methods

    #if os(iOS)
    public static func deviceName() -> String {
        return UIDevice.current.name
    }
    #endif

    #if os(macOS)
    public static func deviceName() -> String {
        return Host.current().localizedName ?? "Unknown Client"
    }
    #endif

    // MARK: - Private Properties

    private let multipeerClient: MultipeerClient

    private var transceiversByDeviceToken: [UUID: Transceiver] = [:]

}

extension Client: MultipeerClientDelegate {

    func multipeerClient(
        _ client: MultipeerClient,
        didConnectTransceiver multipeerTransceiver: MultipeerTransceiver,
        forServer serverToken: UUID,
        named serverName: String
    ) {
        let transceiver: Transceiver
        if let existingTransceiver = transceiversByDeviceToken[serverToken] {
            transceiver = existingTransceiver
        } else {
            transceiver = Transceiver(name: serverName, deviceToken: serverToken)
            transceiver.addObserver(self)
            transceiversByDeviceToken[serverToken] = transceiver
        }

        transceiver.multipeerTransceiver = multipeerTransceiver

        delegate?.clientDidUpdateAvailableTransceivers(client: self)
    }

    func multipeerClient(
        _ client: MultipeerClient,
        didEncounterError error: Error
    ) {
        delegate?.client(self, didEncounterError: error)
    }

}

extension Client: TransceiverObserver {

    public func transceiverDidUpdateConnection(_ transceiver: Transceiver) {
        delegate?.clientDidUpdateAvailableTransceivers(client: self)
    }

    public func transceiverDidLoseConnection(_ transceiver: Transceiver) {
        delegate?.clientDidUpdateAvailableTransceivers(client: self)
    }

    public func transceiver(_ transceiver: Transceiver, didReceivePayload payload: Data) {
        // No-op.
    }

}
