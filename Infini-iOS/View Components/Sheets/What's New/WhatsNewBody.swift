//
//  WhatsNewBody090.swift
//  Infini-iOS
//
//  Created by Alex Emry on 9/28/21.
//  
//
    

import SwiftUI

struct WhatsNewBody: View {
	
	var body: some View {
		ScrollView{
				Text("UI Changes")
					.font(.title2)
					.padding()
				Text("Tons of UI changes: New 'Home' view features some stats about your watch and the connect/disconnect button. DFU page was cleaned up a little. Color scheme changes were made to improve clarity for light mode users.")
					.padding()
				Text("Chart Persistence")
					.font(.title2)
					.padding()
				Text("Infini-iOS is now capable of saving chart data as it is generated, and chart data can now be filtered by time. I've set the watch to prune data older than a week for now, but am open to suggestions!")
				Text("Device Naming")
					.font(.title2)
					.padding()
				Text("Devices can now be named in Infini-iOS! While this name has no effect on the watch, setting a name for the device in Infini-iOS associates the UUID of the watch with the new name. Any time this watch would appear on screen (Home screen, Connect screen, etc), your chosen name will display instead of 'InfiniTime'. Hopefully this will be helpful for those of you that have more than one watch!")
					.padding()
				Text("Arbitrary Notifications")
					.font(.title2)
					.padding()
				Text("Now you can send arbitrary notifications to your PineTime from the Settings Menu. Have a short list of stuff to get at the store? Send the list as a notification and it will be on your wrist as you shop!")
					.padding()
				Text("Firmware Updates")
					.font(.title2)
					.padding()
				Text("Updated DFU process: DFU downloads are now available! Now, when you tap the 'Select Firmware File' button, you're given the option to select a local file or download a firmware file. Tapping the download button uses the GitHub API to bring up a list of firmware files available on GitHub. Selecting a file from that list will download it and prepare it for flashing. After flashing, the file is deleted. Also, when a watch is connected, Infini-iOS will compare the firmware version number on the watch to this list, and notify you of any updates on the Home screen.")
					.padding()
		}
	}
}

