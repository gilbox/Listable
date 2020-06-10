//
//  ItemTestingView.swift
//  Listable
//
//  Created by Kyle Van Essen on 6/8/20.
//

import UIKit


public final class ItemTestingView<Content:ItemContent> : UIView {
            
    let listView : ListView
    
    public init(width : CGFloat = UIScreen.main.bounds.width, _ configure : (ItemTestingView<Content>) -> ())
    {
        self.listView = ListView(frame: CGRect(x: 0.0, y: 0.0, width: width, height: 100.0))
        
        super.init(frame: CGRect(x: 0.0, y: 0.0, width: width, height: 100.0))
        
        configure(self)
    }
    
    public func set(
        _ item : Item<Content>,
        itemState : ItemState = .init(isSelected: false, isHighlighted: false),
        appearance : (inout Appearance) -> () = { _ in }
    ) {
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
                        
        self.addSubview(self.listView)
    }
    
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.listView.frame = self.bounds
    }

}
