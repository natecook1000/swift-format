/// A state machine for parsing lines of documentation.
protocol DocLineParser {
  /// Given a line of documentation and an array of blocks, updates the array
  /// of blocks and returns the parser to handle the next line.
  func parseLine(
    _ line: String, blocks: inout [DocBlock]
  ) -> DocLineParser
}

extension StringProtocol where SubSequence == Substring {
  var withoutLeadingWhitespace: Substring {
    self.drop(while: \.isWhitespace)
  }
  
  var isEmptyOrWhiteSpace: Bool {
    withoutLeadingWhitespace.isEmpty
  }
  
  func matches(_ pattern: String) -> Bool {
    return nil != range(of: pattern, options: .regularExpression)
  }
  
  var leadingWhitespaceCount: Int {
    prefix(while: \.isWhitespace).count
  }
  
  func wrapAtWidth(
    _ width: Int,
    withPrefix prefix: String = "",
    indentingWrappedBy indentWrapped: Int = 0
  ) -> String {
    // The actual width to wrap to
    var localWidth = width - prefix.count
    // The per-line prefix to add - this includes any additional indentation,
    // as is used for lists where the bullet is a hanging indentation
    var localPrefix = prefix
    // The running result string
    var result = ""
    
    // The current index in the string while scanning
    var current = startIndex
    // Track the start of the "current" line
    var lineStart = startIndex
    // The last possible break point seen while scanning
    var lastSpace = startIndex
    
    // Length of the current line
    var lineCount = 0
    // Flag to track whether we're in an `inline code` block
    // Don't want to wrap in the middle of that, so we skip spaces when
    // this is true
    var inlineCode = false
    
    /// Adds the currently running segment, in the range `lineStart..<lastSpace`
    /// to `result`, then updates the current state.
    func addCurrentSegment() {
      let toAdd = self[lineStart ..< lastSpace]
      
      // If the line consists only of white space, we just add the prefix
      // without the trailing space.
      if toAdd.isEmptyOrWhiteSpace {
        result += String(prefix.dropLast()) + "\n"
      } else {
        result += localPrefix + toAdd + "\n"
      }
      
      // Reset the state
      lineStart = index(after: lastSpace)
      lineCount = distance(from: lineStart, to: current)
      
      localPrefix = prefix + String(repeating: " ", count: indentWrapped)
      localWidth = width - localPrefix.count
    }
    
    while current != endIndex {
      switch self[current] {
      case "`":
        // Inline code span is starting or stopping
        inlineCode = !inlineCode
      case " " where !inlineCode:
        // A space (outside of a code span) is when we check for line length.
        // If the line is too long at this point, we add the segment up to
        // the *last* space (not this one, since it's too far), then continue.
        if lineCount > localWidth {
          addCurrentSegment()
        }
        lastSpace = current
      case "\n":
        // A line break is always treated as the end of a segment.
        lastSpace = current
        addCurrentSegment()
      default:
        break
      }
      
      formIndex(after: &current)
      lineCount += 1
    }
    
    // Do we have any characters left over?
    if lineStart != current {
      // Did the current line go over length? Add another segment if so
      if lineCount >= localWidth {
        addCurrentSegment()
      }
      // Add anything still left over
      result += localPrefix + self[lineStart...]
    }
    
    return result
  }
}

extension DocLineParser {
  /// Returns `true` if the given string is part of a code block.
  func isCodeBlock(_ line: String) -> Bool {
    line.starts(with: "    ")
  }
  
  /// Returns `true` if the given string is a bulleted list item.
  func isBullet(_ line: String) -> Bool {
    switch line.withoutLeadingWhitespace.prefix(2) {
    case "- ", "* ", "+ ":
      return true
    default:
      return false
    }
  }
  
  func isCodeFence(_ line: String) -> Bool {
    line.withoutLeadingWhitespace.starts(with: "```")
  }
  
  /// Returns `true` if the given string is a numbered list item.
  func isNumberedItem(_ line: String) -> Bool {
    let s = line.withoutLeadingWhitespace
    let numberPrefix = s.prefix(while: \.isNumber)
    if numberPrefix.isEmpty { return false }
    switch s[numberPrefix.endIndex...].prefix(2) {
    case ". ", ") ":
      return true
    default:
      return false
    }
  }
  
