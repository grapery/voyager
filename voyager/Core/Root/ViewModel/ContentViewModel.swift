//
//  ContentViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation
import Combine

class ContentViewModel: ObservableObject {
    
    private let service = AuthService.shared
    @Published var currentUser: User?
    @Published var userSession: String?
    
    init() {
        loadUserToken()
    }
    
    func loadUserToken() {
    }
}
