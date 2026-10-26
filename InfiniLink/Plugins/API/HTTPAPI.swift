//
//  HTTPAPI.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import Foundation
import JavaScriptCore

@objc protocol HTTPAPIExports: JSExport {
    func request(_ method: String, _ url: String, _ options: JSValue, _ callback: JSValue) -> String?
}

// Matches PinePartner: request(method, url, [options], [callback])
final class HTTPAPI: NSObject, HTTPAPIExports {
    private weak var runner: PluginRunner?
    
    init(runner: PluginRunner) {
        self.runner = runner
    }
    
    func request(_ method: String, _ url: String, _ options: JSValue, _ callback: JSValue) -> String? {
        guard let runner else { return nil }
        guard let url = URL(string: url), url.scheme == "http" || url.scheme == "https" else {
            runner.throwError("Invalid URL \(url)")
            return nil
        }
        
        let isFunction = { (value: JSValue) in value.isObject && value.forProperty("call")?.isUndefined == false }
        let callback = isFunction(options) ? options : callback
        let options = isFunction(options) ? nil : options.toDictionary()
        
        var request = URLRequest(url: url)
        request.httpMethod = method.uppercased()
        request.timeoutInterval = ((options?["timeout"] as? Double) ?? 5000) / 1000
        if let body = options?["body"] {
            request.httpBody = Data("\(body)".utf8)
        }
        for (key, value) in options?["headers"] as? [String: Any] ?? [:] {
            request.setValue("\(value)", forHTTPHeaderField: key)
        }
        
        if isFunction(callback) {
            URLSession.shared.dataTask(with: request) { [weak runner] data, _, error in
                guard let data else {
                    runner?.output(.error, "\(method) \(url) failed: \(error?.localizedDescription ?? "no response")")
                    return
                }
                runner?.perform { _ in
                    callback.call(withArguments: [String(decoding: data, as: UTF8.self)])
                }
            }.resume()
            return nil
        }
        
        // Only blocks this plugin's queue
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<Data, Error>?
        URLSession.shared.dataTask(with: request) { data, _, error in
            result = data.map { .success($0) } ?? .failure(error ?? URLError(.badServerResponse))
            semaphore.signal()
        }.resume()
        semaphore.wait()
        
        switch result {
        case .success(let data):
            return String(decoding: data, as: UTF8.self)
        case .failure(let error):
            runner.throwError("\(method) \(url) failed: \(error.localizedDescription)")
            return nil
        case nil:
            return nil
        }
    }
}
