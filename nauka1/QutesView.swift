import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct QuotesView: View {
    @State private var quotes: [Quote] = []
    @State private var newQuoteContent: String = ""
    @State private var newQuoteAuthor: String = ""
    @State private var isLoading: Bool = false // Domyślnie false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Cytaty")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                // Formularz dodawania cytatu
                VStack(spacing: 10) {
                    TextField("Treść cytatu", text: $newQuoteContent)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                    
                    TextField("Autor", text: $newQuoteAuthor)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                    
                    Button(action: {
                        Task {
                            await addQuote()
                        }
                    }) {
                        HStack {
                            Text("Dodaj cytat")
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
                    .disabled(isLoading || newQuoteContent.isEmpty || newQuoteAuthor.isEmpty)
                    .opacity((newQuoteContent.isEmpty || newQuoteAuthor.isEmpty) ? 0.6 : 1.0)
                }
                
                // Lista cytatów
                ScrollView {
                    VStack(spacing: 15) {
                        if quotes.isEmpty && !isLoading {
                            Text("Brak cytatów")
                                .foregroundColor(.white)
                                .padding()
                        } else if isLoading {
                            ProgressView("Ładowanie...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .foregroundColor(.white)
                        } else {
                            ForEach(quotes) { quote in
                                QuoteCard(quote: quote)
                                    .padding(.horizontal, 20)
                                    .transition(.slide)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                Spacer()
            }
        }
        .onAppear {
            Task {
                await setupSnapshotListener()
            }
        }
    }
    
    private func setupSnapshotListener() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Brak zalogowanego użytkownika w setupSnapshotListener")
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        print("Pobieram cytaty dla userId: \(userId)")
        db.collection("quotes")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        print("Błąd pobierania cytatów: \(error.localizedDescription)")
                        return
                    }
                    
                    self.quotes = snapshot?.documents.compactMap { document in
                        let data = document.data()
                        print("Mapuję cytat \(document.documentID): \(data)") // Debugowanie danych
                        guard let content = data["content"] as? String,
                              let author = data["author"] as? String,
                              let userId = data["userId"] as? String,
                              let createdAt = data["createdAt"] as? Timestamp else {
                            print("Błąd mapowania cytatu \(document.documentID): Brak wymaganych pól")
                            return nil
                        }
                        
                        return Quote(
                            id: document.documentID,
                            content: content,
                            author: author,
                            userId: userId,
                            createdAt: createdAt.dateValue()
                        )
                    } ?? []
                    
                    print("Pobrano \(self.quotes.count) cytatów: \(self.quotes.map { $0.content })")
                }
            }
    }
    
    private func addQuote() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Brak zalogowanego użytkownika w addQuote")
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        let quoteData: [String: Any] = [
            "content": newQuoteContent,
            "author": newQuoteAuthor,
            "userId": userId,
            "createdAt": Timestamp()
        ]
        
        print("Dodaję cytat: \(newQuoteContent) by \(newQuoteAuthor)")
        do {
            _ = try await db.collection("quotes").addDocument(data: quoteData)
            DispatchQueue.main.async {
                self.isLoading = false
                self.newQuoteContent = ""
                self.newQuoteAuthor = ""
                print("Dodano cytat: \(quoteData)")
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                print("Błąd dodawania cytatu: \(error.localizedDescription)")
            }
        }
    }
}

struct QuotesView_Previews: PreviewProvider {
    static var previews: some View {
        QuotesView()
    }
}
