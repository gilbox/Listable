//
//  PresentationState.HeaderFooterState.swift
//  Listable
//
//  Created by Kyle Van Essen on 5/22/20.
//

import Foundation


protocol AnyPresentationHeaderFooterState : AnyObject
{
    var anyModel : AnyHeaderFooter { get }
        
    func dequeueAndPrepareReusableHeaderFooterView(in cache : ReusableViewCache, frame : CGRect) -> UIView
    func enqueueReusableHeaderFooterView(_ view : UIView, in cache : ReusableViewCache)
    
    func applyTo(view anyView : UIView, reason : ApplyReason)
    
    func setNew(headerFooter anyHeaderFooter : AnyHeaderFooter)
    
    func resetCachedSizes()
    func size(in sizeConstraint : CGSize, layoutDirection : LayoutDirection, defaultSize : CGSize, measurementCache : ReusableViewCache) -> CGSize
}


extension PresentationState
{
    final class HeaderFooterViewStatePair
    {
        var state : AnyPresentationHeaderFooterState? {
            didSet {
                guard oldValue !== self.state else {
                    return
                }
                
                guard let container = self.visibleContainer else {
                    return
                }
                
                container.headerFooter = self.state
            }
        }
        
        private(set) var visibleContainer : SupplementaryContainerView?
        
        func willDisplay(view : SupplementaryContainerView)
        {
            self.visibleContainer = view
        }
        
        func didEndDisplay()
        {
            self.visibleContainer = nil
        }
        
        func applyToVisibleView()
        {
            guard let view = visibleContainer?.content, let state = self.state else {
                return
            }
            
            state.applyTo(view: view, reason: .wasUpdated)
        }
    }
    
    final class HeaderFooterState<Element:HeaderFooterElement> : AnyPresentationHeaderFooterState
    {
        var model : HeaderFooter<Element>
                
        init(_ model : HeaderFooter<Element>)
        {
            self.model = model
        }
        
        // MARK: AnyPresentationHeaderFooterState
        
        var anyModel: AnyHeaderFooter {
            return self.model
        }
                
        func dequeueAndPrepareReusableHeaderFooterView(in cache : ReusableViewCache, frame : CGRect) -> UIView
        {
            let view = cache.pop(with: self.model.reuseIdentifier) {
                return Element.createReusableHeaderFooterView(frame: frame)
            }
            
            self.applyTo(view: view, reason: .willDisplay)
            
            return view
        }
        
        func enqueueReusableHeaderFooterView(_ view : UIView, in cache : ReusableViewCache)
        {
            cache.push(view, with: self.model.reuseIdentifier)
        }
        
        func createReusableHeaderFooterView(frame : CGRect) -> UIView
        {
            return Element.createReusableHeaderFooterView(frame: frame)
        }
        
        func applyTo(view : UIView, reason : ApplyReason)
        {
            let view = view as! Element.ContentView
            
            self.model.element.apply(to: view, reason: reason)
        }
        
        func setNew(headerFooter anyHeaderFooter: AnyHeaderFooter)
        {
            let oldModel = self.model
            
            self.model = anyHeaderFooter as! HeaderFooter<Element>
            
            let isEquivalent = self.model.anyIsEquivalent(to: oldModel)
            
            if isEquivalent == false {
                self.resetCachedSizes()
            }
        }
        
        private var cachedSizes : [SizeKey:CGSize] = [:]
        
        func resetCachedSizes()
        {
            self.cachedSizes.removeAll()
        }
        
        func size(in sizeConstraint : CGSize, layoutDirection : LayoutDirection, defaultSize : CGSize, measurementCache : ReusableViewCache) -> CGSize
        {
            guard sizeConstraint.isEmpty == false else {
                return .zero
            }
            
            let key = SizeKey(
                width: sizeConstraint.width,
                height: sizeConstraint.height,
                layoutDirection: layoutDirection,
                sizing: self.model.sizing
            )
            
            if let size = self.cachedSizes[key] {
                return size
            } else {
                SignpostLogger.log(.begin, log: .updateContent, name: "Measure HeaderFooter", for: self.model)
                
                let size : CGSize = measurementCache.use(
                    with: self.model.reuseIdentifier,
                    create: {
                        return Element.createReusableHeaderFooterView(frame: .zero)
                }, { view in
                    self.model.element.apply(to: view, reason: .willDisplay)
                    
                    return self.model.sizing.measure(with: view, in: sizeConstraint, layoutDirection: layoutDirection, defaultSize: defaultSize)
                })
                
                self.cachedSizes[key] = size
                
                SignpostLogger.log(.end, log: .updateContent, name: "Measure HeaderFooter", for: self.model)
                
                return size
            }
        }
    }
}
