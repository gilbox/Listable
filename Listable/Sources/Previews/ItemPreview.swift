//
//  ItemPreview.swift
//  Listable
//
//  Created by Kyle Van Essen on 6/9/20.
//


#if DEBUG && canImport(SwiftUI) && !arch(i386) && !arch(arm)

import UIKit
import SwiftUI

@available(iOS 13.0, *)
public struct ItemPreview<Content:ItemContent> : UIViewRepresentable
{
    public var item : Item<Content>
    public var width : CGFloat
    public var itemState : ItemState
    public var appearance : (inout Appearance) -> ()
    
    public init(
        _ item : Item<Content>,
        width : CGFloat = UIScreen.main.bounds.width,
        itemState : ItemState = .init(isSelected: false, isHighlighted: false),
        appearance : @escaping (inout Appearance) -> () = { _ in }
    ) {
        self.item = item
        self.width = width
        self.itemState = itemState
        self.appearance = appearance
    }
    
    public typealias UIViewType = ItemPreviewView<Content>
    
    public func makeUIView(context: Context) -> UIViewType {
        return ItemPreviewView()
    }
    
    public func updateUIView(_ view: UIViewType, context: Context) {
        view.set(
            self.item,
            width: self.width,
            itemState: self.itemState,
            appearance: self.appearance
        )
    }
}

#endif
