//
//  Behavior.swift
//  Listable
//
//  Created by Kyle Van Essen on 11/13/19.
//

import Foundation


/// Controls various behaviors of the list view, such as keyboard dismissal, selection mode, and behavior
/// when the list content underflows the available space in the list view.
public struct Behavior : Equatable
{
    /// How the keyboard should be dismissed (if at all) based on scrolling of the list view.
    public var keyboardDismissMode : UIScrollView.KeyboardDismissMode
        
    /// How the list should respond to selection attempts.
    public var selectionMode : SelectionMode
        
    /// How the list should behave when its content takes up less space than is available in the list view.
    public var underflow : Underflow
    
    /// A Boolean value that controls whether touches in the content view always lead to tracking.
    public var canCancelContentTouches : Bool
    
    /// A Boolean value that determines whether the scroll view delays the handling of touch-down gestures.
    public var delaysContentTouches : Bool
    
    /// Creates a new `Behavior` based on the provided parameters.
    public init(
        keyboardDismissMode : UIScrollView.KeyboardDismissMode = .interactive,
        selectionMode : SelectionMode = .single,
        underflow : Underflow = Underflow(),
        canCancelContentTouches : Bool = true,
        delaysContentTouches : Bool = true
    ) {
        self.keyboardDismissMode = keyboardDismissMode
        self.selectionMode = selectionMode
        self.underflow = underflow
        
        self.canCancelContentTouches = canCancelContentTouches
        self.delaysContentTouches = delaysContentTouches
    }
}

public extension Behavior
{
    /// The selection mode of the list view, which controls how many items (if any) can be selected at once.
    enum SelectionMode : Equatable
    {
        /// The list view does not allow any selections.
        case none
        
        /// The list view allows single selections. When an item is selected, the previously selected item (if any)
        /// will be deselected by the list. If you provide multiple selected items in your content description,
        /// the last selected item in the content will be selected.
        case single
        
        /// The list view allows multiple selections. It is your responsibility to update the content
        /// of the list to select and deselect items based on the selection of other items.
        case multiple
    }
    
    struct Underflow : Equatable
    {
        public var alwaysBounce : Bool
        public var alignment : Alignment
        
        public init(alwaysBounce : Bool = true, alignment : Alignment = .top)
        {
            self.alwaysBounce = alwaysBounce
            self.alignment = alignment
        }
        
        public enum Alignment : Equatable
        {
            case top
            case center
            case bottom
            
            func offsetFor(contentHeight : CGFloat, viewHeight: CGFloat) -> CGFloat
            {
                guard contentHeight < viewHeight else {
                    return 0.0
                }
                
                switch self {
                case .top: return 0.0
                case .center: return round((viewHeight - contentHeight) / 2.0)
                case .bottom: return viewHeight - contentHeight
                }
            }
        }
    }
}
