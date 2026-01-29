//
//  LoginView.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 09/06/25.
//

import SwiftData
import SwiftUI

struct LoginView: View {   
    @StateObject private var viewModel = LoginViewModel()
    
    @State private var isPasswordVisible = false
    @State private var presentNextScreen = false

    var body: some View {
        NavigationStack {
            makeScreenContent()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .background(Color(.systemGroupedBackground))
                .navigationDestination(isPresented: Binding(get: { viewModel.presentNextScreen  }, set: { _,_ in })) {
                    SheetListView()
                        .navigationBarBackButtonHidden()
                }
        }
        .onAppear {
            viewModel.onAppear()
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
                        
            if let message = viewModel.message {
                Text(viewModel.message ?? "")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .transition(.slide)
                    .animation(.easeInOut, value: message)
            }
            
            Spacer()
            
            Text(AppInfo.versionBuildFormatted)
                .font(.footnote)
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

                if viewModel.status == .loading {
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
        .disabled(viewModel.status == .loading)
        .accessibilityIdentifier("Login")
    }
}

#Preview {
    LoginView()
}
