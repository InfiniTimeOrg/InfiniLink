//
//  WhatsNewBody090.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/28/21.
//  
//
    

import SwiftUI

struct WhatsNewBody: View {
	
	var body: some View {
		ScrollView{
			Text("Step Counter:\n- InfiniTime 1.7.0 introduces a long-awaited feature: step count transmission to companion apps. This version of InfiniLink is set up to receive those values! I have created a pretty rudimentary UI for interpreting these values, which includes:\n- Current value: a circular guage that fills as you approach your step goal\n- Weekly value: a bar chart with the step values you've achieved for each day this week\n- A calendar view, which features the same circular guage around each day around each day of the month, for more long-term step tracking")
				.padding()
			Text("Improved Apple Music Functionality:\n- Big thanks to @WowieMan on Github for this!\n- Current time and total run time the currently playing track is shown on InfiniTime now\n- Play/pause state is reflected on InfiniTime\n- Volume buttons in InfiniTime work now.\n- *Please note that this still only applies to Apple Music for now.*")
				.padding()
			Text("New Logo:\n- Again, big thanks to @WowieMan for the new logo! This logo was submitted a long time ago, and I kept meaning to add it before submitting releases to TestFlight, and then forgetting. ")
				.padding()
		}
	}
}

