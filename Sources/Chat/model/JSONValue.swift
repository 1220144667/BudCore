//
//  JSONValue.swift
//
//  Copyright © 2019-2022 BudChat LLC. All rights reserved.
//

import Foundation

// Needed for encoding/decoding arrays and dictionaries of objects in JSON.
// Inspired by https://medium.com/grand-parade/parsing-fields-in-codable-structs-that-can-be-of-any-json-type-e0283d5edb
public enum JSONValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case int64(Int64)
    case double(Double)
    case bool(Bool)
    case dict([String: JSONValue])
    case array([JSONValue])
    case bytes(Data)
    case null

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .bool(v):
            try container.encode(v)
        case let .int(v):
            try container.encode(v)
        case let .int64(v):
            try container.encode(v)
        case let .string(v):
            try container.encode(v)
        case let .double(v):
            try container.encode(v)
        case let .dict(v):
            try container.encode(v)
        case let .array(v):
            try container.encode(v)
        case let .bytes(v):
            try container.encode(v)
        case .null:
            try container.encodeNil()
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .int64(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .dict(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode(Data.self) {
            self = .bytes(value)
        } else if let isNull = try? container.decodeNil(), isNull {
            self = .null
        } else {
            throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Not a JSON"))
        }
    }

    // MARK: Convenience accessors.

    public func asString() -> String? {
        if case let .string(v) = self {
            return v
        }
        return nil
    }

    public func asInt() -> Int? {
        if case let .int(v) = self {
            return v
        }
        return nil
    }

    public func asInt64() -> Int64? {
        switch self {
        case let .int(val):
            return Int64(val)
        case let .int64(val):
            return val
        default:
            return nil
        }
    }

    public func asData() -> Data? {
        switch self {
        case let .bytes(val):
            return val
        case let .string(val):
            return Data(base64Encoded: val)
        default:
            return nil
        }
    }

    public func asBool() -> Bool? {
        if case let .bool(v) = self {
            return v
        }
        return nil
    }

    public func asArray() -> [JSONValue]? {
        if case let .array(v) = self {
            return v
        }
        return nil
    }

    public func asDict() -> [String: JSONValue]? {
        if case let .dict(v) = self {
            return v
        }
        return nil
    }
}
