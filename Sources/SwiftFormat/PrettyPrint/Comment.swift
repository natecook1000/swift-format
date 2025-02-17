//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftSyntax

extension StringProtocol {
  /// Trims whitespace from the end of a string, returning a new string with no trailing whitespace.
  ///
  /// If the string is only whitespace, an empty string is returned.
  ///
  /// - Returns: The string with trailing whitespace removed.
  func trimmingTrailingWhitespace() -> String {
    if isEmpty { return String() }
    let scalars = unicodeScalars
    var idx = scalars.index(before: scalars.endIndex)
    while scalars[idx].properties.isWhitespace {
      if idx == scalars.startIndex { return String() }
      idx = scalars.index(before: idx)
    }
    return String(String.UnicodeScalarView(scalars[...idx]))
  }
}

struct Comment {
  enum Kind {
    case line, docLine, block, docBlock

    /// A Boolean value indicating whether this is a documentation comment.
    var isDocComment: Bool {
      switch self {
      // `//`, `/*`
      case .line, .block: return false
      // `///`, `/**`
      case .docLine, .docBlock: return true
      }
    }

    /// The length of the characters starting the comment.
    var prefixLength: Int {
      isDocComment ? 3 : 2
    }

    var prefix: String {
      switch self {
      case .line: return "//"
      case .block: return "/*"
      case .docBlock: return "/**"
      case .docLine: return "///"
      }
    }
  }

  let kind: Kind
  var text: [String]
  var length: Int
  // what was the leading indentation, if any, that preceded this comment?
  var leadingIndent: Indent?

  init(kind: Kind, leadingIndent: Indent?, text: String) {
    self.kind = kind
    self.leadingIndent = leadingIndent

    switch kind {
    case .line, .docLine:
      self.length = text.count
      self.text = [text]
      self.text[0].removeFirst(kind.prefixLength)

    case .block, .docBlock:
      var fulltext: String = text
      fulltext.removeFirst(kind.prefixLength)
      fulltext.removeLast(2)
      let lines = fulltext.split(separator: "\n", omittingEmptySubsequences: false)

      // The last line in a block style comment contains the "*/" pattern to end the comment. The
      // trailing space(s) need to be kept in that line to have space between text and "*/".
      var trimmedLines = lines.dropLast().map({ $0.trimmingTrailingWhitespace() })
      if let lastLine = lines.last {
        trimmedLines.append(String(lastLine))
      }
      self.text = trimmedLines
      self.length = self.text.reduce(0, { $0 + $1.count }) + kind.prefixLength + 3
    }
  }

  func _printImpl(text: [String], indent: [Indent]) -> String {
    switch self.kind {
    case .line, .docLine:
      let separator = "\n" + indent.indentation() + kind.prefix
      let trimmedLines = text.map { $0.trimmingTrailingWhitespace() }
      return kind.prefix + trimmedLines.joined(separator: separator)
    case .block, .docBlock:
      let separator = "\n"

      // if all the lines after the first matching leadingIndent, replace that prefix with the
      // current indentation level
      if let leadingIndent {
        return kind.prefix
          + text
              .reindentingRest(from: leadingIndent.text, to: indent.indentation())
              .joined(separator: "\n")
          + "*/"
      }

      return kind.prefix + text.joined(separator: separator) + "*/"
    }
  }

  func print(indent: [Indent]) -> String {
    _printImpl(text: self.text, indent: indent)
  }

  func reflow(toWidth: Int, indent: [Indent]) -> String {
    // Non-doc comments don't get re-flowed.
    guard self.kind.isDocComment, !text.isEmpty else {
      return print(indent: indent)
    }
            
    // When wrapping, need to account for indentation, the prefix, and a space.
    let maxIndent = indent.map(\.count).max() ?? 0
    let wrapLimit = toWidth - (maxIndent + kind.prefix.count + 1)

    // Strip the lines of their initial whitespace.
    let whitespacePrefix = (self.leadingIndent?.text ?? "") + "    "
    var strippedText: [String]
    if kind == .docBlock {
      strippedText = text.reindentingRest(from: whitespacePrefix, to: "")
      strippedText[0].removeFirst()
    } else {
      strippedText = text.map { String($0.dropFirst()) }
    }
    
    var reflowedText = Reflow.reflowComments(strippedText, maxWidth: wrapLimit)

    // Re-apply initial whitespace.
    if self.kind == .docBlock, !reflowedText.isEmpty {
      // `.docBlock` comments need four prefixed spaces UNLESS empty or with
      // an existing block indent, except for the first line, which just needs
      // a single prefixed space (because it will get the actual prefix later).
      reflowedText[0] = " " + reflowedText[0]
      for i in reflowedText.indices.dropFirst() {
        if reflowedText[i].isEmpty { continue }
        reflowedText[i] = whitespacePrefix + reflowedText[i]
      }
      // The last line also needs a trailing space, to make room for the
      // comment-closing suffix.
      reflowedText[reflowedText.count - 1] += " "
    } else {
      // `.docLine` comments all just get a single prefixed space.
      reflowedText = reflowedText.map { " " + $0 }
    }
    
    return _printImpl(text: reflowedText, indent: indent)
  }
  
  mutating func addText(_ text: [String]) {
    for line in text {
      self.text.append(line)
      self.length += line.count + self.kind.prefixLength + 1
    }
  }
}

extension Array where Element == String {
  fileprivate func reindentingRest(from current: String, to new: String) -> Self {
    guard count > 1 else { return self }
    guard dropFirst().allSatisfy({ $0.hasPrefix(current) || $0.isEmpty })
      else { return self }
    
    var result = [self[0]]
    result.reserveCapacity(count)
    for s in dropFirst() {
      if s.isEmpty {
        result.append(s)
      } else {
        result.append(new + s.dropFirst(current.count))
      }
    }
    return result
  }
}
