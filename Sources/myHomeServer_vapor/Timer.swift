//
//  Timer.swift
//  myHomeServer_vapor
//
//  Created by Marek Slaninka on 03.11.16.
//
//

import Dispatch

typealias TimerCallback = (NewTimer) -> Void
class NewTimer {
    var interval: Double
    var handler: TimerCallback
    var repeats: Bool
    private var strand: Strand?
    
    init(interval: Double, handler: @escaping TimerCallback, repeats: Bool = true) {
        self.interval = interval
        self.handler = handler
        self.repeats = repeats
    }
    
    func start() throws {
        strand = try Strand {
            drop.console.print("1", newLine: true)

            while self.repeats {
                // Wait for alloted time
                drop.console.wait(seconds: self.interval)
                drop.console.print("2", newLine: true)

                // Execute on the main thread
                DispatchQueue.global().sync {
                    drop.console.print("3", newLine: true)

                    self.execute()
                }
//                commandQueue.append(self.execute)
            }
        }
    }
    
    func execute() {
        drop.console.print("4", newLine: true)

        handler(self)
    }
    
    func cancel() throws {
        try strand?.cancel()
    }
}
