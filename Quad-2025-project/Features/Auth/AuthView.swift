import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AuthView: View {
    @Binding var isLoggedIn: Bool
    @State private var isLogin = true
    
    var body: some View {
        VStack {
            if isLogin {
                LoginView(isLogin: $isLogin, isLoggedIn: $isLoggedIn)
            } else {
                SignUpView(isLogin: $isLogin, isLoggedIn: $isLoggedIn)
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @Binding var isLogin: Bool
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""

    let allowedDomains = ["@utexas.edu", "@eid.utexas.edu", "@gmail.com"]

    var body: some View {
        VStack(spacing: 20) {
            Text("UniTime")
                .font(.largeTitle)
                .bold()

            TextField("UTmail (utexas.edu / eid.utexas.edu)", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.password)
                .padding(.horizontal)

            Button("Login") {
                login()
            }
            .buttonStyle(.borderedProminent)

            Text(message).foregroundColor(.red)

            Spacer()

            Button("Don't have an account? Sign up") {
                isLogin = false
            }
            .foregroundColor(.blue)
        }
        .padding()
    }

    func login() {
        guard allowedDomains.contains(where: { email.hasSuffix($0) }) else {
            message = "Only UTmail accounts (@utexas.edu or @eid.utexas.edu) are allowed."
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    message = "Login failed: \(error.localizedDescription)"
                }
            } else if let user = result?.user {
                // 🔑 인증 상태 새로고침
                user.reload { reloadError in
                    if let reloadError = reloadError {
                        DispatchQueue.main.async {
                            message = "Error checking verification: \(reloadError.localizedDescription)"
                        }
                        return
                    }

                    if user.isEmailVerified {
                        let db = Firestore.firestore()
                        db.collection("users").document(user.uid).getDocument { snapshot, error in
                            if let data = snapshot?.data(),
                               let verified = data["isVerified"] as? Bool, verified {
                                DispatchQueue.main.async {
                                    isLoggedIn = true
                                }
                            } else {
                                // Firestore에 isVerified 갱신
                                db.collection("users").document(user.uid).updateData([
                                    "isVerified": true
                                ])
                                DispatchQueue.main.async {
                                    isLoggedIn = true
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            message = "Please verify your email before logging in."
                            try? Auth.auth().signOut()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @Binding var isLogin: Bool
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var message = ""

    let allowedDomains = ["@utexas.edu", "@eid.utexas.edu", "@gmail.com"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign Up")
                .font(.largeTitle)
                .bold()

            TextField("UTmail (utexas.edu / eid.utexas.edu)", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.newPassword)
                .padding(.horizontal)

            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.newPassword)
                .padding(.horizontal)

            Button("Create Account") {
                signUp()
            }
            .buttonStyle(.borderedProminent)

            Text(message).foregroundColor(.red)

            Spacer()

            Button("Already have an account? Login") {
                isLogin = true
            }
            .foregroundColor(.blue)
        }
        .padding()
    }

    func signUp() {
        guard allowedDomains.contains(where: { email.hasSuffix($0) }) else {
            message = "Only UTmail accounts (@utexas.edu or @eid.utexas.edu) are allowed."
            return
        }
        guard password == confirmPassword else {
            message = "Passwords do not match."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    message = "Sign up failed: \(error.localizedDescription)"
                }
            } else if let user = result?.user {
                let actionCodeSettings = ActionCodeSettings()
                actionCodeSettings.url = URL(string: "https://quad-2025-project.web.app")!
                actionCodeSettings.handleCodeInApp = true
                actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)

                // Firestore에 기록 (isVerified = false)
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "uid": user.uid,
                    "email": user.email ?? "",
                    "isVerified": false,
                    "createdAt": Timestamp(date: Date())
                ])

                // 이메일 인증 메일 발송
                user.sendEmailVerification(with: actionCodeSettings) { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            message = "Failed to send verification email: \(error.localizedDescription)"
                        }
                    } else {
                        DispatchQueue.main.async {
                            message = "Verification email sent! Please check your inbox."
                            try? Auth.auth().signOut()
                        }
                    }
                }
            }
        }
    }
}
