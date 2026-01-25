import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Auth Root
struct AuthView: View {
    @Binding var isLoggedIn: Bool
    @State private var isLogin = true

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if isLogin {
                LoginView(isLogin: $isLogin, isLoggedIn: $isLoggedIn)
            } else {
                SignUpView(isLogin: $isLogin, isLoggedIn: $isLoggedIn)
            }
        }
    }
}

//
// MARK: - Login View
//
struct LoginView: View {
    @Binding var isLogin: Bool
    @Binding var isLoggedIn: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false

    let allowedDomains = ["@utexas.edu", "@eid.utexas.edu", "@gmail.com"]

    var body: some View {
        VStack {
            Spacer()

            // 🔷 Logo + Title
            VStack(spacing: 12) {
                // Logo
                Image("UniTimeLogo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .foregroundColor(Color("UTAustinOrange"))

                // Subtitle
                Text("Your campus life, in one place")
                    .font(.subheadline)
                    .foregroundColor(Color(.systemGray))
            }
            .padding(.bottom, 40)

            // 🔐 Input Card
            VStack(spacing: 14) {
                TextField("UTmail", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
            }
            .padding(.horizontal)

            // 🔵 Login Button
            Button {
                login()
            } label: {
                ZStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Log in")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("UTAustinOrange"))
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .disabled(isLoading)

            // ❌ Error Message
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal)
            }

            Spacer()

            // ➕ Switch to Sign Up
            Button {
                isLogin = false
            } label: {
                Text("Don't have an account? Sign up")
                    .font(.footnote)
                    .foregroundColor(Color("UTAustinOrange"))
            }
            .padding(.bottom, 20)
        }
        .padding()
    }

    // MARK: - Login Logic (기존 그대로)
    private func login() {
        guard allowedDomains.contains(where: { email.hasSuffix($0) }) else {
            message = "Only UTmail accounts are allowed."
            return
        }

        isLoading = true
        message = ""

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false

            if let error = error {
                message = error.localizedDescription
                return
            }

            guard let user = result?.user else { return }

            user.reload { _ in
                if user.isEmailVerified {
                    isLoggedIn = true
                } else {
                    message = "Please verify your email before logging in."
                    try? Auth.auth().signOut()
                }
            }
        }
    }
}

//
// MARK: - Sign Up View
//
struct SignUpView: View {
    @Binding var isLogin: Bool
    @Binding var isLoggedIn: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var message = ""
    @State private var isLoading = false

    let allowedDomains = ["@utexas.edu", "@eid.utexas.edu", "@gmail.com"]

    var body: some View {
        VStack {
            Spacer()

            // 🔷 Title
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.largeTitle.bold())

                Text("Use your UTmail to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)

            // 🔐 Input Card
            VStack(spacing: 14) {
                TextField("UTmail", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)

                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
            }
            .padding(.horizontal)

            // 🔵 Create Account Button
            Button {
                signUp()
            } label: {
                ZStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Create account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("UTAustinOrange"))
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .disabled(isLoading)

            // ❌ Error / Info
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundColor(message.contains("sent") ? .green : .red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal)
            }

            Spacer()

            // 🔙 Back to Login
            Button {
                isLogin = true
            } label: {
                Text("Already have an account? Log in")
                    .font(.footnote)
                    .foregroundColor(Color("UTAustinOrange"))
            }
            .padding(.bottom, 20)
        }
        .padding()
    }

    // MARK: - Sign Up Logic (기존 그대로)
    private func signUp() {
        guard allowedDomains.contains(where: { email.hasSuffix($0) }) else {
            message = "Only UTmail accounts are allowed."
            return
        }

        guard password == confirmPassword else {
            message = "Passwords do not match."
            return
        }

        isLoading = true
        message = ""

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            isLoading = false

            if let error = error {
                message = error.localizedDescription
                return
            }

            guard let user = result?.user else { return }

            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "uid": user.uid,
                "email": user.email ?? "",
                "isVerified": false,
                "createdAt": Timestamp(date: Date())
            ])

            user.sendEmailVerification { error in
                if let error = error {
                    message = error.localizedDescription
                } else {
                    message = "Verification email sent. Please check your inbox."
                    try? Auth.auth().signOut()
                }
            }
        }
    }
}

