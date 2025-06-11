import SwiftUI

// Model artykułu
struct Article: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let content: String
    let category: String
    let imageUrl: String?
    let likesCount: Int
    let viewsCount: Int
    let isLiked: Bool
    let createdAt: Date
    
    // Implementacja Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Article, rhs: Article) -> Bool {
        lhs.id == rhs.id
    }
}

// Model cytatu
struct Quote: Identifiable {
    let id: String
    let content: String
    let author: String
    let userId: String
    let createdAt: Date
}

// Model zadania
struct Todo: Identifiable {
    let id: String
    let title: String
    let isCompleted: Bool
    let userId: String
    let createdAt: Date
}

// Komponent karty artykułu
struct ArticleCard: View {
    let article: Article
    let onToggleLike: () -> Void
    @State private var isTapped: Bool = false // Stan dla animacji
    
    private var categoryColor: Color {
        switch article.category {
        case "technology": return .blue.opacity(0.2)
        case "lifestyle": return .green.opacity(0.2)
        case "news": return .red.opacity(0.2)
        default: return .gray.opacity(0.2)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pomijamy sekcję zdjęcia, jeśli imageUrl jest nil lub pusty
            if let imageUrl = article.imageUrl, !imageUrl.isEmpty {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .overlay(Text("Zdjęcie (placeholder)")) // Placeholder, jeśli obrazek nie jest ładowany
                    .cornerRadius(10)
            }
            
            Text(article.title)
                .font(.headline)
                .foregroundColor(.black)
            
            Text(article.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isTapped = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isTapped = false
                    }
                    onToggleLike()
                }) {
                    Image(systemName: article.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(article.isLiked ? .red : .gray)
                        .scaleEffect(isTapped ? 1.2 : 1.0) // Animacja skalowania
                }
                
                Text("\(article.likesCount)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Image(systemName: "eye")
                    .foregroundColor(.gray)
                
                Text("\(article.viewsCount)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(categoryColor)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

// Komponent karty cytatu
struct QuoteCard: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(quote.content)
                .font(.body)
                .foregroundColor(.black)
                .padding(.bottom, 5)
            
            Text("— \(quote.author)")
                .font(.caption)
                .foregroundColor(.gray)
                .italic()
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

// Komponent karty zadania
struct TodoCard: View {
    let todo: Todo
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggleCompletion) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : .gray)
            }
            
            Text(todo.title)
                .font(.body)
                .foregroundColor(.black)
                .strikethrough(todo.isCompleted)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
