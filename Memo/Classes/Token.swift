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

public protocol TokenIdentifiable {

    static var tokenPrefix: String { get }

}

public enum TokenError: Swift.Error {

    case incorrectPrefix(token: String, expectedPrefix: String)

    case invalidToken

}

public struct Token<IdentifiedType: TokenIdentifiable> {

    // MARK: - Life Cycle

    public init() {
        self.uuid = UUID()
    }

    fileprivate init(_ rawValue: String) throws {
        guard rawValue.hasPrefix(IdentifiedType.tokenPrefix + "-") else {
            throw TokenError.incorrectPrefix(token: rawValue, expectedPrefix: IdentifiedType.tokenPrefix)
        }

        guard let parsedUUID = UUID(uuidString: String(rawValue.dropFirst(IdentifiedType.tokenPrefix.count + 1))) else {
            throw TokenError.invalidToken
        }

        self.uuid = parsedUUID
    }

    // MARK: - Private Properties

    private let uuid: UUID

}

extension Token: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(IdentifiedType.tokenPrefix)
        hasher.combine(uuid)
    }

}

extension Token: Equatable {}

extension Token: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(IdentifiedType.tokenPrefix + "-" + uuid.uuidString)
    }

}

extension Token: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(container.decode(String.self))
    }

}

extension Token: CustomStringConvertible {

    public var description: String {
        return IdentifiedType.tokenPrefix + "-" + uuid.uuidString
    }

}
