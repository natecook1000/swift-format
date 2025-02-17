/// A type that can represent a block of documentation.
protocol DocBlock {
  /// The parser that handles this type of block.
  static var parser: DocLineParser { get }
  
  /// Creates a new block with the given string.
  init(text: String)
  
  /// The indent level for this particular block.
  var indent: Int { get }
  
  /// Adds the given string to this block, formatting as required.
  mutating func addText(_ newText: String)
  
  /// Returns the contents of the block, wrapped at the given width and
  /// prefixed by the given prefix.
  func renderForWidth(_ width: Int) -> String
  
  /// Returns `true` if the given block should follow this block without
  /// a blank line between them.
  func keepWith(_ next: DocBlock) -> Bool
}

extension DocBlock {
  func keepWith(_ next: DocBlock) -> Bool {
    false
  }
}

extension Reflow {
  /// A paragraph block.
  struct Paragraph: DocBlock {
    static var parser: DocLineParser = ParagraphParser()
    
    var text: String
    let indent: Int
    
    var headerToken = ""
    
    init(text: String) {
      self.text = text.trimmingTrailingWhitespace()
      self.indent = text.leadingWhitespaceCount
    }
    
    func renderForWidth(_ width: Int) -> String {
      text.wrapAtWidth(width, indentingWrappedBy: indent)
    }
    
    mutating func addText(_ newText: String) {
      let spacer = newText.first == "\n" ? "" : " "
      text += spacer + newText.trimmingCharacters(in: .whitespaces)
    }
  }
  
  /// A block for a single list item, either ordered or unordered.
  struct ListItem: DocBlock {
    static var parser: DocLineParser = BulletParser()
    
    var text: String
    let indent: Int
    let hangingIndent: Int
    
    init(text: String) {
      self.text = text.trimmingTrailingWhitespace()
      self.indent = text.leadingWhitespaceCount
      self.hangingIndent = text
        .drop(while: { $0.isWhitespace })
        .prefix(while: { !$0.isWhitespace })
        .count + 1
    }
    
    func renderForWidth(_ width: Int) -> String {
      text.wrapAtWidth(width, indentingWrappedBy: indent + hangingIndent)
    }
    
    mutating func addText(_ newText: String) {
      text += " " + newText.trimmingCharacters(in: .whitespaces)
    }
    
    func keepWith(_ next: DocBlock) -> Bool {
      next is ListItem
    }
  }
  
  /// A block for an indented code block.
  struct CodeBlock: DocBlock {
    static var parser: DocLineParser = CodeParser()
    
    /// The lines of code, not to be wrapped.
    var lines: [String]
    let indent: Int
    
    init(text: String) {
      self.lines = [text]
      self.indent = text.leadingWhitespaceCount
    }
    
    mutating func addText(_ newText: String) {
      lines.append(newText)
    }
    
    /// Returns the lines of the code block without wrapping.
    func renderForWidth(_ width: Int) -> String {
      let linesToDrop = lines.last?.isEmpty == true ? 1 : 0
      return lines.dropLast(linesToDrop).map {
        $0.trimmingTrailingWhitespace()
      }.joined(separator: "\n")
    }
  }
  
  struct FencedCodeBlock: DocBlock {
    static var parser: DocLineParser = FencedCodeParser()
    
    /// The lines of code, not to be wrapped.
    var lines: [String]
    let indent: Int
    
    init(text: String) {
      self.lines = [text]
      self.indent = text.leadingWhitespaceCount
    }
    
    mutating func addText(_ newText: String) {
      lines.append(newText)
    }
    
    /// Returns the lines of the code block prefixed with `prefix`. Ignores the
    /// `width` parameter and doesn't wrap its lines.
    func renderForWidth(_ width: Int) -> String {
      lines.map { $0.trimmingTrailingWhitespace() }
        .joined(separator: "\n")
    }
  }

  /// A block for a line of text that shouldn't be wrapped in the output.
  ///
  /// This is currently only used for Markdown link references, like this:
  /// [ref]: http://example.com/path/to/a/long_url_needs_to_stay_on_the_same_line_as_its_label.html
  struct UnwrappedLine: DocBlock {
    static var parser: DocLineParser = EmptyParser()
    
    /// The line of code, not to be wrapped.
    let text: String
    
    /// This is ignored - the line is returned as is.
    let indent = 0
    
    init(text: String) {
      self.text = text.trimmingTrailingWhitespace()
    }
    
    func addText(_ newText: String) {
      fatalError("An unwrapped line only supports single line")
    }
    
    func renderForWidth(_ width: Int) -> String {
      text.wrapAtWidth(.max, indentingWrappedBy: 0)
    }
    
    func keepWith(_ next: DocBlock) -> Bool {
      next is UnwrappedLine
    }
  }
}
