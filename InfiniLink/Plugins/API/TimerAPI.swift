//
//  TimerAPI.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import Foundation
import JavaScriptCore

extension PluginRunner {
    func installTimers(in context: JSContext) {
        let setInterval: @convention(block) (JSValue, Double) -> Int = { [weak self] callback, ms in
            self?.schedule(callback, ms: ms, repeats: true) ?? 0
        }
        let setTimeout: @convention(block) (JSValue, Double) -> Int = { [weak self] callback, ms in
            self?.schedule(callback, ms: ms.isNaN ? 0 : ms, repeats: false) ?? 0
        }
        let clear: @convention(block) (Int) -> Void = { [weak self] id in
            self?.timers.removeValue(forKey: id)?.cancel()
        }
        
        let timer = JSValue(newObjectIn: context)
        timer?.setObject(unsafeBitCast(setInterval, to: AnyObject.self), forKeyedSubscript: "setInterval" as NSString)
        timer?.setObject(unsafeBitCast(setTimeout, to: AnyObject.self), forKeyedSubscript: "setTimeout" as NSString)
        timer?.setObject(unsafeBitCast(clear, to: AnyObject.self), forKeyedSubscript: "clear" as NSString)
        context.setObject(timer, forKeyedSubscript: "timer" as NSString)
        
        // Browser-style globals, so outside code works as-is
        context.evaluateScript("var setTimeout = timer.setTimeout, setInterval = timer.setInterval, clearTimeout = timer.clear, clearInterval = timer.clear;")
    }
    
    private func schedule(_ callback: JSValue, ms: Double, repeats: Bool) -> Int {
        guard callback.isObject else {
            throwError("Timer callback must be a function")
            return 0
        }
        guard repeats ? ms >= 100 : ms >= 0 else {
            throwError(repeats ? "Interval must be at least 100 ms" : "Delay can't be negative")
            return 0
        }
        
        nextTimerID += 1
        let id = nextTimerID
        let interval = DispatchTimeInterval.milliseconds(Int(ms))
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + interval, repeating: repeats ? interval : .never)
        timer.setEventHandler { [weak self] in
            if !repeats {
                self?.timers.removeValue(forKey: id)
            }
            callback.call(withArguments: [])
        }
        timers[id] = timer
        timer.resume()
        
        return id
    }
}
