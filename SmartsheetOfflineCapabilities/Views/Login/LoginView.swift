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

    var body: some View {
        NavigationStack {
            makeScreenContent()
                .onChange(of: viewModel.errorMessage) { _, newValue in
                    guard let newValue = newValue else { return }
                    showingError = newValue.isNotEmpty
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
                makeLoginButton()
            }

            Spacer()
        }
    }
    
    private func makeLoginButton() -> some View {
        Button(action: {
            viewModel.login()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Colors.blueNCL)
                    .frame(height: 44)

                if viewModel.isLoginInProgress {
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
        .disabled(viewModel.isLoginInProgress)
        .accessibilityIdentifier("Login")
    }
}

#Preview {
    LoginView()
}
