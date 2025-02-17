import SwiftFormat

final class DocumentationReflowTests: PrettyPrintTestCase {
  var config: Configuration {
    var config = Configuration()
    config.reflowDocumentationComments = true
    return config
  }
  
  func testReflowDocumentationComments() {
    let input =
      """
      /// This is a doc comment.
      /// This is the second sentence of a comment.
      /// This is a third line.
      func foo() {}
      """
    let expected =
      """
      /// This is a doc comment. This is the
      /// second sentence of a comment. This
      /// is a third line.
      func foo() {}
      
      """
    assertPrettyPrintEqual(
      input: input, expected: expected, linelength: 40, configuration: config)
  }
  
  func testReflowDocumentationCommentsIndented() {
    let input =
      """
      public class MyClass {
        /// This is the first doc comment.
        /// This is the second sentence of a comment.
        /// This is a third line.
        enum MyEnum {
          /// The first case.
          case one
          /// The second case, which will take up more than one line.
          case two
        }
      }
      """
    let expected =
      """
      public class MyClass {
        /// This is the first doc comment.
        /// This is the second sentence of a
        /// comment. This is a third line.
        enum MyEnum {
          /// The first case.
          case one
          /// The second case, which will take
          /// up more than one line.
          case two
        }
      }
      
      """
    assertPrettyPrintEqual(
      input: input, expected: expected, linelength: 40, configuration: config)
  }
  
  func testReflowDocumentationCommentsAdvanced() {
    let input =
      """
      /// This is a doc comment. 
      /// This is the second sentence of a comment.
      /// This is a third line.
      ///
      /// This is after an empty line.
      ///
      /// This is a comment that probably should have already been wrapped. It's so long that it goes way past one line.
      /// And then another line with a more normal size.
      ///
      ///     let foo = 1
      ///     print(foo)
      ///     // Prints "1"
      ///
      /// Another section explaining the code sample, and introducing another:
      ///
      /// ```bash
      /// $ example --one two --three -4
      /// ```
      ///  
      /// Here are some additional Markdown features, like a list:
      ///
      /// * First item.
      /// * Second item is quite long, and should of course wrap.
      /// * This item is also long, because it has to introduce a nested list:
      ///   - This nested list uses dashes. It also has a long item.
      ///   - And a short one.
      ///   - And another long item that should wrap onto another line.
      /// * And finally the last item of the list.
      ///
      /// And then a numbered list:
      ///
      /// 1. The first item is quite long, and should wrap.
      /// 2. The second item is short.
      /// 1. The third item uses the incorrect number, and is also long.
      /// 4. The fourth item.
      ///
      /// Hey, how about a block quote:
      ///
      /// > As accustomed as I am to public speaking, 
      /// I'd like to share with you a maxim I thought of the first time I met an IBM mainframe: 
      /// NEVER TRUST A COMPUTER YOU CAN'T LIFT!
      ///
      /// - Parameters:
      ///   - first: This is a long comment that should definitely wrap, 
      ///     for a closure with two parameters.
      ///     - param1: Hello.
      ///     - param2: Goodbye.
      ///   - second: A short comment.
      ///   - third: This comment
      ///     has line breaks
      ///     already in it.
      /// - Throws: An error if something is wrong.
      func foo() {}
      """
    let expected =
      """
      /// This is a doc comment. This is the
      /// second sentence of a comment. This
      /// is a third line.
      ///
      /// This is after an empty line.
      ///
      /// This is a comment that probably
      /// should have already been wrapped.
      /// It's so long that it goes way past
      /// one line. And then another line with
      /// a more normal size.
      ///
      ///     let foo = 1
      ///     print(foo)
      ///     // Prints "1"
      ///
      /// Another section explaining the code
      /// sample, and introducing another:
      ///
      /// ```bash
      /// $ example --one two --three -4
      /// ```
      ///
      /// Here are some additional Markdown
      /// features, like a list:
      ///
      /// * First item.
      /// * Second item is quite long, and
      ///   should of course wrap.
      /// * This item is also long, because it
      ///   has to introduce a nested list:
      ///   - This nested list uses dashes. It
      ///     also has a long item.
      ///   - And a short one.
      ///   - And another long item that
      ///     should wrap onto another line.
      /// * And finally the last item of the
      ///   list.
      ///
      /// And then a numbered list:
      ///
      /// 1. The first item is quite long, and
      ///    should wrap.
      /// 2. The second item is short.
      /// 1. The third item uses the incorrect
      ///    number, and is also long.
      /// 4. The fourth item.
      ///
      /// Hey, how about a block quote:
      ///
      /// > As accustomed as I am to public
      /// speaking, I'd like to share with you
      /// a maxim I thought of the first time
      /// I met an IBM mainframe: NEVER TRUST
      /// A COMPUTER YOU CAN'T LIFT!
      ///
      /// - Parameters:
      ///   - first: This is a long comment
      ///     that should definitely wrap, for
      ///     a closure with two parameters.
      ///     - param1: Hello.
      ///     - param2: Goodbye.
      ///   - second: A short comment.
      ///   - third: This comment has line
      ///     breaks already in it.
      /// - Throws: An error if something is
      ///   wrong.
      func foo() {}
      
      """
    assertPrettyPrintEqual(
      input: input, expected: expected, linelength: 40, configuration: config)
  }
  
