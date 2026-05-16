import XCTest
import AppKit
import HotKey
@testable import SideNote

/// Locks down the four features layered on the M0–M4 baseline:
/// live-edit rendering gaps, configurable reveal hotkey, slash menu, and the
/// VERSION/project.yml sync. See `TEST_PLAN.md` for the coverage matrix.
final class FeatureTests: XCTestCase {

    // MARK: - Helpers

    private func newCoordinator() -> LiveMarkdownEditor.Coordinator {
        LiveMarkdownEditor(text: .constant("")).makeCoordinator()
    }

    private func highlighted(_ s: String) -> NSTextStorage {
        let storage = NSTextStorage(string: s)
        newCoordinator().highlight(storage)
        return storage
    }

    private func attr(_ s: NSTextStorage, _ k: NSAttributedString.Key, at i: Int) -> Any? {
        s.attribute(k, at: i, effectiveRange: nil)
    }

    // MARK: - Live-edit · ordered list regex

    func testOrderedListRegex() {
        let re = LiveMarkdownEditor.Coordinator.ordered
        func m(_ s: String) -> Bool {
            re.firstMatch(in: s, range: NSRange(location: 0, length: (s as NSString).length)) != nil
        }
        XCTAssertTrue(m("1. first"))
        XCTAssertTrue(m("10. tenth"))
        XCTAssertTrue(m("  3. nested"))
        XCTAssertFalse(m("1.no space"))
        XCTAssertFalse(m("1) paren"))
        XCTAssertFalse(m("see 1. mid line"))

        let ns = "  7. x" as NSString
        let mm = re.firstMatch(in: ns as String, range: NSRange(location: 0, length: ns.length))!
        XCTAssertEqual(ns.substring(with: mm.range(at: 1)), "  ", "group1 = leading whitespace")
    }

    // MARK: - Live-edit · highlight() attribute pass

    func testHighlightMarksCodeBlock() {
        let s = highlighted("```\nlet x = 1\n```")
        XCTAssertNotNil(attr(s, .snCodeBlock, at: 0), "opening fence marked")
        let mid = (s.string as NSString).range(of: "let").location
        XCTAssertNotNil(attr(s, .snCodeBlock, at: mid), "fenced body marked")
    }

    func testHighlightMarksQuote() {
        let s = highlighted("> a calm quote")
        XCTAssertNotNil(attr(s, .snQuote, at: 0))
        let ps = attr(s, .paragraphStyle, at: 0) as? NSParagraphStyle
        XCTAssertEqual(ps?.firstLineHeadIndent, 12)
        XCTAssertEqual(ps?.headIndent, 12)
    }

    func testHighlightHangsLists() {
        for line in ["- bullet item", "1. ordered item", "- [ ] a task"] {
            let s = highlighted(line)
            let ps = attr(s, .paragraphStyle, at: (line as NSString).length - 1) as? NSParagraphStyle
            XCTAssertNotNil(ps, "\(line): expected a hanging paragraph style")
            XCTAssertGreaterThan(ps!.headIndent, ps!.firstLineHeadIndent,
                                 "\(line): wrapped lines must hang past the marker")
        }
    }

    func testHighlightTaskCheckboxAttr() {
        let open = highlighted("- [ ] todo")
        let openBox = (open.string as NSString).range(of: "[ ]").location
        XCTAssertEqual(attr(open, .snCheckbox, at: openBox) as? Bool, false)

        let done = highlighted("- [x] todo")
        let doneBox = (done.string as NSString).range(of: "[x]").location
        XCTAssertEqual(attr(done, .snCheckbox, at: doneBox) as? Bool, true)
        let content = (done.string as NSString).range(of: "todo").location
        XCTAssertNotNil(attr(done, .strikethroughStyle, at: content),
                        "checked task body struck through")
    }

    func testHighlightInlineCodeBackground() {
        let s = highlighted("use `swift` now")
        let inside = (s.string as NSString).range(of: "swift").location
        XCTAssertNotNil(attr(s, .backgroundColor, at: inside),
                        "inline code gets a wash background")
    }

