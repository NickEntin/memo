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

internal struct MultipeerDiscoveryInfo {

    // MARK: - Life Cycle

    init(deviceToken: UUID, memoProtocolVersion: Int) {
        self.deviceToken = deviceToken
        self.memoProtocolVersion = memoProtocolVersion
    }

    // MARK: - Internal Properties

    var deviceToken: UUID

    var memoProtocolVersion: Int

    // MARK: - Private Types

    private enum Keys {

        static let deviceToken = "device_token"

        static let memoProtocolVersion = "memo_protocol_version"

    }

    // MARK: - Internal Methods

    init?(_ dictionary: [String: String]?) {
        guard let dictionary = dictionary else {
            return nil
        }

        guard
            let rawDeviceToken = dictionary[Keys.deviceToken],
            let deviceToken = UUID(uuidString: rawDeviceToken)
        else {
            return nil
        }
        self.deviceToken = deviceToken

        guard
            let rawMemoProtocolVersion = dictionary[Keys.memoProtocolVersion],
            let memoProtocolVersion = Int(rawMemoProtocolVersion)
        else {
            return nil
        }
        self.memoProtocolVersion = memoProtocolVersion
    }

    func toDictionary() -> [String: String] {
        return [
            Keys.deviceToken: deviceToken.uuidString,
            Keys.memoProtocolVersion: "\(memoProtocolVersion)"
        ]
    }

}