  func testReflowDocumentationCommentsAdvancedIndented() {
    let input =
      """
      class MyClass {
        /// This is a doc comment.
        /// This is the second sentence of a comment.
        /// This is a third line.
        ///
        /// This is after an empty line.
        ///
        /// This is a comment that probably should have already been wrapped. It's so long that it goes way past one line.
        /// And then another line with a more normal size.
        ///
        ///     let foo = 1
        ///     print(foo)
        ///     // Prints "1"
        ///
        /// Another section explaining the code sample, and introducing another:
        ///
        /// ```bash
        /// $ example --one two --three -4
        /// ```
        /// 
        /// - Parameters:
        ///   - first: This is a long comment that should definitely wrap, 
        ///     for a closure with two parameters.
        ///     - param1: Hello.
        ///     - param2: Goodbye.
        ///   - second: A short comment.
        ///   - third: This comment
        ///     has line breaks
        ///     already in it.
        /// - Throws: An error if something is wrong.
        func foo() {}
      }
      """
    let expected =
      """
      class MyClass {
        /// This is a doc comment. This is the
        /// second sentence of a comment. This
        /// is a third line.
        ///
        /// This is after an empty line.
        ///
        /// This is a comment that probably
        /// should have already been wrapped.
        /// It's so long that it goes way past
        /// one line. And then another line
        /// with a more normal size.
        ///
        ///     let foo = 1
        ///     print(foo)
        ///     // Prints "1"
        ///
        /// Another section explaining the
        /// code sample, and introducing
        /// another:
        ///
        /// ```bash
        /// $ example --one two --three -4
        /// ```
        ///
        /// - Parameters:
        ///   - first: This is a long comment
        ///     that should definitely wrap,
        ///     for a closure with two
        ///     parameters.
        ///     - param1: Hello.
        ///     - param2: Goodbye.
        ///   - second: A short comment.
        ///   - third: This comment has line
        ///     breaks already in it.
        /// - Throws: An error if something is
        ///   wrong.
        func foo() {}
      }
      
      """
    assertPrettyPrintEqual(
      input: input, expected: expected, linelength: 40, configuration: config)
  }

  func testReflowDocumentationBlockComments() {
    let input =
      """
      /** This is a doc comment.
          This is the second sentence of a comment.
          This is a third line. */
      func foo() {}
      """
    let expected =
      """
      /** This is a doc comment. This is the
          second sentence of a comment. This
          is a third line. */
      func foo() {}
      
      """
    assertPrettyPrintEqual(
      input: input, expected: expected, linelength: 40, configuration: config)
  }
  
