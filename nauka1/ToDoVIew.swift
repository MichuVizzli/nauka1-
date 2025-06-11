import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TodoView: View {
    @State private var todos: [Todo] = []
    @State private var newTodoTitle: String = ""
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
                Text("Lista do wykonania")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                // Formularz dodawania zadania
                HStack {
                    TextField("Nowe zadanie", text: $newTodoTitle)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                    
                    Button(action: {
                        Task {
                            await addTodo()
                        }
                    }) {
                        Text("Dodaj")
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(isLoading || newTodoTitle.isEmpty)
                    .opacity(newTodoTitle.isEmpty ? 0.6 : 1.0)
                }
                .padding(.horizontal, 30)
                
                // Lista zadań
                ScrollView {
                    VStack(spacing: 15) {
                        if todos.isEmpty && !isLoading {
                            Text("Brak zadań")
                                .foregroundColor(.white)
                                .padding()
                        } else if isLoading {
                            ProgressView("Ładowanie...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .foregroundColor(.white)
                        } else {
                            ForEach(todos) { todo in
                                TodoCard(
                                    todo: todo,
                                    onToggleCompletion: { toggleCompletion(for: todo.id, isCompleted: !todo.isCompleted) },
                                    onDelete: { deleteTodo(for: todo.id) }
                                )
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
        
        print("Pobieram zadania dla userId: \(userId)")
        db.collection("todos")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        print("Błąd pobierania zadań: \(error.localizedDescription)")
                        return
                    }
                    
                    self.todos = snapshot?.documents.compactMap { document in
                        let data = document.data()
                        print("Mapuję zadanie \(document.documentID): \(data)") // Debugowanie danych
                        guard let title = data["title"] as? String,
                              let isCompleted = data["isCompleted"] as? Bool,
                              let userId = data["userId"] as? String,
                              let createdAt = data["createdAt"] as? Timestamp else {
                            print("Błąd mapowania zadania \(document.documentID): Brak wymaganych pól")
                            return nil
                        }
                        
                        return Todo(
                            id: document.documentID,
                            title: title,
                            isCompleted: isCompleted,
                            userId: userId,
                            createdAt: createdAt.dateValue()
                        )
                    } ?? []
                    
                    print("Pobrano \(self.todos.count) zadań: \(self.todos.map { $0.title })")
                }
            }
    }
    
    private func addTodo() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Brak zalogowanego użytkownika w addTodo")
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        let todoData: [String: Any] = [
            "title": newTodoTitle,
            "isCompleted": false,
            "userId": userId,
            "createdAt": Timestamp()
        ]
        
        print("Dodaję zadanie: \(newTodoTitle)")
        do {
            _ = try await db.collection("todos").addDocument(data: todoData)
            DispatchQueue.main.async {
                self.isLoading = false
                self.newTodoTitle = ""
                print("Dodano zadanie: \(todoData)")
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                print("Błąd dodawania zadania: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleCompletion(for todoId: String, isCompleted: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Brak zalogowanego użytkownika w toggleCompletion")
            return
        }
        
        print("Zmieniam status zadania \(todoId) na: \(isCompleted)")
        db.collection("todos").document(todoId).updateData(["isCompleted": isCompleted]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Błąd zmiany statusu zadania: \(error.localizedDescription)")
                } else {
                    print("Zaktualizowano status zadania \(todoId)")
                }
            }
        }
    }
    
    private func deleteTodo(for todoId: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Brak zalogowanego użytkownika w deleteTodo")
            return
        }
        
        print("Usuwam zadanie \(todoId)")
        db.collection("todos").document(todoId).delete { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Błąd usuwania zadania: \(error.localizedDescription)")
                } else {
                    print("Usunięto zadanie \(todoId)")
                }
            }
        }
    }
}

struct TodoView_Previews: PreviewProvider {
    static var previews: some View {
        TodoView()
    }
}
