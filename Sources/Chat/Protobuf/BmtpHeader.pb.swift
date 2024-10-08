// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: BmtpHeader.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
private struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
    struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
    typealias Version = _2
}

enum BmtpPackType: SwiftProtobuf.Enum {
    typealias RawValue = Int
    case packTypeNone // = 0

    /// 心跳
    case packTypePing // = 1

    /// 登出
    case packTypeLogout // = 10

    /// 踢出
    case packTypeKickout // = 11

    /// 通知消息
    case packTypeNote // = 19

    /// 单聊消息
    case packTypeMsgChat // = 20

    /// 群聊消息
    case packTypeMsgGroupChat // = 21
    case UNRECOGNIZED(Int)

    init() {
        self = .packTypeNone
    }

    init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .packTypeNone
        case 1: self = .packTypePing
        case 10: self = .packTypeLogout
        case 11: self = .packTypeKickout
        case 19: self = .packTypeNote
        case 20: self = .packTypeMsgChat
        case 21: self = .packTypeMsgGroupChat
        default: self = .UNRECOGNIZED(rawValue)
        }
    }

    var rawValue: Int {
        switch self {
        case .packTypeNone: return 0
        case .packTypePing: return 1
        case .packTypeLogout: return 10
        case .packTypeKickout: return 11
        case .packTypeNote: return 19
        case .packTypeMsgChat: return 20
        case .packTypeMsgGroupChat: return 21
        case let .UNRECOGNIZED(i): return i
        }
    }
}

#if swift(>=4.2)

    extension BmtpPackType: CaseIterable {
        // The compiler won't synthesize support with the UNRECOGNIZED case.
        static let allCases: [BmtpPackType] = [
            .packTypeNone,
            .packTypePing,
            .packTypeLogout,
            .packTypeKickout,
            .packTypeNote,
            .packTypeMsgChat,
            .packTypeMsgGroupChat,
        ]
    }

#endif // swift(>=4.2)

enum BmtpPackFlag: SwiftProtobuf.Enum {
    typealias RawValue = Int
    case packFlagNone // = 0

    /// 是否请求响应。0000 0000 0000 0001
    case packFlagAck // = 1

    /// 是否重发。0000 0000 0000 0010
    case packFlagDup // = 2

    /// 是否计数。0000 0000 0000 0100
    case packFlagCounter // = 4

    /// 是否覆写。0000 0000 0000 1000
    case packFlagOverride // = 8

    /// 高优先级。0000 0000 0001 0000
    case packFlagRevoke // = 16

    /// 压缩算法。0000 0000 0010 0000
    case packFlagHighprj // = 32

    /// 加密算法。0000 0000 0100 0000
    case packFlagCompress // = 64
    case UNRECOGNIZED(Int)

    init() {
        self = .packFlagNone
    }

    init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .packFlagNone
        case 1: self = .packFlagAck
        case 2: self = .packFlagDup
        case 4: self = .packFlagCounter
        case 8: self = .packFlagOverride
        case 16: self = .packFlagRevoke
        case 32: self = .packFlagHighprj
        case 64: self = .packFlagCompress
        default: self = .UNRECOGNIZED(rawValue)
        }
    }

    var rawValue: Int {
        switch self {
        case .packFlagNone: return 0
        case .packFlagAck: return 1
        case .packFlagDup: return 2
        case .packFlagCounter: return 4
        case .packFlagOverride: return 8
        case .packFlagRevoke: return 16
        case .packFlagHighprj: return 32
        case .packFlagCompress: return 64
        case let .UNRECOGNIZED(i): return i
        }
    }
}

#if swift(>=4.2)

    extension BmtpPackFlag: CaseIterable {
        // The compiler won't synthesize support with the UNRECOGNIZED case.
        static let allCases: [BmtpPackFlag] = [
            .packFlagNone,
            .packFlagAck,
            .packFlagDup,
            .packFlagCounter,
            .packFlagOverride,
            .packFlagRevoke,
            .packFlagHighprj,
            .packFlagCompress,
        ]
    }

