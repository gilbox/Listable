//
//  XcodePreviewDemo.swift
//  Demo
//
//  Created by Kyle Van Essen on 6/9/20.
//  Copyright © 2020 Kyle Van Essen. All rights reserved.
//

import SwiftUI
import Listable


@available(iOS 13.0, *)
struct ElementPreview : PreviewProvider {
    static var previews: some View {
        ItemPreview<XcodePreviewDemoContent>(
            Item(XcodePreviewDemoContent(text: "Hello, World"))
        )
    }
}


public struct ItemPreview2<Content:ItemContent> : UIViewRepresentable
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


fileprivate struct XcodePreviewDemoContent : ItemContent, Equatable
{
    var text : String
    
    var identifier: Identifier<XcodePreviewDemoContent> {
        .init(self.text)
    }
    
    func apply(to views: ItemContentViews<XcodePreviewDemoContent>, for reason: ApplyReason, with info: ApplyItemContentInfo) {
        views.content.text = self.text
    }
    
    typealias ContentView = UILabel
    
    static func createReusableContentView(frame: CGRect) -> UILabel {
        UILabel(frame: frame)
    }
}
