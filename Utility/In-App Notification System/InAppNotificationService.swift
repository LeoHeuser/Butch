//
//  InAppNotificationService.swift
//  ButchSDK
//
//  Created by Leo Heuser on 26.01.26.
//

import Foundation

@Observable
class InAppNotificationService {
    
}

/// TODO: Call of In-App Notification
/// You can call the "@Environment(InAppNotificationService.self) var inAppNotification" within every SwiftUI view when the ".environment(inAppNotification)" is deifnied on the root level of the application.
/// The you can just call in any line of the code inAppNotification.send(InAppNotificationObject). This will send  an object to the service and the service will ensire that it is displayed appropiated.
///
/// Definition of the InAppNotificationObject: It has (1) title:LocalizedStringKey, (2) message:LocalizedStringKey?, and (3) systemImage: String?. These are the parameters that the notifacion need so that the notifaction can be displayed.
