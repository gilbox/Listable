//
//  ListView.swift
//  Listable
//
//  Created by Kyle Van Essen on 6/16/19.
//

import UIKit


public final class ListView : UIView
{
    //
    // MARK: Initialization
    //
    
    public init(frame: CGRect = .zero, appearance : Appearance = Appearance())
    {
        // Create all default values.

        self.appearance = appearance
        
        self.behavior = Behavior()
        self.autoScrollAction = .none
        self.scrollInsets = ScrollInsets(top: nil, bottom:  nil)
        
        self.storage = Storage()
        self.sourcePresenter = SourcePresenter(initial: StaticSource.State(), source: StaticSource())
        
        self.dataSource = DataSource()
        self.delegate = Delegate()
        
        let initialLayout = CollectionViewLayout(
            delegate: self.delegate,
            layoutType: .list,
            appearance: self.appearance,
            behavior: self.behavior
        )

        self.collectionView = CollectionView(frame: CGRect(origin: .zero, size: frame.size), collectionViewLayout: initialLayout)
        
        self.layoutManager = LayoutManager(
            layout: initialLayout,
            collectionView: self.collectionView
        )
        
        self.visibleContent = VisibleContent()

        self.keyboardObserver = KeyboardObserver()
        
        self.collectionView.isPrefetchingEnabled = false
                
        self.collectionView.dataSource = self.dataSource
        self.collectionView.delegate = self.delegate
        
        // Super init.
        
        super.init(frame: frame)
        
        // Associate ourselves with our child objects.

        self.collectionView.view = self

        self.dataSource.presentationState = self.storage.presentationState
        
        self.delegate.view = self
        self.delegate.presentationState = self.storage.presentationState
        
        self.keyboardObserver.delegate = self
        
        // Register supplementary views.
        
        SupplementaryKind.allCases.forEach {
            SupplementaryContainerView.register(in: self.collectionView, for: $0.rawValue)
        }
        
        // Size and update views.
        
        self.collectionView.frame = self.bounds
        self.addSubview(self.collectionView)
        
        self.applyAppearance()
        self.applyBehavior()
        self.applyScrollInsets()
    }
    
