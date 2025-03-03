// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: comment.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

public struct Common_CommentInfo: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var commentID: Int64 = 0

  public var prevCommentID: Int64 = 0

  public var userID: Int64 = 0

  public var userName: String = String()

  public var avatarURL: String = String()

  public var storyID: Int64 = 0

  public var boardID: Int64 = 0

  public var groupID: Int64 = 0

  public var content: String = String()

  public var ctime: Int64 = 0

  public var mtime: Int64 = 0

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "common"

extension Common_CommentInfo: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".CommentInfo"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "comment_id"),
    2: .standard(proto: "prev_comment_id"),
    3: .standard(proto: "user_id"),
    4: .standard(proto: "user_name"),
    5: .standard(proto: "avatar_url"),
    6: .standard(proto: "story_id"),
    7: .standard(proto: "board_id"),
    8: .standard(proto: "group_id"),
    9: .same(proto: "content"),
    10: .same(proto: "ctime"),
    11: .same(proto: "mtime"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt64Field(value: &self.commentID) }()
      case 2: try { try decoder.decodeSingularInt64Field(value: &self.prevCommentID) }()
      case 3: try { try decoder.decodeSingularInt64Field(value: &self.userID) }()
      case 4: try { try decoder.decodeSingularStringField(value: &self.userName) }()
      case 5: try { try decoder.decodeSingularStringField(value: &self.avatarURL) }()
      case 6: try { try decoder.decodeSingularInt64Field(value: &self.storyID) }()
      case 7: try { try decoder.decodeSingularInt64Field(value: &self.boardID) }()
      case 8: try { try decoder.decodeSingularInt64Field(value: &self.groupID) }()
      case 9: try { try decoder.decodeSingularStringField(value: &self.content) }()
      case 10: try { try decoder.decodeSingularInt64Field(value: &self.ctime) }()
      case 11: try { try decoder.decodeSingularInt64Field(value: &self.mtime) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.commentID != 0 {
      try visitor.visitSingularInt64Field(value: self.commentID, fieldNumber: 1)
    }
    if self.prevCommentID != 0 {
      try visitor.visitSingularInt64Field(value: self.prevCommentID, fieldNumber: 2)
    }
    if self.userID != 0 {
      try visitor.visitSingularInt64Field(value: self.userID, fieldNumber: 3)
    }
    if !self.userName.isEmpty {
      try visitor.visitSingularStringField(value: self.userName, fieldNumber: 4)
    }
    if !self.avatarURL.isEmpty {
      try visitor.visitSingularStringField(value: self.avatarURL, fieldNumber: 5)
    }
    if self.storyID != 0 {
      try visitor.visitSingularInt64Field(value: self.storyID, fieldNumber: 6)
    }
    if self.boardID != 0 {
      try visitor.visitSingularInt64Field(value: self.boardID, fieldNumber: 7)
    }
    if self.groupID != 0 {
      try visitor.visitSingularInt64Field(value: self.groupID, fieldNumber: 8)
    }
    if !self.content.isEmpty {
      try visitor.visitSingularStringField(value: self.content, fieldNumber: 9)
    }
    if self.ctime != 0 {
      try visitor.visitSingularInt64Field(value: self.ctime, fieldNumber: 10)
    }
    if self.mtime != 0 {
      try visitor.visitSingularInt64Field(value: self.mtime, fieldNumber: 11)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Common_CommentInfo, rhs: Common_CommentInfo) -> Bool {
    if lhs.commentID != rhs.commentID {return false}
    if lhs.prevCommentID != rhs.prevCommentID {return false}
    if lhs.userID != rhs.userID {return false}
    if lhs.userName != rhs.userName {return false}
    if lhs.avatarURL != rhs.avatarURL {return false}
    if lhs.storyID != rhs.storyID {return false}
    if lhs.boardID != rhs.boardID {return false}
    if lhs.groupID != rhs.groupID {return false}
    if lhs.content != rhs.content {return false}
    if lhs.ctime != rhs.ctime {return false}
    if lhs.mtime != rhs.mtime {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
