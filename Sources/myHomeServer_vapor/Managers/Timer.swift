import Strand

typealias TimerCallback = (Timer) -> Void
class Timerer {
	var interval: Double
	var handler: TimerCallback
	var repeats: Bool
	private var strand: Strand?
	
	init(interval: Double, handler: TimerCallback, repeats: Bool = true) {
		self.interval = interval
		self.handler = handler
		self.repeats = repeats
	}
	
	func start() throws {
		strand = try Strand {
			while self.repeats {
				// Wait for alloted time
				drop.console.wait(seconds: self.interval)
				
				// Execute on the main thread
				commandQueue.append(self.execute)
			}
		}
	}
	
	func execute() {
		handler(self)
	}
	
	func cancel() throws {
		try strand?.cancel()
	}
}
