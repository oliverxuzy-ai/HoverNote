import XCTest
@testable import SideNote

/// M0 canary tests.
/// Real tests start arriving in M2 (NoteStore + FrontmatterCodec).
final class SideNoteTests: XCTestCase {

    /// If this test runs, the test target compiled and linked against SideNote.
    /// That alone is the M0 canary signal.
    func testCanaryBuild() throws {
        XCTAssertTrue(true, "side-note built and linked. M0 OK.")
    }
}
