import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text(article.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    Text(article.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 20)
                    
                    if !article.content.isEmpty {
                        Text(article.content)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                    } else {
                        Text("Brak treści artykułu")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Szczegóły artykułu")
    }
}

struct ArticleDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleDetailView(
            article: Article(
                id: "test",
                title: "Testowy artykuł",
                description: "Krótki opis artykułu, który pokazuje się w kafelku.",
                content: "Pełna treść artykułu, widoczna tylko w widoku szczegółów.",
                category: "technology",
                imageUrl: "",
                likesCount: 0,
                viewsCount: 0,
                isLiked: false,
                createdAt: Date()
            )
        )
    }
}
