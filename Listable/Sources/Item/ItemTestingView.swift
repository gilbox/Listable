//
//  ItemTestingView.swift
//  Listable
//
//  Created by Kyle Van Essen on 6/8/20.
//

import UIKit


public final class ItemTestingView<Content:ItemContent> : UIView {
            
    let cell : ItemCell<Content>
    let presentationState : PresentationState.ItemState<Content>
    
    public init(
        _ content : Content,
        sizing : Sizing,
        width : CGFloat,
        maxHeight : CGFloat = .greatestFiniteMagnitude,
        state : ItemState = .init(isSelected: false, isHighlighted: false),
        position : ItemPosition = .single,
        padding : UIEdgeInsets = .zero,
        background : UIColor = .white
    ) {
        self.cell = ItemCell<Content>()
        
        self.cell.isSelected = state.isSelected
        self.cell.isHighlighted = state.isHighlighted
        
        let item = Item(
            content,
            sizing: sizing
        )
        
        item.content.apply(
            to: ItemContentViews(
                content: self.cell.contentContainer.contentView,
                background: self.cell.background,
                selectedBackground: self.cell.selectedBackground
            ),
            for: .willDisplay,
            with: ApplyItemContentInfo(state: state, position: position, reordering: ReorderingActions())
        )
        
        self.presentationState = PresentationState.ItemState(
            with: item,
            dependencies: ItemStateDependencies(
                reorderingDelegate: ReorderingStub(),
                coordinatorDelegate: ItemContentCoordinatorStub()
            )
        )
        
        let cache = ReusableViewCache()
        
        let measured = self.presentationState.size(
            in: CGSize(width: width, height: maxHeight),
            layoutDirection: .vertical,
            defaultSize: CGSize(width: width, height: 100.0),
            measurementCache: cache
        )
        
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: width, height: measured.height)))
        
        self.backgroundColor = background
        
        self.addSubview(self.cell)
    }
    
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.cell.frame = self.bounds
    }
    
    private final class ReorderingStub : ReorderingActionsDelegate {
        func beginInteractiveMovementFor(item: AnyPresentationItemState) -> Bool { false }
        
        func updateInteractiveMovementTargetPosition(with recognizer: UIPanGestureRecognizer) {}
        
        func endInteractiveMovement() {}
        
        func cancelInteractiveMovement() {}
    }
    
    private final class ItemContentCoordinatorStub : ItemContentCoordinatorDelegate {
        func coordinatorUpdated(for item: AnyItem, animated: Bool) {}
    }
}
