import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var name: String = ""
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Zarejestruj się")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
                    TextField("Imię", text: $name)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding(.horizontal, 30)
                    
                    ZStack(alignment: .trailing) {
                        Group {
                            if showPassword {
                                TextField("Hasło", text: $password)
                            } else {
                                SecureField("Hasło", text: $password)
                            }
                        }
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                                .padding(.trailing, 40)
                        }
                    }
                    
                    SecureField("Potwierdź hasło", text: $confirmPassword)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 30)
                    }
                    
                    Button(action: {
                        signUp()
                    }) {
                        HStack {
                            Text("Zarejestruj")
                                .fontWeight(.semibold)
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.leading, 10)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    
                    NavigationLink("Masz już konto? Zaloguj się", destination: LoginView())
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                    
                    Spacer()
                }
            }
            .animation(.easeInOut, value: showPassword)
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !name.isEmpty &&
        password == confirmPassword &&
        email.contains("@") &&
        password.count >= 6
    }
    
    private func signUp() {
        guard isFormValid else {
            errorMessage = "Proszę wypełnić poprawnie formularz"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    print("Błąd rejestracji: \(error.localizedDescription)")
                    return
                }
                
                guard let user = result?.user else {
                    isLoading = false
                    errorMessage = "Nie udało się utworzyć użytkownika"
                    return
                }
                
                // Zapis danych użytkownika w Firestore
                let userData: [String: Any] = [
                    "name": name,
                    "email": email,
                    "createdAt": Timestamp()
                ]
                
                db.collection("users").document(user.uid).setData(userData) { error in
                    DispatchQueue.main.async {
                        isLoading = false
                        if let error = error {
                            errorMessage = "Błąd zapisu danych: \(error.localizedDescription)"
                            print("Błąd zapisu w Firestore: \(error.localizedDescription)")
                            return
                        }
                        
                        print("Zarejestrowano i zapisano dane użytkownika: \(email), UID: \(user.uid)")
                    }
                    }
                }
            }
        }
    }

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
