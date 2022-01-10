//
//  DownloadManager.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/26/21.
//  
//
    

import Foundation
import NordicDFU

class DownloadManager: NSObject, ObservableObject {
	static var shared = DownloadManager()

	@Published var tasks: [URLSessionTask] = []
	@Published var results: [Result] = []
	@Published var downloading = false
	@Published var updateAvailable = false
	@Published var autoUpgrade: Result!
	@Published var lastCheck: Date!
	
	private lazy var urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
	private var downloadTask: URLSessionDownloadTask!
	
	struct Asset: Codable {
		let id: Int
		let name: String
		let browser_download_url: URL
	}
	
	struct Result: Codable {
		let tag_name: String
		let assets: [Asset]
		var zipAsset: Asset!
		
		private enum CodingKeys: String, CodingKey {
			case tag_name, assets
		}
	}
	
	func checkForUpdates() -> Bool {
		for i in results {
			if i.tag_name.first != "v" {
				let comparison = BLEDeviceInfo.shared.firmware.compare(i.tag_name, options: .numeric)
				if comparison == .orderedAscending {
					updateAvailable = true
					autoUpgrade = i
					return true
				}
			}
		}
		return false
	}
	
	func getDownloadUrls() {
		results = []
		guard let url = URL(string: "https://api.github.com/repos/InfiniTimeOrg/InfiniTime/releases") else {
			return
		}
		URLSession.shared.dataTask(with: url) { data, response, error in
			if let data = data {
				do {
					let res = try JSONDecoder().decode([Result].self, from: data)
					DispatchQueue.main.async {
						for i in res {
							if i.tag_name.first != "v" {
								if UserDefaults.standard.value(forKey: "showNewDownloadsOnly") as? Bool ?? true {
									let comparison = BLEDeviceInfo.shared.firmware.compare(i.tag_name, options: .numeric)
									if comparison == .orderedAscending || comparison == .orderedSame {
										self.results.append(i)
									}
								} else {
									self.results.append(i)
								}
							}
						}
					}
				} catch {
					DebugLogManager.shared.debug(error: "JSON Decoding Error: \(error)", log: .app, date: Date())
				}
			}
		}.resume()
	}
	
	func chooseAsset(response: Result) -> Asset {
		// for now, I'm pulling the .zip file from the releases. This is not guaranteed to be successful (ie if there's more than one zip file in the release), but it's a start
		for x in response.assets {
			if x.name.suffix(4) == ".zip" {
				return x
			}
		}
		return Asset(id: Int(), name: String(), browser_download_url: URL(fileURLWithPath: ""))
	}

	func startDownload(url: URL) {
		self.downloading = true
		let downloadTask = urlSession.downloadTask(with: url)
		downloadTask.resume()
		self.downloadTask = downloadTask
	}

	private func updateTasks() {
		urlSession.getAllTasks { tasks in
			DispatchQueue.main.async {
				self.tasks = tasks
			}
		}
	}
}

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
	func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten _: Int64, totalBytesExpectedToWrite _: Int64) {
	}
	
	func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		do {
			
			let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
			let savedURL = documentsURL.appendingPathComponent(
				"firmware.zip")
			
			// check for existing file and delete it if there is anything.
			if FileManager.default.fileExists(atPath: savedURL.path) {
				try? FileManager.default.removeItem(at: savedURL)
			}
			
			// move downloaded file out of ephemeral storage and tell DFU where to look
			try FileManager.default.moveItem(at: location, to: savedURL)
			DFU_Updater.shared.firmwareURL = savedURL
			
			} catch let fmerror {
				DebugLogManager.shared.debug(error: "Error saving downloaded firmware file: \(fmerror)", log: .app, date: Date())
				// handle filesystem error
			}
		DispatchQueue.main.async {
			self.downloading = false
		}
	}
	
	func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let error = error {
			DebugLogManager.shared.debug(error: "Download error: \(String(describing: error))", log: .app, date: Date())
		}
	}
}
