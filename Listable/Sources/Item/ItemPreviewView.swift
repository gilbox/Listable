//
//  ItemPreviewView.swift
//  Listable
//
//  Created by Kyle Van Essen on 6/8/20.
//

import UIKit


public final class ItemPreviewView<Content:ItemContent> : UIView {
            
    let listView : ListView
    
    public init(width : CGFloat = UIScreen.main.bounds.width)
    {
        let frame = CGRect(x: 0.0, y: 0.0, width: width, height: 100.0)
        
        self.listView = ListView(frame: frame)
        
        super.init(frame: frame)
        
        self.addSubview(self.listView)
    }
    
    public convenience init(
        _ item : Item<Content>,
        width : CGFloat = UIScreen.main.bounds.width,
        itemState : ItemState = .init(isSelected: false, isHighlighted: false),
        appearance : (inout Appearance) -> () = { _ in }
    ) {
        self.init(width: width)
        
        self.set(item, width: width, itemState: itemState, appearance: appearance)
    }
    
    public func set(
        _ item : Item<Content>,
        width : CGFloat = UIScreen.main.bounds.width,
        itemState : ItemState = .init(isSelected: false, isHighlighted: false),
        appearance : (inout Appearance) -> () = { _ in }
    ) {
        self.frame.size.width = width
        
        self.listView.setContent { list in
            appearance(&list.appearance)
            
            list += Section(identifier: "section") { section in
                section += item
            }
        }
        
        self.listView.collectionView.layoutIfNeeded()
        
        let indexPath = IndexPath(item: 0, section: 0)
        
        let cell = self.listView.collectionView.cellForItem(at: indexPath)!
        let state = self.listView.storage.presentationState.item(at: indexPath)
        
        state.applyTo(cell: cell, itemState: itemState, reason: .willDisplay)
        
        self.frame.size.height = self.listView.layout.layout.content.contentSize.height
    }
    
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.listView.frame = self.bounds
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize
    {
        self.listView.layout.layout.content.contentSize
    }

}
