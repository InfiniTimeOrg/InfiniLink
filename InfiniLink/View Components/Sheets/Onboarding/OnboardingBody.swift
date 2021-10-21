//
//  OnboardingBody.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/15/21.
//  
//
    

import SwiftUI

struct OnboardingBody: View {
	
	var body: some View {
		ScrollView{
			VStack {
				
				Text("Other notes:")
					.font(.title2)
					.padding()
				Text("- Notifications are not currently functional, as this requires the Apple Notification Center Service (ANCS) protocol to be implemented in InfiniTime.")
					.padding()
				Text("- The music controls do work in InfiniTime, but only if you're playing music through the Apple Music app. System-wide music control in iOS requires the proprietary Apple Media Service to be implemented in InfiniTime. At the app level, I can really only interact with Apple Music, and have no control over podcasts, YouTube videos, system volume, etc. until AMS is added to InfiniTime.")
					.padding()
				Text("- Your PineTime is only capable of sustaining one Bluetooth connection at a time. If you're having trouble connecting, please ensure that your PineTime is not already connected to another device, or to another app on this device.")
					.padding()
				Text("- If your PineTime is still not showing up as an available device, please reboot your watch by holding down the side button on your watch until you see the Pine64 pinecone logo in green, and then release. There is currently an issue with Bluetooth advertising in Infinitime that the developers are working extremely hard on. Wish them luck!")
					.padding()
			}
		}
	}
}
