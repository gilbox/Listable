//
//  Sizing.swift
//  Listable
//
//  Created by Kyle Van Essen on 10/27/19.
//

import Foundation


///
/// Controls how a header, footer, or item in a list view is sized.
///
public enum Sizing : Hashable
{
    /// The default size from the list's appearance is used. The size is not dynamic at all.
    case `default`
    
    /// Fixes the size to the absolute value passed in.
    ///
    /// Note
    /// ----
    /// This option takes in both a size and a width. However, for standard list views,
    /// only the height is used. The width is provided for when custom layouts are used,
    /// which may allow sizing for other types of layouts, eg, grids.
    ///
    case fixed(width : CGFloat = 0.0, height : CGFloat = 0.0)
    
    /// Sizes the item by calling `sizeThatFits` on its underlying view type.
    case thatFits
    
    /// Sizes the item by calling `sizeThatFits` on its underlying view type.
    /// The passed in constraint is used to clamp the size to a minimum, maximum, or range.
    ///
    /// Example
    /// -------
    /// If you would like to use `sizeThatFits` to size an item, but would like to enforce a minimum size,
    /// you would do something similar to the following:
    ///
    /// ```
    /// // Enforces that the size is at least the default size of the list.
    /// .thatFitsWith(.init(.atLeast(.default)))
    ///
    ///  // Enforces that the size is at least 50 points.
    /// .thatFitsWith(.init(.atLeast(.fixed(50))))
    /// ```
    case thatFitsWith(Constraint)
    
    /// Sizes the item by calling `systemLayoutSizeFitting` on its underlying view type.
    case autolayout
    
    /// Sizes the item by calling `systemLayoutSizeFitting` on its underlying view type.
    /// The passed in constraint is used to clamp the size to a minimum, maximum, or range.
    ///
    /// Example
    /// -------
    /// If you would like to use `systemLayoutSizeFitting` to size an item, but would like to enforce a minimum size,
    /// you would do something similar to the following:
    ///
    /// ```
    /// // Enforces that the size is at least the default size of the list.
    /// .autolayoutWith(.init(.atLeast(.default)))
    ///
    ///  // Enforces that the size is at least 50 points.
    /// .autolayoutWith(.init(.atLeast(.fixed(50))))
    /// ```
    case autolayoutWith(Constraint)
    
    /// Measures the given view with the provided options.
    /// The returned value is `ceil()`'d to round up to the next full integer value.
    func measure(with view : UIView, in sizeConstraint : CGSize, layoutDirection : LayoutDirection, defaultSize : CGSize) -> CGSize
    {
        let value : CGSize = {
            switch self {
            case .default:
                return defaultSize
                
            case .fixed(let width, let height):
                return CGSize(width: width, height: height)
                
            case .thatFits:
                return Sizing.thatFitsWith(.noConstraint).measure(
                    with: view,
                    in: sizeConstraint,
                    layoutDirection: layoutDirection,
                    defaultSize: defaultSize
                )
                
            case .thatFitsWith(let constraint):
                let fittingSize = layoutDirection.size(for: sizeConstraint)
                let size = view.sizeThatFits(fittingSize)
                
                return constraint.clamp(size, with: defaultSize)
                
            case .autolayout:
                return Sizing.autolayoutWith(.noConstraint).measure(
                    with: view,
                    in: sizeConstraint,
                    layoutDirection: layoutDirection,
                    defaultSize: defaultSize
                )
                
            case .autolayoutWith(let constraint):
                let fittingSize = layoutDirection.size(for: sizeConstraint)
                
                let size : CGSize
                
                switch layoutDirection {
                case .vertical:
                    size = view.systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
                case .horizontal:
                    size = view.systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: .defaultLow, verticalFittingPriority: .required)
                }
                
                return constraint.clamp(size, with: defaultSize)
            }
        }()
        
        return CGSize(
            width: ceil(value.width),
            height: ceil(value.height)
        )
    }
}


public extension Sizing
{
    struct Constraint : Hashable
    {
        public var width : Axis
        public var height : Axis
        
        public static var noConstraint : Constraint {
            Constraint(
                width: .noConstraint,
                height: .noConstraint
            )
        }
        
        public init(_ value : Axis)
        {
            self.width = value
            self.height = value
        }
        
