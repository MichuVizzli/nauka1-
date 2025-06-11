import Firebase
import SwiftUI

@main
struct SwiftUIFirebaseExampleApp: App {
    init () {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
