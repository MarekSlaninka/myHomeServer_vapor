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
            if self.repeats {
                while self.repeats {
                    // Wait for alloted time
                    drop.console.wait(seconds: self.interval)
                    // Execute on the main thread
                    DispatchQueue.global().sync {
                        self.execute()
                    }
                }
            } else {
                drop.console.wait(seconds: self.interval)
                // Execute on the main thread
                DispatchQueue.global().sync {
                    self.execute()
                }
                
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
