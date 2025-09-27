import WatchKit
import SwiftUI
import UserNotifications

struct NotificationView: View {
    var title: String
    var message: String

    init(title: String = "Ana", message: String = "Keep moving to stay on pace.") {
        self.title = title
        self.message = message
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.footnote)
        }
        .padding()
    }
}

final class NotificationController: WKUserNotificationHostingController<NotificationView> {
    private var currentMessage = NotificationView()

    override var body: NotificationView {
        currentMessage
    }

    override func didReceive(_ notification: UNNotification) {
        currentMessage = NotificationView(
            title: notification.request.content.title.isEmpty ? "Ana" : notification.request.content.title,
            message: notification.request.content.body
        )
    }
}