#endif // swift(>=4.2)

struct BmtpHeader {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    var packID: String = .init()

    var type: BmtpPackType = .packTypeNone

    var flag: BmtpPackFlag = .packFlagNone

    var version: Int64 = 0

    var code: Int64 = 0

    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
}

#if swift(>=5.5) && canImport(_Concurrency)
    extension BmtpPackType: @unchecked Sendable {}
    extension BmtpPackFlag: @unchecked Sendable {}
    extension BmtpHeader: @unchecked Sendable {}
#endif // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension BmtpPackType: SwiftProtobuf._ProtoNameProviding {
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        0: .same(proto: "PACK_TYPE_NONE"),
        1: .same(proto: "PACK_TYPE_PING"),
        10: .same(proto: "PACK_TYPE_LOGOUT"),
        11: .same(proto: "PACK_TYPE_KICKOUT"),
        19: .same(proto: "PACK_TYPE_NOTE"),
        20: .same(proto: "PACK_TYPE_MSG_CHAT"),
        21: .same(proto: "PACK_TYPE_MSG_GROUP_CHAT"),
    ]
}

extension BmtpPackFlag: SwiftProtobuf._ProtoNameProviding {
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        0: .same(proto: "PACK_FLAG_NONE"),
        1: .same(proto: "PACK_FLAG_ACK"),
        2: .same(proto: "PACK_FLAG_DUP"),
        4: .same(proto: "PACK_FLAG_COUNTER"),
        8: .same(proto: "PACK_FLAG_OVERRIDE"),
        16: .same(proto: "PACK_FLAG_REVOKE"),
        32: .same(proto: "PACK_FLAG_HIGHPRJ"),
        64: .same(proto: "PACK_FLAG_COMPRESS"),
    ]
}

extension BmtpHeader: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
    static let protoMessageName: String = "BmtpHeader"
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        1: .same(proto: "packId"),
        2: .same(proto: "type"),
        3: .same(proto: "flag"),
        4: .same(proto: "version"),
        5: .same(proto: "code"),
    ]

    mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        while let fieldNumber = try decoder.nextFieldNumber() {
            // The use of inline closures is to circumvent an issue where the compiler
            // allocates stack space for every case branch when no optimizations are
            // enabled. https://github.com/apple/swift-protobuf/issues/1034
            switch fieldNumber {
            case 1: try decoder.decodeSingularStringField(value: &packID)
            case 2: try decoder.decodeSingularEnumField(value: &type)
            case 3: try decoder.decodeSingularEnumField(value: &flag)
            case 4: try decoder.decodeSingularInt64Field(value: &version)
            case 5: try decoder.decodeSingularInt64Field(value: &code)
            default: break
            }
        }
    }

    func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        if !packID.isEmpty {
            try visitor.visitSingularStringField(value: packID, fieldNumber: 1)
        }
        if type != .packTypeNone {
            try visitor.visitSingularEnumField(value: type, fieldNumber: 2)
        }
        if flag != .packFlagNone {
            try visitor.visitSingularEnumField(value: flag, fieldNumber: 3)
        }
        if version != 0 {
            try visitor.visitSingularInt64Field(value: version, fieldNumber: 4)
        }
        if code != 0 {
            try visitor.visitSingularInt64Field(value: code, fieldNumber: 5)
        }
        try unknownFields.traverse(visitor: &visitor)
    }

    static func == (lhs: BmtpHeader, rhs: BmtpHeader) -> Bool {
        if lhs.packID != rhs.packID { return false }
        if lhs.type != rhs.type { return false }
        if lhs.flag != rhs.flag { return false }
        if lhs.version != rhs.version { return false }
        if lhs.code != rhs.code { return false }
        if lhs.unknownFields != rhs.unknownFields { return false }
        return true
    }
}
