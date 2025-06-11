import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @State private var userName: String = "Ładowanie..."
    @State private var articles: [Article] = []
    @State private var isLoading: Bool = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        Text("Witaj, \(userName)!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 50)
                            .padding(.trailing, 20)
                    }
                    
                    if isLoading {
                        ProgressView("Ładowanie...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                    } else {
                        ScrollView {
                            VStack(spacing: 15) {
                                if articles.isEmpty {
                                    Text("Brak artykułów")
                                        .foregroundColor(.white)
                                        .padding()
                                } else {
                                    ForEach(articles) { article in
                                        NavigationLink(value: article) {
                                            ArticleCard(article: article, onToggleLike: { toggleLike(for: article.id) })
                                                .padding(.horizontal, 20)
                                        }
                                        .navigationDestination(for: Article.self) { article in
                                            ArticleDetailView(article: article)
                                        }
                                        .onAppear { incrementView(for: article.id) }
                                    }
                                }
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            fetchUserName()
            fetchArticles()
        }
    }
    
    private func fetchUserName() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            print("Brak zalogowanego użytkownika w fetchUserName")
            return
        }
        
        db.collection("users").document(userId).getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Błąd pobierania danych użytkownika: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists, let data = document.data(), let name = data["name"] as? String {
                    self.userName = name
                    print("Pobrano imię: \(name)")
                } else {
                    self.userName = "Nieznany"
                }
            }
        }
    }
    
    private func fetchArticles() {
        db.collection("articles")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        print("Błąd pobierania artykułów: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("Brak dokumentów w kolekcji articles")
                        self.articles = []
                        return
                    }
                    
                    print("Liczba dokumentów: \(documents.count)")
                    self.articles = documents.compactMap { document in
                        let data = document.data()
                        print("Mapuję artykuł \(document.documentID): \(data)")
                        guard let title = data["title"] as? String else {
                            print("Błąd mapowania artykułu \(document.documentID): Brak tytułu")
                            return nil
                        }
                        let description = data["description"] as? String ?? ""
                        let content = data["content"] as? String ?? ""
                        let category = data["category"] as? String ?? "technology"
                        let imageUrl = data["imageUrl"] as? String ?? ""
                        let likesCount = data["likesCount"] as? Int ?? 0
                        let viewsCount = data["viewsCount"] as? Int ?? 0
                        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        
                        let likedBy = data["likedBy"] as? [String] ?? []
                        let isLiked = likedBy.contains(Auth.auth().currentUser?.uid ?? "")
                        print("Artykuł \(document.documentID): likesCount=\(likesCount), isLiked=\(isLiked), viewsCount=\(viewsCount)")
                        
                        return Article(
                            id: document.documentID,
                            title: title,
                            description: description,
                            content: content,
                            category: category,
                            imageUrl: imageUrl,
                            likesCount: likesCount,
                            viewsCount: viewsCount,
                            isLiked: isLiked,
                            createdAt: createdAt
                        )
                    }
                    
                    print("Pobrano \(self.articles.count) artykułów: \(self.articles.map { $0.title })")
                }
            }
    }
    
    private func toggleLike(for articleId: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Brak zalogowanego użytkownika w toggleLike")
            return
        }
        
        let articleRef = db.collection("articles").document(articleId)
        
        // Inicjalizacja likedBy i likesCount, jeśli nie istnieją
        articleRef.getDocument { document, error in
            if let error = error {
                print("Błąd pobierania dokumentu artykułu \(articleId): \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("Dokument artykułu \(articleId) nie istnieje")
                return
            }
            
            let data = document.data()
            if data?["likedBy"] == nil || data?["likesCount"] == nil {
                articleRef.setData(["likedBy": [], "likesCount": 0], merge: true) { error in
                    if let error = error {
                        print("Błąd inicjalizacji likedBy/likesCount dla artykułu \(articleId): \(error.localizedDescription)")
                    } else {
                        print("Zainicjalizowano likedBy/likesCount dla artykułu \(articleId)")
                    }
                }
            }
            
            // Transakcja aktualizacji
            self.db.runTransaction { transaction, errorPointer in
                let articleDocument: DocumentSnapshot
                do {
                    try articleDocument = transaction.getDocument(articleRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    print("Błąd pobierania dokumentu w transakcji dla artykułu \(articleId): \(error.localizedDescription)")
                    return nil
                }
                
                var likedBy = articleDocument.data()?["likedBy"] as? [String] ?? []
                var likesCount = articleDocument.data()?["likesCount"] as? Int ?? 0
                print("Przed aktualizacją: likesCount=\(likesCount), likedBy=\(likedBy)")
                
                if likedBy.contains(userId) {
                    likedBy.removeAll { $0 == userId }
                    likesCount = max(0, likesCount - 1)
                    print("Usunięto polubienie dla artykułu \(articleId)")
                } else {
                    likedBy.append(userId)
                    likesCount += 1
                    print("Dodano polubienie dla artykułu \(articleId)")
                }
                
                transaction.updateData(["likedBy": likedBy, "likesCount": likesCount], forDocument: articleRef)
                print("Po aktualizacji: likesCount=\(likesCount), likedBy=\(likedBy)")
                return nil
            } completion: { _, error in
                if let error = error {
                    print("Błąd transakcji polubienia dla artykułu \(articleId): \(error.localizedDescription)")
                } else {
                    print("Transakcja polubienia dla artykułu \(articleId) zakończona sukcesem")
                }
            }
        }
    }
    
    private func incrementView(for articleId: String) {
        let articleRef = db.collection("articles").document(articleId)
        
        articleRef.getDocument { document, error in
            if let error = error {
                print("Błąd pobierania dokumentu artykułu \(articleId): \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("Dokument artykułu \(articleId) nie istnieje")
                return
            }
            
            if document.data()?["viewsCount"] == nil {
                articleRef.setData(["viewsCount": 0], merge: true) { error in
                    if let error = error {
                        print("Błąd inicjalizacji viewsCount dla artykułu \(articleId): \(error.localizedDescription)")
                    } else {
                        print("Zainicjalizowano viewsCount dla artykułu \(articleId)")
                    }
                }
            }
            
            articleRef.updateData(["viewsCount": FieldValue.increment(Int64(1))]) { error in
                if let error = error {
                    print("Błąd zwiększania wyświetleń dla artykułu \(articleId): \(error.localizedDescription)")
                } else {
                    print("Zwiększono wyświetlenia dla artykułu \(articleId)")
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
