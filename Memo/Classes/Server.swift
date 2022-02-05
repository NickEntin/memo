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

public protocol ServerDelegate: AnyObject {

    func server(_ server: Server, didReceiveIncomingConnection transceiver: Transceiver)

    func server(_ server: Server, didEncounterError error: Error)

}

public final class Server {

    // MARK: - Life Cycle

    public init(name: String = deviceName(), deviceToken: UUID = .init(), config: Config) {
        self.multipeerServer = MultipeerServer(
            deviceToken: deviceToken,
            serverName: name,
            bonjourServiceName: config.bonjourServiceName
        )

        multipeerServer.delegate = self
    }

    // MARK: - Public Properties

    public weak var delegate: ServerDelegate?

    // MARK: - Public Methods

    public func start() {
        multipeerServer.start()
    }

    public func stop() {
        multipeerServer.stop()
    }

    // MARK: - Public Static Methods

    #if os(iOS)
    public static func deviceName() -> String {
        return UIDevice.current.name
    }
    #endif

    #if os(macOS)
    public static func deviceName() -> String {
        return Host.current().localizedName ?? "Unknown Server"
    }
    #endif

    // MARK: - Private Properties

    private let multipeerServer: MultipeerServer

    private var transceiversByDeviceToken: [UUID: Transceiver] = [:]

}

extension Server: MultipeerServerDelegate {

    func multipeerServer(
        _ multipeerServer: MultipeerServer,
        didConnectTransceiver multipeerTransceiver: MultipeerTransceiver,
        forClient clientToken: UUID,
        named clientName: String
    ) {
        let transceiver: Transceiver
        if let existingTransceiver = transceiversByDeviceToken[clientToken] {
            transceiver = existingTransceiver
        } else {
            transceiver = Transceiver(name: clientName, deviceToken: clientToken)
            transceiversByDeviceToken[clientToken] = transceiver
        }

        transceiver.multipeerTransceiver = multipeerTransceiver

        delegate?.server(self, didReceiveIncomingConnection: transceiver)
    }

    func multipeerServer(
        _ multipeerServer: MultipeerServer,
        didEncounterError error: Error
    ) {
        delegate?.server(self, didEncounterError: error)
    }

}