        public init(
            width : Axis,
            height : Axis
        ) {
            self.width = width
            self.height = height
        }
        
        public func clamp(_ value : CGSize, with defaultSize : CGSize) -> CGSize
        {
            return CGSize(
                width: self.width.clamp(value.width, with: defaultSize.width),
                height: self.height.clamp(value.height, with: defaultSize.height)
            )
        }
        
        public enum Axis : Hashable
        {
            case noConstraint
            
            case atLeast(Value)
            case atMost(CGFloat)
            
            case within(Value, CGFloat)
            
            public enum Value : Hashable
            {
                case `default`
                case fixed(CGFloat)
                
                public func value(with defaultHeight : CGFloat) -> CGFloat
                {
                    switch self {
                    case .`default`: return defaultHeight
                    case .fixed(let fixed): return fixed
                    }
                }
            }
            
            public func clamp(_ value : CGFloat, with defaultValue : CGFloat) -> CGFloat
            {
                switch self {
                case .noConstraint: return value
                case .atLeast(let minimum): return max(minimum.value(with: defaultValue), value)
                case .atMost(let maximum): return min(maximum, value)
                case .within(let minimum, let maximum): return max(minimum.value(with: defaultValue), min(maximum, value))
                }
            }
        }
    }
}


public enum WidthConstraint : Equatable
{
    case noConstraint
    case fixed(CGFloat)
    case atMost(CGFloat)
    
    public func clamp(_ value : CGFloat) -> CGFloat
    {
        switch self {
        case .noConstraint: return value
        case .fixed(let fixed): return fixed
        case .atMost(let maximum): return min(maximum, value)
        }
    }
}


public enum CustomWidth : Equatable
{
    case `default`
    case fill
    case custom(Custom)
    
    public func merge(with parent : CustomWidth) -> CustomWidth
    {
        switch self {
        case .default: return parent
        case .fill: return self
        case .custom(_): return self
        }
    }
    
    public func position(with viewSize : CGSize, defaultWidth : CGFloat, layoutDirection : LayoutDirection) -> Position
    {
        switch self {
        case .default: return Position(origin: round((layoutDirection.width(for: viewSize) - defaultWidth) / 2.0), width: defaultWidth)
        case .fill: return Position(origin: 0.0, width: layoutDirection.width(for: viewSize))
        case .custom(let custom): return custom.position(with: viewSize, layoutDirection: layoutDirection)
        }
    }
    
    public struct Custom : Equatable
    {
        public var padding : HorizontalPadding
        public var width : WidthConstraint
        public var alignment : Alignment
        
        public init(
            padding : HorizontalPadding = .zero,
            width : WidthConstraint = .noConstraint,
            alignment : Alignment = .center
        )
        {
            self.padding = padding
            self.width = width
            self.alignment = alignment
        }
        
        public func position(with viewSize : CGSize, layoutDirection : LayoutDirection) -> Position
        {
            let width = ListAppearance.Layout.width(
                with: layoutDirection.width(for: viewSize),
                padding: self.padding,
                constraint: self.width
            )
            
            return Position(
                origin: self.alignment.originWith(
                    parentWidth: layoutDirection.width(for: viewSize),
                    width: width,
                    padding: self.padding,
                    layoutDirection: layoutDirection
                ),
                width: width
            )
        }
    }
    
    public enum Alignment : Equatable
    {
        case left
        case center
        case right
        
        public func originWith(parentWidth : CGFloat, width : CGFloat, padding : HorizontalPadding, layoutDirection : LayoutDirection) -> CGFloat
        {
            switch self {
            case .left:
                return padding.left
            case .center:
                return round((parentWidth - width) / 2.0)
            case .right:
                return parentWidth - width - padding.right
            }
        }
    }
    
    public struct Position : Equatable
    {
        var origin : CGFloat
        var width : CGFloat
    }
}


public struct HorizontalPadding : Equatable
{
    public var left : CGFloat
    public var right : CGFloat
    
    public static var zero : HorizontalPadding {
        return HorizontalPadding(left: 0.0, right: 0.0)
    }
    
    public init(left : CGFloat = 0.0, right : CGFloat = 0.0)
    {
        self.left = left
        self.right = right
    }
    
    public init(uniform : CGFloat = 0.0)
    {
        self.left = uniform
        self.right = uniform
    }
}