    deinit
    {        
        /**
         Even though these are zeroing weak references in UIKIt as of iOS 9.0,
         
         We still want to nil these out, because _our_ `delegate` and `dataSource`
         objects have unowned references back to us (`ListView`). We do not want
         any `delegate` or `dataSource` callbacks to trigger referencing
         that unowned reference (eg, in `scrollViewDidScroll:`).
         */

        self.collectionView.delegate = nil
        self.collectionView.dataSource = nil
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { listableFatal() }
    
    //
    // MARK: Internal Properties
    //
    
    let storage : Storage
    let collectionView : CollectionView
    let delegate : Delegate
    
    var layout : CollectionViewLayout {
        self.layoutManager.current
    }
    
    private(set) var visibleContent : VisibleContent
    
    //
    // MARK: Private Properties
    //
        
    private let layoutManager : LayoutManager
    
    private var sourcePresenter : AnySourcePresenter

    private var autoScrollAction : AutoScrollAction
    
    private let dataSource : DataSource
    
    private let keyboardObserver : KeyboardObserver
    
    //
    // MARK: Debugging
    //
    
    public var debuggingIdentifier : String? = nil
    
    //
    // MARK: Appearance
    //
    
    public var appearance : Appearance {
        didSet {
            guard oldValue != self.appearance else {
                return
            }
            
            self.applyAppearance()
        }
    }
    
    private func applyAppearance()
    {
        // Appearance
        
        self.layout.appearance = self.appearance
        self.backgroundColor = self.appearance.backgroundColor
        
        // Row Sizing
        
        self.storage.presentationState.resetAllCachedSizes()
        
        // Scroll View
        
        self.updateCollectionViewBounce()
        
        self.collectionView.showsHorizontalScrollIndicator = self.appearance.showsScrollIndicators
        self.collectionView.showsVerticalScrollIndicator = self.appearance.showsScrollIndicators
    }
    
    //
    // MARK: Layout
    //
    
    public var scrollPositionInfo : ListScrollPositionInfo {
        let visibleItems = Set(self.visibleContent.items.map { item in
            item.item.anyModel.identifier
        })
        
        return ListScrollPositionInfo(
            scrollView: self.collectionView,
            visibleItems: visibleItems,
            isFirstItemVisible: self.content.firstItem.map { visibleItems.contains($0.identifier) } ?? false,
            isLastItemVisible: self.content.lastItem.map { visibleItems.contains($0.identifier) } ?? false
        )
    }
    
    public var layoutType : ListLayoutType {
        get {
            self.layout.layoutType
        }
        
        set {
            self.set(layoutType: newValue)
        }
    }
    
    public func set(layoutType : ListLayoutType, animated : Bool = false, completion : @escaping () -> () = {})
    {
        self.layoutManager.set(layoutType: layoutType, animated: animated, completion: completion)
    }
    
    //
    // MARK: Behavior
    //
    
    public var behavior : Behavior {
        didSet {
            guard oldValue != self.behavior else {
                return
            }
            
            self.applyBehavior()
        }
    }
    
    private func applyBehavior()
    {
        self.layout.behavior = self.behavior
        
        self.collectionView.keyboardDismissMode = self.behavior.keyboardDismissMode
        
        self.updateCollectionViewBounce()
        self.updateCollectionViewSelectionMode()
    }
    
    private func updateCollectionViewBounce()
    {
        self.collectionView.setAlwaysBounce(
            self.behavior.underflow.alwaysBounce,
            direction: self.appearance.direction
        )
    }
    
    private func updateCollectionViewSelectionMode()
    {
        let view = self.collectionView
        
        switch self.behavior.selectionMode {
        case .none:
            view.allowsSelection = false
            view.allowsMultipleSelection = false
            
        case .single:
            view.allowsSelection = true
            view.allowsMultipleSelection = false
            
        case .multiple:
            view.allowsSelection = true
            view.allowsMultipleSelection = true
        }
    }
    
    //
    // MARK: Scroll Insets
    //
    
    public var scrollInsets : ScrollInsets {
        didSet {
            guard oldValue != self.scrollInsets else {
                return
            }
            
            self.applyScrollInsets()
        }
    }
    
    func applyScrollInsets()
    {
        let insets = self.scrollInsets.insets(
            with: self.collectionView.contentInset,
            layoutDirection: self.appearance.direction
        )

        self.collectionView.contentInset = insets
        self.collectionView.scrollIndicatorInsets = insets
    }
    
    //
    // MARK: Public - Scrolling To Sections & Items
    //
    
    ///
    /// Scrolls to the provided item, with the provided positioning.
    /// If the item is contained in the list, true is returned. If it is not, false is returned.
    ///
    @discardableResult
    public func scrollTo(item : AnyItem, position : ItemScrollPosition, animated : Bool = false) -> Bool
    {
        return self.scrollTo(item: item.identifier, position: position, animated: animated)
    }
    
    ///
    /// Scrolls to the item with the provided identifier, with the provided positioning.
    /// If there is more than one item with the same identifier, the list scrolls to the first.
    /// If the item is contained in the list, true is returned. If it is not, false is returned.
    ///
    @discardableResult
    public func scrollTo<Content:ItemContent>(item : Identifier<Content>, position : ItemScrollPosition, animated : Bool = false) -> Bool
    {
        return self.scrollTo(item: item.toAny, position: position, animated: animated)
    }
    
    ///
    /// Scrolls to the item with the provided identifier, with the provided positioning.
    /// If there is more than one item with the same identifier, the list scrolls to the first.
    /// If the item is contained in the list, true is returned. If it is not, false is returned.
    ///
    @discardableResult
    public func scrollTo(item : AnyIdentifier, position : ItemScrollPosition, animated : Bool = false) -> Bool
    {
        // Make sure the item identifier is valid.
        
        guard let toIndexPath = self.storage.allContent.indexPath(for: item) else {
            return false
        }
        
        return self.preparePresentationStateForScroll(to: toIndexPath) {
                        
            let isAlreadyVisible: Bool = {
                let frame = self.layout.frameForItem(at: toIndexPath)

                return self.collectionView.contentFrame.contains(frame)
            }()

            // If the item is already visible and that's good enough, return.

            if isAlreadyVisible && position.ifAlreadyVisible == .doNothing {
                return
            }
            
            self.collectionView.scrollToItem(
                at: toIndexPath,
                at: position.position.UICollectionViewScrollPosition,
                animated: animated
            )
        }
    }
    
    /// Scrolls to the very top of the list, which includes displaying the list header.
    @discardableResult
    public func scrollToTop(animated : Bool = false) -> Bool {
        self.preparePresentationStateForScroll(to: IndexPath(item: 0, section: 0))  {
            self.collectionView.scrollRectToVisible(.zero, animated: animated)
        }
    }

    /// Scrolls to the last item in the list. If the list contains no items, no action is performed.
    @discardableResult
    public func scrollToLastItem(animated : Bool = false) -> Bool {

        // Make sure we have a valid last index path.

        guard let toIndexPath = self.storage.allContent.lastIndexPath() else {
            return false
        }

        // Perform scrolling.

        return self.preparePresentationStateForScroll(to: toIndexPath)  {
            let contentHeight = self.layout.collectionViewContentSize.height
            let contentFrameHeight = self.collectionView.contentFrame.height

            guard contentHeight > contentFrameHeight else {
                return
            }

            let contentOffsetY = contentHeight - contentFrameHeight - self.collectionView.lst_adjustedContentInset.top
            let contentOffset = CGPoint(x: self.collectionView.contentOffset.x, y: contentOffsetY)
            
            self.collectionView.setContentOffset(contentOffset, animated: animated)
        }
    }
    
    //
    // MARK: Setting & Getting Content
    //
    
    public var content : Content {
        get { return self.storage.allContent }
        set { self.setContent(animated: false, newValue) }
    }
    
    public func setContent(with builder : ListDescription.Build)
    {
        let description = ListDescription(
            animatesChanges: true,
            layoutType: self.layoutType,
            appearance: self.appearance,
            behavior: self.behavior,
            autoScrollAction: self.autoScrollAction,
            scrollInsets: self.scrollInsets,
            accessibilityIdentifier: self.collectionView.accessibilityIdentifier,
            debuggingIdentifier: self.debuggingIdentifier,
            build: builder
        )
        
        self.setProperties(with: description)
    }
    
    public func setContent(animated : Bool = false, _ content : Content)
    {
        self.set(
            source: StaticSource(with: content),
            initial: StaticSource.State(),
            animated: animated
        )
    }
    
    private var sourceChangedTimer : ReloadTimer? = nil
    
    @discardableResult
    public func set<Source:ListViewSource>(source : Source, initial : Source.State, animated : Bool = false) -> StateAccessor<Source.State>
    {
        self.sourcePresenter.discard()
        
        let sourcePresenter = SourcePresenter(initial: initial, source: source, didChange: { [weak self] in
            guard let self = self else { return }
            guard self.sourceChangedTimer == nil else { return }
            
            self.sourceChangedTimer = ReloadTimer {
                self.sourceChangedTimer = nil
                self.setContentFromSource(animated: true)
            }
        })
        
        self.sourcePresenter = sourcePresenter
        
        self.setContentFromSource(animated: animated)
        
        return StateAccessor(get: {
            sourcePresenter.state
        }, set: {
            sourcePresenter.state = $0
        })
    }
    
    public func setProperties(with description : ListDescription)
    {
        let animated = description.animatesChanges
        
        self.appearance = description.appearance
        self.behavior = description.behavior
        self.autoScrollAction = description.autoScrollAction
        self.scrollInsets = description.scrollInsets
        self.collectionView.accessibilityIdentifier = description.accessibilityIdentifier
        self.debuggingIdentifier = description.debuggingIdentifier

        self.set(layoutType: description.layoutType, animated: animated)
        
        self.setContent(animated: animated, description.content)
    }
    
    private func setContentFromSource(animated : Bool = false)
    {
        let oldIdentifier = self.storage.allContent.identifier
        self.storage.allContent = self.sourcePresenter.reloadContent()
        let newIdentifier = self.storage.allContent.identifier
        
        let identifierChanged = oldIdentifier != newIdentifier
        
        self.updatePresentationState(for: .contentChanged(animated: animated, identifierChanged: identifierChanged))
    }
    
    //
    // MARK: UIView
    //
    
    public override var frame: CGRect {
        didSet {
            /**
             Set the frame explicitly, so that the layout can occur
             within performBatchUpdates. Waiting for layoutSubviews() is too late.
             */
            self.collectionView.frame = self.bounds
            
            /**
             Once the view actually has a size, we can provide content.
            
             There's no value in having content with no view size, as we cannot
             size cells otherwise.
             */
            
            let fromEmpty = oldValue.isEmpty && self.bounds.isEmpty == false
            let toEmpty = oldValue.isEmpty == false && self.bounds.isEmpty
            
            if fromEmpty {
                self.updatePresentationState(for: .transitionedToBounds(isEmpty: false))
            } else if toEmpty {
                self.updatePresentationState(for: .transitionedToBounds(isEmpty: true))
            }
        }
    }
    
    public override var backgroundColor: UIColor? {
        didSet {
            self.collectionView.backgroundColor = self.backgroundColor
        }
    }
    
    public override func didMoveToWindow()
    {
        super.didMoveToWindow()
        
        if self.window != nil {
            self.setContentInsetWithKeyboardFrame()
        }
    }
    
    public override func didMoveToSuperview()
    {
        super.didMoveToSuperview()
        
        if self.superview != nil {
            self.setContentInsetWithKeyboardFrame()
        }
    }
    
    override public func layoutSubviews()
    {
        super.layoutSubviews()
        
        self.collectionView.frame = self.bounds
    }
    
    //
    // MARK: Internal - Updating Content
    //
    
    internal func setPresentationStateItemPositions()
    {
        self.storage.presentationState.forEachItem { indexPath, item in
            item.itemPosition = self.layout.positionForItem(at: indexPath)
        }
    }
    
    private func updateCollectionViewSelections(animated : Bool)
    {
        let oldSelected : Set<IndexPath> = Set(self.collectionView.indexPathsForSelectedItems ?? [])
        let newSelected : Set<IndexPath> = Set(self.storage.presentationState.selectedIndexPaths)
        
        let removed = oldSelected.subtracting(newSelected)
        let added = newSelected.subtracting(oldSelected)
        
        let view = self.collectionView
        let state = self.storage.presentationState
        
        removed.forEach {
            let item = state.item(at: $0)
            view.deselectItem(at: $0, animated: animated)
            item.applyToVisibleCell()
        }
        
        added.forEach {
            let item = state.item(at: $0)
            view.selectItem(at: $0, animated: animated, scrollPosition: [])
            item.applyToVisibleCell()
        }
    }
    
    //
    // MARK: Internal - Updating Presentation State
    //
    
    internal func updatePresentationState(
        for reason : Content.Slice.UpdateReason,
        completion callerCompletion : @escaping (Bool) -> () = { _ in }
    ) {
        SignpostLogger.log(.begin, log: .updateContent, name: "List Update", for: self)
        
        let completion = { (completed : Bool) in
            callerCompletion(completed)
            SignpostLogger.log(.end, log: .updateContent, name: "List Update", for: self)
        }
        
        let indexPaths = self.collectionView.indexPathsForVisibleItems
        
        let indexPath = indexPaths.first
        
        let presentationStateTruncated = self.storage.presentationState.containsAllItems == false
        
        switch reason {
        case .scrolledDown:
            let needsUpdate = self.collectionView.isScrolledNearBottom() && presentationStateTruncated
            
            if needsUpdate {
                self.updatePresentationStateWith(firstVisibleIndexPath: indexPath, for: reason, completion: completion)
            } else {
                completion(true)
            }
            
        case .contentChanged:
            self.updatePresentationStateWith(firstVisibleIndexPath: indexPath, for: reason, completion: completion)

        case .didEndDecelerating:
            if presentationStateTruncated {
                self.updatePresentationStateWith(firstVisibleIndexPath: indexPath, for: reason, completion: completion)
            } else {
                completion(true)
            }
            
        case .scrolledToTop:
            if presentationStateTruncated {
                self.updatePresentationStateWith(firstVisibleIndexPath: IndexPath(item: 0, section: 0), for: reason, completion: completion)
            } else {
                completion(true)
            }
            
        case .transitionedToBounds(_):
            self.updatePresentationStateWith(firstVisibleIndexPath: indexPath, for: reason, completion: completion)
            
        case .programaticScrollDownTo(let scrollToIndexPath):
            self.updatePresentationStateWith(firstVisibleIndexPath: scrollToIndexPath, for: reason, completion: completion)
        }
    }
        
    private func updatePresentationStateWith(
        firstVisibleIndexPath indexPath: IndexPath?,
        for reason : Content.Slice.UpdateReason,
        completion callerCompletion : @escaping (Bool) -> ()
        )
    {
        // Figure out visible content.
        
        let presentationState = self.storage.presentationState
        
        let indexPath = indexPath ?? IndexPath(item: 0, section: 0)

        let visibleSlice = self.newVisibleSlice(to: indexPath)

        let diff = SignpostLogger.log(log: .updateContent, name: "Diff Content", for: self) {
            ListView.diffWith(old: presentationState.sectionModels, new: visibleSlice.content.sections)
        }

        let updateBackingData = {
            let dependencies = ItemStateDependencies(reorderingDelegate: self, coordinatorDelegate: self)
            
            presentationState.update(with: diff, slice: visibleSlice, dependencies: dependencies, loggable: self)
        }
        
        // Update Refresh Control
        
        /**
         Update Refresh Control
         
         Note: Must be called *OUTSIDE* of CollectionView's `performBatchUpdates:`, otherwise
         we trigger a bug where updated indexes are calculated incorrectly.
         */
        presentationState.updateRefreshControl(with: visibleSlice.content.refreshControl, in: self.collectionView)
        
        // Update Collection View
        
        self.performBatchUpdates(with: diff, animated: reason.animated, updateBackingData: updateBackingData, completion: callerCompletion)
        
        // Update the visible items.
        
        self.visibleContent.update(with: self)
        
        // Perform any needed auto scroll actions.
        self.performAutoScrollAction(with: diff.changes.addedItemIdentifiers, animated: reason.animated)

        // Update info for new contents.
        
        self.updateCollectionViewSelections(animated: reason.animated)
    }
    
    private func newVisibleSlice(to indexPath : IndexPath) -> Content.Slice
    {
        if self.bounds.isEmpty {
            return Content.Slice()
        } else {
            switch self.autoScrollAction {
            case .scrollToItem(let insertInfo):
                guard let autoScrollIndexPath = self.storage.allContent.indexPath(for: insertInfo.insertedIdentifier) else {
                    fallthrough
                }

                let greaterIndexPath = max(autoScrollIndexPath, indexPath)
                return self.storage.allContent.sliceTo(indexPath: greaterIndexPath)

            case .none:

                return self.storage.allContent.sliceTo(indexPath: indexPath)
            }
        }
    }
    
    private func performAutoScrollAction(with addedItems : Set<AnyIdentifier>, animated : Bool)
    {
        switch self.autoScrollAction {
        case .none:
            return
            
        case .scrollToItem(let info):
            let wasInserted = addedItems.contains(info.insertedIdentifier)
            
            if wasInserted && info.shouldPerform(self.scrollPositionInfo) {
                /// Only animate the scroll if both the update **and** the scroll action are animated.
                let bothAnimate = info.animated && animated
                
                if let destination = info.destination.destination(with: self.content) {
                    self.scrollTo(item: destination, position: info.position, animated: bothAnimate)
                }
            }
        }
    }

    private func preparePresentationStateForScroll(to toIndexPath: IndexPath, scroll: @escaping () -> Void) -> Bool {

        // Make sure we have a last loaded index path.

        guard let lastLoadedIndexPath = self.storage.presentationState.lastIndexPath else {
            return false
        }

        // Update presentation state if needed, then scroll.

        if lastLoadedIndexPath < toIndexPath {
            self.updatePresentationState(for: .programaticScrollDownTo(toIndexPath)) { _ in
                scroll()
            }
        } else {
            scroll()
        }

        return true
    }

    private func performBatchUpdates(
        with diff : SectionedDiff<Section,AnyItem>,
        animated: Bool,
        updateBackingData : @escaping () -> (),
        completion callerCompletion : @escaping (Bool) -> ()
    )
    {
        SignpostLogger.log(.begin, log: .updateContent, name: "Update UICollectionView", for: self)
        
        let completion = { (completed : Bool) in
            callerCompletion(completed)
            SignpostLogger.log(.end, log: .updateContent, name: "Update UICollectionView", for: self)
        }
        
        let view = self.collectionView
        
        let changes = CollectionViewChanges(sectionChanges: diff.changes)
                
        let batchUpdates = {
            updateBackingData()
            // Sections

            view.deleteSections(IndexSet(changes.deletedSections.map { $0.oldIndex }))
            view.insertSections(IndexSet(changes.insertedSections.map { $0.newIndex }))
            
            changes.movedSections.forEach {
                view.moveSection($0.oldIndex, toSection: $0.newIndex)
            }

            // Items
            
            view.deleteItems(at: changes.deletedItems.map { $0.oldIndex })
            view.insertItems(at: changes.insertedItems.map { $0.newIndex })
            
            changes.movedItems.forEach {
                view.moveItem(at: $0.oldIndex, to: $0.newIndex)
            }
            
            self.visibleContent.updateVisibleViews()
        }
        
        if changes.hasIndexAffectingChanges {
            self.cancelInteractiveMovement()
        }
        
        self.layout.setShouldAskForItemSizesDuringLayoutInvalidation()
        
        if animated {
            view.performBatchUpdates(batchUpdates, completion: completion)
        } else {
            UIView.performWithoutAnimation {
                view.performBatchUpdates(batchUpdates, completion: completion)
            }
        }
    }
    
    private static func diffWith(old : [Section], new : [Section]) -> SectionedDiff<Section, AnyItem>
    {
        return SectionedDiff(
            old: old,
            new: new,
            configuration: SectionedDiff.Configuration(
                section: .init(
                    identifier: { $0.info.anyIdentifier },
                    items: { $0.items },
                    movedHint: { $0.info.anyWasMoved(comparedTo: $1.info) }
                ),
                item: .init(
                    identifier: { $0.identifier },
                    updated: { $0.anyIsEquivalent(to: $1) == false },
                    movedHint: { $0.anyWasMoved(comparedTo: $1) }
                )
            )
        )
    }
}


extension ListView : ItemContentCoordinatorDelegate
{
    func coordinatorUpdated(for : AnyItem, animated : Bool)
    {
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.layoutManager.current.setNeedsRelayout()
                self.collectionView.layoutIfNeeded()
            }
        } else {
            self.layoutManager.current.setNeedsRelayout()
        }
    }
}


