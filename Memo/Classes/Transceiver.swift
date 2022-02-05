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

public protocol TransceiverObserver: AnyObject {

    func transceiver(_ transceiver: Transceiver, didReceivePayload payload: Data)

    /// This method will be called on a background thread.
    func transceiverDidUpdateConnection(_ transceiver: Transceiver)

    /// This method will be called on a background thread.
    func transceiverDidLoseConnection(_ transceiver: Transceiver)

}

public final class Transceiver {

    // MARK: - Life Cycle

    internal init(
        name: String,
        deviceToken: UUID
    ) {
        self.name = name
        self.deviceToken = deviceToken
    }

    // MARK: - Public Properties

    public let name: String

    public let deviceToken: UUID

    public var hasActiveConnection: Bool {
        return multipeerTransceiver?.hasActiveConnection ?? false
    }

    // MARK: - Public Methods

    public func addObserver(_ observer: TransceiverObserver) {
        observers.add(observer)
    }

    public func removeObserver(_ observer: TransceiverObserver) {
        observers.remove(observer)
    }

    public func send(payload: Data) throws {
        guard let activeTransceiver = multipeerTransceiver, activeTransceiver.hasActiveConnection else {
            throw MemoTransceiverError.noActiveTransceiver
        }

        try activeTransceiver.send(payload: payload)
    }

    // MARK: - Internal Properties

    internal var multipeerTransceiver: MultipeerTransceiver? = nil {
        didSet {
            multipeerTransceiver?.delegate = self
        }
    }

    // MARK: - Private Properties

    private var observers: NSHashTable<AnyObject> = .weakObjects()

    // MARK: - Private Methods

    private func notifyObservers(_ block: (TransceiverObserver) -> Void) {
        observers.allObjects.forEach { observer in
            block(observer as! TransceiverObserver)
        }
    }

}

public enum MemoTransceiverError: Error {

    case noActiveTransceiver

}

extension Transceiver: MultipeerTransceiverDelegate {

    func multipeerTransceiverDidReceivePayload(_ payload: Data) {
        notifyObservers { $0.transceiver(self, didReceivePayload: payload) }
    }

    func multipeerTransceiverDidUpdateConnectionState(_ transceiver: MultipeerTransceiver) {
        if transceiver.hasActiveConnection {
            notifyObservers { $0.transceiverDidUpdateConnection(self) }
        } else if self.hasActiveConnection {
            // No-op. We have another active connection, so we aren't losing the connection.
        } else {
            notifyObservers { $0.transceiverDidLoseConnection(self) }
        }
    }

}
