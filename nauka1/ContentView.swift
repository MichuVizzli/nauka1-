import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        if authManager.isLoggedIn {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Główny", systemImage: "house")
                    }
                
                QuotesView()
                    .tabItem {
                        Label("Cytaty", systemImage: "quote.bubble")
                    }
                
                TodoView()
                    .tabItem {
                        Label("To-Do", systemImage: "checklist")
                    }
                
                SavedView()
                    .tabItem {
                        Label("Polubione", systemImage: "heart")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Ustawienia", systemImage: "gear")
                    }
            }
            .accentColor(.white)
        } else {
            LoginView()
        }
    }
}

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        handle = Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.isLoggedIn = user != nil
            }
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
