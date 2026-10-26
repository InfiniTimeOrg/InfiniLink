//
//  ConsoleAPI.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import Foundation
import JavaScriptCore

extension PluginRunner {
    func installConsole(in context: JSContext) {
        let write: @convention(block) (Int, String) -> Void = { [weak self] level, message in
            self?.output(level == 0 ? .info : .error, message)
        }
        
        let console = context.evaluateScript("""
        (function (write) {
            const format = args => args.map(arg => {
                if (typeof arg !== "object" || arg === null) return String(arg);
                try { return JSON.stringify(arg); } catch { return String(arg); }
            }).join(" ");
            
            return {
                log: (...args) => write(0, format(args)),
                info: (...args) => write(0, format(args)),
                warn: (...args) => write(1, format(args)),
                error: (...args) => write(2, format(args))
            };
        })
        """)?.call(withArguments: [unsafeBitCast(write, to: AnyObject.self)])
        
        context.setObject(console, forKeyedSubscript: "console" as NSString)
    }
}
