import Testing
@testable import Codax

@MainActor
struct CodaxPaneModelTests {
	@Test func contentViewModelStoresLocalDraftStateOnly() {
		let vm = ContentViewModel()
		#expect(vm.turnInput.isEmpty)
		vm.turnInput = "Ship it"
		#expect(vm.turnInput == "Ship it")
	}
}