  /// Returns `true` if the given string is a Markdown link reference.
  func isLinkReference(_ line: String) -> Bool {
    return line.matches("^\\[.+\\]: .+")
  }
  
  /// Returns the matching `DocumentationBlock` type for the given string.
  func getBlockForLine(_ line: String) -> DocBlock.Type {
    if isBullet(line) || isNumberedItem(line) {
      return Reflow.ListItem.self
    }
    
    if isCodeFence(line) {
      return Reflow.FencedCodeBlock.self
    }
    
    if isCodeBlock(line) {
      return Reflow.CodeBlock.self
    }
    
    if isLinkReference(line) {
      return Reflow.UnwrappedLine.self
    }
    
    return Reflow.Paragraph.self
  }
}

extension Reflow {
  /// A "default" parser with no inherent state.
  struct EmptyParser: DocLineParser {
    func parseLine(
      _ line: String, blocks: inout [DocBlock]
    ) -> DocLineParser {
      // Just skip empty lines at this point
      if line.isEmptyOrWhiteSpace {
        return self
      }
      
      // Find and add the next block type
      let docBlockType = getBlockForLine(line)
      blocks += [docBlockType.init(text: line)]
      return docBlockType.parser
    }
  }
  
  /// A parser to use in the context of a paragraph.
  struct ParagraphParser: DocLineParser {
    func parseLine(
      _ line: String, blocks: inout [DocBlock]
    ) -> DocLineParser {
      // Stop this paragraph on a blank line
      if line.isEmptyOrWhiteSpace {
        return EmptyParser()
      }
      if isCodeFence(line) {
        blocks.append(FencedCodeBlock(text: line))
        return FencedCodeParser()
      }
      
      // Look for a Markdown header in setext format.
      let underlinePattern = "^\\s*[-=]+$"
      if line.matches(underlinePattern) {
        // Match the line to the length of the header.
        let headerLength = (blocks.last! as! Paragraph).text.count
        blocks[blocks.endIndex - 1].addText("\n" + String(repeating: line.last!, count: headerLength))
        return EmptyParser()
      }
      
      // Nothing special, just more text
      blocks[blocks.endIndex - 1].addText(line)
      return self
    }
  }
  
  /// A parser to use in the context of a bulleted or numbered list.
  struct BulletParser: DocLineParser {
    func parseLine(
      _ line: String, blocks: inout [DocBlock]
    ) -> DocLineParser {
      // Stop this bullet on an empty line
      if line.isEmptyOrWhiteSpace {
        return EmptyParser()
      }
      
      // Also stop if we encounter another bullet
      if isBullet(line) || isNumberedItem(line) {
        // Find and add the next block type
        let docBlockType = getBlockForLine(line)
        blocks += [docBlockType.init(text: line)]
        return docBlockType.parser
      }
      
      blocks[blocks.endIndex - 1].addText(line)
      return self
    }
  }
  
  /// A parser to use in the context of an indented code block.
  struct CodeParser: DocLineParser {
    func parseLine(
      _ line: String, blocks: inout [DocBlock]
    ) -> DocLineParser {
      // Add empty or properly indented lines to the code block
      if line.isEmptyOrWhiteSpace
          || line.leadingWhitespaceCount >= blocks.last!.indent
      {
        blocks[blocks.endIndex - 1].addText(line)
        return self
      }
      
      // Not a code block
      // Find and add the next block type
      let docBlockType = getBlockForLine(line)
      blocks.append(docBlockType.init(text: line))
      return docBlockType.parser
    }
  }
  
  /// A parser to use in the context of an indented code block.
  struct FencedCodeParser: DocLineParser {
    func parseLine(
      _ line: String, blocks: inout [DocBlock]
    ) -> DocLineParser {
      blocks[blocks.endIndex - 1].addText(line)

      guard !isCodeFence(line) else {
        return EmptyParser()
      }
      return self
    }
  }
}
