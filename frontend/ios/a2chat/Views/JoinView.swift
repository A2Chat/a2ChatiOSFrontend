import SwiftUI

struct JoinView: View {
    /// View Properties
    @State var otpText: String = ""
    /// Keyboard State
    @FocusState private var isKeyboardShowing: Bool
    
    var body: some View {
        VStack {
            otpInputField
            joinButton
        }
        .padding(.all)
        .frame(maxHeight: .infinity, alignment: .top)
        .toolbar { keyboardToolbar }
    }
    
    /// OTP Input Field
    private var otpInputField: some View {
        HStack(spacing: 0) {
            /// OTP Textboxes
            ForEach(0..<6, id: \.self) { index in
                OTPTextBox(index)
            }
        }
        .background(content: {
            hiddenTextField
        })
        .contentShape(Rectangle())
        .onTapGesture {
            isKeyboardShowing.toggle()
        }
        .padding(.bottom, 20)
        .padding(.top, 200)
    }
    
    /// Hidden Text Field for Input
    private var hiddenTextField: some View {
        TextField("", text: $otpText.limit(6))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            /// Hiding it out
            .frame(width: 1, height: 1)
            .opacity(0.001)
            .blendMode(.screen)
            .focused($isKeyboardShowing)
    }
    
    /// Join Button
    private var joinButton: some View {
        Button {
            // Your button action here
        } label: {
            Text("Join Lobby")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.blue)
                }
        }
        .disableWithOpacity(otpText.count < 6)
    }
    
    /// Keyboard Toolbar
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItem(placement: .keyboard) {
            Button("Done") {
                isKeyboardShowing.toggle()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    /// OTP Text Box
    @ViewBuilder
    private func OTPTextBox(_ index: Int) -> some View {
        ZStack {
            if otpText.count > index {
                let startIndex = otpText.startIndex
                let charIndex = otpText.index(startIndex, offsetBy: index)
                let charToString = String(otpText[charIndex])
                Text(charToString)
            } else {
                Text(" ")
            }
        }
        .frame(width: 45, height: 45)
        .background {
            /// Background Color
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.gray.opacity(0.1)) // Set background color here
                .overlay {
                    /// Highlight Current Active Box
                    let status = (isKeyboardShowing && otpText.count == index)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(status ? .black : .gray, lineWidth: status ? 2 : 0)
                        .animation(.easeInOut(duration: 0.2), value: status)
                }
        }
        .frame(maxWidth: .infinity)
    }
    
    struct JoinView_Previews: PreviewProvider {
        static var previews: some View {
            JoinView()
        }
    }
}

/// Viewing Extension
extension View {
    func disableWithOpacity(_ condition: Bool) -> some View {
        self
            .disabled(condition)
            .opacity(condition ? 0.6 : 1)
    }
}

/// Binding <String> to 1 Extension
extension Binding where Value == String {
    func limit(_ length: Int) -> Self {
        if self.wrappedValue.count > length {
            DispatchQueue.main.async {
                self.wrappedValue = String(self.wrappedValue.prefix(length))
            }
        }
        return self
    }
}