extension ListView : ReorderingActionsDelegate
{
    //
    // MARK: Internal - Moving Items
    //
    
    func beginInteractiveMovementFor(item : AnyPresentationItemState) -> Bool
    {
        guard let indexPath = self.storage.presentationState.indexPath(for: item) else {
            return false
        }
        
        return self.collectionView.beginInteractiveMovementForItem(at: indexPath)
    }
    
    func updateInteractiveMovementTargetPosition(with recognizer : UIPanGestureRecognizer)
    {
        let position = recognizer.location(in: self.collectionView)
        
        self.collectionView.updateInteractiveMovementTargetPosition(position)
    }
    
    func endInteractiveMovement()
    {
        self.collectionView.endInteractiveMovement()
    }
    
    func cancelInteractiveMovement()
    {
        self.collectionView.cancelInteractiveMovement()
    }
}


extension ListView
{
    final class CollectionView : UICollectionView
    {
        weak var view : ListView?
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            if let view = self.view {
                ///
                /// Update visibility of items and header / footers in the list view.
                ///
                /// This is intentionally performed in `layoutSubviews` of the `UICollectionView`,
                /// **not** within `scrollViewDidScroll`. Why? `visibleContent.update(with:)`
                /// depends on the collection view's layout, which is not updated until it `layoutSubviews`.
                ///
                view.visibleContent.update(with: view)
            }
        }
    }
}


