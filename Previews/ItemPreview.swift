//
//  ItemPreview.swift
//  Listable
//
//  Created by Kyle Van Essen on 6/9/20.
//


#if DEBUG && canImport(SwiftUI) && !arch(i386) && !arch(arm)

import UIKit
import SwiftUI

public struct ItemPreview : UIViewRepresentable
{
    public typealias UIViewType = ItemTestingView
    
    public func makeUIView(context: Context) -> some UIView {
        
    }
    
    public func updateUIView(_ uiView: some UIView, context: Context) {
        
    }
}

#endif
