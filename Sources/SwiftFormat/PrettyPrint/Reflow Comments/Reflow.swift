enum Reflow {
  /// Returns a new string with the reflowed version of the given string.
  static func reflowComments(_ lines: [String], maxWidth: Int) -> [String] {
    // Run `lines` through the parsers to group into blocks.
    var blocks: [any DocBlock] = []
    var parser: any DocLineParser = Reflow.EmptyParser()
    for line in lines {
      parser = parser.parseLine(line, blocks: &blocks)
    }

    // This pairing dance is so that bulleted lists can omit blank lines between
    // them, but every other block can have a trailing blank line.
    let blockPairs = zip(blocks, blocks.dropFirst())
    let rendered: [String] = blockPairs.map { (current, next) in
      let result = current.renderForWidth(maxWidth)
      if current.keepWith(next) {
        return result
      } else {
        return result + "\n"
      }
    }
      + [blocks.last!.renderForWidth(maxWidth)]
      + (lines.last == "\n" ? ["\n"] : [])
    
    return rendered.flatMap {
      $0.split(separator: "\n", omittingEmptySubsequences: false)
        .map(String.init)
    }
  }
}