  func testReflowDocumentationBlockCommentsIndented() {
    let input =
      """
      public class MyClass {
        /** This is the first doc comment.
            This is the second sentence of a comment.
            This is a third line. */
        func foo() {}
      }
      """
    let expected =
      """
      public class MyClass {
        /** This is the first doc comment.
            This is the second sentence of a
            comment. This is a third line. */
        func foo() {}
      }
      
      """
    assertPrettyPrintEqual(
      input: input, expected: expected, linelength: 40, configuration: config)
  }
  
  func testReflowDocumentationBlockCommentsAdvanced() {
    let input =
      """
      /** This is a doc comment.
          This is the second sentence of a comment.
          This is a third line.
      
          This is after an empty line.
      
          This is a comment that probably should have already been wrapped. It's so long that it goes way past one line.
          And then another line with a more normal size.
      
              let foo = 1
              print(foo)
              // Prints "1"
      
          Another section explaining the code sample, and introducing another:
      
          ```bash
          $ example --one two --three -4
          ```
      
          Sometimes people forget the line break before a fenced code block:
          ```
          func bar() {}
          ```
      
          - Parameters:
            - first: This is a long comment that should definitely wrap, 
              for a closure with two parameters.
              - param1: Hello.
              - param2: Goodbye.
            - second: A short comment.
            - third: This comment
              has line breaks
              already in it.
          - Throws: An error if something is wrong. */
      func foo() {}
      """
    let expected =
      """
      /** This is a doc comment. This is the
          second sentence of a comment. This
          is a third line.
      
          This is after an empty line.
      
          This is a comment that probably
          should have already been wrapped.
          It's so long that it goes way past
          one line. And then another line with
          a more normal size.
      
              let foo = 1
              print(foo)
              // Prints "1"
      
          Another section explaining the code
          sample, and introducing another:
      
          ```bash
          $ example --one two --three -4
          ```
      
          Sometimes people forget the line
          break before a fenced code block:
      
          ```
          func bar() {}
          ```

          - Parameters:
            - first: This is a long comment
              that should definitely wrap, for
              a closure with two parameters.
              - param1: Hello.
              - param2: Goodbye.
            - second: A short comment.
            - third: This comment has line
              breaks already in it.
          - Throws: An error if something is
            wrong. */
      func foo() {}
      
      """
    assertPrettyPrintEqual(
      input: input, expected: expected, linelength: 40, configuration: config)
  }
  
  func testReflowDocumentationBlockCommentsAdvancedIndented() {
    let input =
      """
      class MyClass {
        /** This is a doc comment.
            This is the second sentence of a comment.
            This is a third line.
           
            This is after an empty line.
           
            This is a comment that probably should have already been wrapped. It's so long that it goes way past one line.
            And then another line with a more normal size.
           
                let foo = 1
                print(foo)
                // Prints "1"
           
            Another section explaining the code sample, and introducing another:
           
            ```bash
            $ example --one two --three -4
            ```
            
            - Parameters:
              - first: This is a long comment that should definitely wrap, 
                for a closure with two parameters.
                - param1: Hello.
                - param2: Goodbye.
              - second: A short comment.
              - third: This comment
                has line breaks
                already in it.
            - Throws: An error if something is wrong. */
        func foo() {}
      }
      """
    let expected =
      """
      class MyClass {
        /** This is a doc comment. This is the
            second sentence of a comment. This
            is a third line.
      
            This is after an empty line.
      
            This is a comment that probably
            should have already been wrapped.
            It's so long that it goes way past
            one line. And then another line
            with a more normal size.
      
                let foo = 1
                print(foo)
                // Prints "1"
      
            Another section explaining the
            code sample, and introducing
            another:
      
            ```bash
            $ example --one two --three -4
            ```
      
            - Parameters:
              - first: This is a long comment
                that should definitely wrap,
                for a closure with two
                parameters.
                - param1: Hello.
                - param2: Goodbye.
              - second: A short comment.
              - third: This comment has line
                breaks already in it.
            - Throws: An error if something is
              wrong. */
        func foo() {}
      }
      
      """
    assertPrettyPrintEqual(
      input: input, expected: expected, linelength: 40, configuration: config)
  }
}