extension ListView : SignpostLoggable
{
    var signpostInfo : SignpostLoggingInfo {
        SignpostLoggingInfo(
            identifier: self.debuggingIdentifier,
            instanceIdentifier: String(format: "%p", unsafeBitCast(self, to: Int.self))
        )
    }
}

extension ListView : KeyboardObserverDelegate
{
    private func setContentInsetWithKeyboardFrame()
    {
        guard let frame = self.keyboardObserver.currentFrame(in: self) else {
            return
        }
        
        let inset : CGFloat
        
        switch frame {
        case .notVisible:
            inset = 0.0
        case .visible(let frame):
            if #available(iOS 11, *) {
                inset = (self.bounds.size.height - frame.origin.y) - self.safeAreaInsets.bottom
            } else {
                inset = (self.bounds.size.height - frame.origin.y)
            }
        }
        
        self.collectionView.contentInset.bottom = inset
        self.collectionView.scrollIndicatorInsets.bottom = inset
    }
    
    //
    // MARK: KeyboardObserverDelegate
    //
    
    func keyboardFrameWillChange(observer : KeyboardObserver)
    {
        self.setContentInsetWithKeyboardFrame()
    }
}

fileprivate extension UIScrollView
{

    func isScrolledNearBottom() -> Bool
    {
        let viewHeight = self.bounds.size.height
        
        // We are within one half view height from the bottom of the content.
        return self.contentOffset.y + (viewHeight * 1.5) > self.contentSize.height
    }
    
    func setAlwaysBounce(_ bounce : Bool, direction : LayoutDirection)
    {
        switch direction {
        case .vertical:
            self.alwaysBounceVertical = bounce
            self.alwaysBounceHorizontal = false
        case .horizontal:
            self.alwaysBounceVertical = false
            self.alwaysBounceHorizontal = bounce
        }
    }
}
