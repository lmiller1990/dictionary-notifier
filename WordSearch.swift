//
//  WordSearch.swift
//  NotificationDemo
//
//  Created by Lachlan Miller on 11/10/19.
//  Copyright © 2019 Lachlan Miller. All rights reserved.
//

import Foundation
import SwiftUI

struct SearchBar: UIViewRepresentable {
    
    @Binding var text: String
    var onSearch: () -> Void
    
    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text, onSearchCb: onSearch)
    }
    
    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = context.coordinator
        
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        var searchBarSearchButtonClicked: () -> Void

        init(text: Binding<String>, onSearchCb:  @escaping () -> Void) {
            _text = text
            searchBarSearchButtonClicked = onSearchCb
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            self.searchBarSearchButtonClicked()
        }
    }
}