    // MARK: - Slash menu · model

    func testSlashFilterMatchesTitleAndKeywords() {
        XCTAssertEqual(SlashCommand.filtered("").count, SlashCommand.all.count)
        XCTAssertTrue(SlashCommand.filtered("todo").contains { $0.title == "To-do" })
        XCTAssertTrue(SlashCommand.filtered("h1").contains { $0.title == "Heading 1" })
        XCTAssertTrue(SlashCommand.filtered("NUM").contains { $0.title == "Numbered list" })
        XCTAssertTrue(SlashCommand.filtered("zzz").isEmpty)
    }

    func testSlashCommandSnippetsWellFormed() {
        var titles = Set<String>()
        for c in SlashCommand.all {
            XCTAssertFalse(c.snippet.isEmpty, "\(c.title): empty snippet")
            XCTAssertGreaterThanOrEqual(c.caretOffset, 0)
            XCTAssertLessThanOrEqual(c.caretOffset, c.snippet.count, "\(c.title): caret OOB")
            XCTAssertTrue(titles.insert(c.title).inserted, "duplicate title \(c.title)")
        }
        let code = SlashCommand.all.first { $0.title == "Code block" }!
        let idx = code.snippet.index(code.snippet.startIndex, offsetBy: code.caretOffset)
        XCTAssertEqual(String(code.snippet[..<idx]), "```\n",
                       "code-block caret lands on the empty middle line")
    }

    func testSlashTriggerRegex() {
        let re = SlashMenuController.trigger
        func fires(_ s: String) -> Bool {
            re.firstMatch(in: s, range: NSRange(location: 0, length: (s as NSString).length)) != nil
        }
        XCTAssertTrue(fires("/"))
        XCTAssertTrue(fires("/bul"))
        XCTAssertTrue(fires("text /quote"))
        XCTAssertFalse(fires("http://x"), "slash not at line start / after space")
        XCTAssertFalse(fires("/bul more"), "token broken by space → not at caret end")
    }

    // MARK: - Reveal hotkey · persistence

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: RevealHotkey.defaultsKey)
        super.tearDown()
    }

    func testRevealHotkeyDefault() {
        UserDefaults.standard.removeObject(forKey: RevealHotkey.defaultsKey)
        XCTAssertEqual(RevealHotkey.load().carbonKeyCode, UInt32(49))   // kVK_Space
        XCTAssertEqual(RevealHotkey.displayString, "⌃⇧␣")
    }

    func testRevealHotkeySaveLoadReset() {
        let combo = KeyCombo(key: .n, modifiers: [.command, .option])
        var posted = false
        let obs = NotificationCenter.default.addObserver(
            forName: RevealHotkey.didChange, object: nil, queue: nil) { _ in posted = true }
        defer { NotificationCenter.default.removeObserver(obs) }

        RevealHotkey.save(combo)
        XCTAssertTrue(posted, "save posts didChange so HotkeyService rebinds")

        let loaded = RevealHotkey.load()
        XCTAssertEqual(loaded.carbonKeyCode, combo.carbonKeyCode)
        XCTAssertEqual(loaded.carbonModifiers, combo.carbonModifiers)

        RevealHotkey.reset()
        XCTAssertEqual(RevealHotkey.load().carbonKeyCode, UInt32(49))
    }

    // MARK: - Version tooling

    func testVersionFileIsSemver() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()      // SideNoteTests/
            .deletingLastPathComponent()      // repo root
        let version = try String(
            contentsOf: root.appendingPathComponent("VERSION"), encoding: .utf8
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        XCTAssertNotNil(version.range(of: #"^\d+\.\d+\.\d+$"#, options: .regularExpression),
                        "VERSION must be X.Y.Z, got \(version)")
        let yml = try String(
            contentsOf: root.appendingPathComponent("project.yml"), encoding: .utf8
        )
        XCTAssertTrue(yml.contains("MARKETING_VERSION: \"\(version)\""),
                      "project.yml MARKETING_VERSION out of sync with VERSION")
    }
}
