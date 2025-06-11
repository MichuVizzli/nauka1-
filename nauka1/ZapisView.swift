import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SavedView: View {
    @State private var likedArticles: [Article] = []
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
                    Text("Polubione posty")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
                    if isLoading {
                        ProgressView("Ładowanie...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                    } else {
                        ScrollView {
                            VStack(spacing: 15) {
                                if likedArticles.isEmpty {
                                    Text("Brak polubionych postów")
                                        .foregroundColor(.white)
                                        .padding()
                                } else {
                                    ForEach(likedArticles) { article in
                                        NavigationLink(value: article) {
                                            ArticleCard(article: article, onToggleLike: { toggleLike(for: article.id) })
                                                .padding(.horizontal, 20)
                                        }
                                        .navigationDestination(for: Article.self) { article in
                                            ArticleDetailView(article: article)
                                        }
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
            fetchLikedArticles()
        }
    }
    
    private func fetchLikedArticles() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            print("Brak zalogowanego użytkownika w fetchLikedArticles")
            return
        }
        
        print("Pobieram polubione artykuły dla userId: \(userId)")
        db.collection("articles")
            .whereField("likedBy", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        print("Błąd pobierania polubionych postów: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("Brak dokumentów w kolekcji articles dla likedBy")
                        self.likedArticles = []
                        return
                    }
                    
                    print("Liczba dokumentów: \(documents.count)")
                    self.likedArticles = documents.compactMap { document in
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
                        let isLiked = likedBy.contains(userId)
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
                    
                    print("Pobrano \(self.likedArticles.count) polubionych artykułów: \(self.likedArticles.map { $0.title })")
                }
            }
    }
    
    private func toggleLike(for articleId: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Brak zalogowanego użytkownika w toggleLike")
            return
        }
        
        let articleRef = db.collection("articles").document(articleId)
        
        // Najpierw upewniamy się, że dokument ma pole likedBy
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
            let likedBy = data?["likedBy"] as? [String] ?? []
            
            // Jeśli likedBy nie istnieje, zainicjalizuj je
            if data?["likedBy"] == nil {
                articleRef.setData(["likedBy": []], merge: true) { error in
                    if let error = error {
                        print("Błąd inicjalizacji likedBy dla artykułu \(articleId): \(error.localizedDescription)")
                    } else {
                        print("Zainicjalizowano likedBy dla artykułu \(articleId)")
                    }
                }
            }
            
            // Wykonaj transakcję
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
}

struct SavedView_Previews: PreviewProvider {
    static var previews: some View {
        SavedView()
    }
}
