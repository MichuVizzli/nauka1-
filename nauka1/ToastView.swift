import SwiftUI

struct ToastView: View {
    let message: String
    let isError: Bool
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Text(message)
                .foregroundColor(.white)
                .padding()
                .background(isError ? Color.red : Color.green)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: isShowing)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isShowing = false
            }
        }
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ToastView(message: "Testowe powiadomienie", isError: false, isShowing: .constant(true))
    }
}
