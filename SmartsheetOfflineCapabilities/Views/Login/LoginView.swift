//
//  LoginView.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 09/06/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    @State private var isPasswordVisible = false
    @State private var showingError = false
    @State private var presentNextScreen = false
    
//    @EnvironmentObject private var authenticationService: AuthenticationService

    var body: some View {
        NavigationStack {
            makeScreenContent()
                .onChange(of: viewModel.errorMessage) { _, newValue in
                    showingError = newValue != nil
                }
                .alert("Login Failed", isPresented: $showingError, actions: {
                    Button("OK", role: .cancel) {
                        viewModel.errorMessage = nil
                    }
                }, message: {
                    Text(viewModel.errorMessage ?? "Unknown error")
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .background(Color(.systemGroupedBackground))
                .navigationDestination(isPresented: Binding(get: { viewModel.presentNextScreen  }, set: { _,_ in })) {                    
                    SelectFileView()
                        .navigationBarBackButtonHidden()                                        
                }
        }
    }
    
    // MARK: Initializers
    
//    init(authenticationService: AuthenticationService) {
//        _viewModel = StateObject(wrappedValue: LoginViewModel(authenticationService: authenticationService))
//    }
    
    // MARK: Private methods

    private func makeScreenContent() -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.on.doc")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(Colors.blueNCL)
                .padding(.bottom, 8)

            Text("WelcomeMessage")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
//                TextField("Username", text: $viewModel.username)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .frame(maxWidth: 300)
//                    .disabled(viewModel.isLoggingIn)
//                    .accessibilityIdentifier("Username")

//                ZStack {
//                    if isPasswordVisible {
//                        TextField("Password", text: $viewModel.password)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .frame(maxWidth: 300)
//                            .disabled(viewModel.isLoggingIn)
//                            .accessibilityIdentifier("Password")
//                    } else {
//                        SecureField("Password", text: $viewModel.password)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .frame(maxWidth: 300)
//                            .disabled(viewModel.isLoggingIn)
//                            .accessibilityIdentifier("PasswordSecure")
//                    }

//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            isPasswordVisible.toggle()
//                        }) {
//                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
//                                .foregroundColor(.gray)
//                        }
//                        .padding(.trailing, 12)
//                        .contentShape(Rectangle())
//                    }
//                    .frame(maxWidth: 300)
//                    .accessibilityIdentifier("ShowHidePassword")
//                }

                makeLoginButton()
            }

            Spacer()
        }
    }
    
    private func makeLoginButton() -> some View {
        Button(action: {
            viewModel.login()
                        
            //TODO: Error handling
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
                if viewModel.errorMessage == nil {
                    presentNextScreen = true
                }
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    //viewModel.isLoginDisabled ? Color(.lightGray) :
                    .fill(Colors.blueNCL)
                    .frame(height: 44)

                if viewModel.isLoggingIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Login")
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: 300)
//        .disabled(viewModel.isLoginDisabled)
        .accessibilityIdentifier("Login")
    }
}

//#Preview {
//    LoginView()
//}
