//
//  ItemPreviewViewTests.swift
//  Listable-Unit-Tests
//
//  Created by Kyle Van Essen on 6/8/20.
//

import XCTest
import Listable



class ItemPreviewViewTests : XCTestCase
{
    func test_view()
    {
        let view = ItemPreviewView(Item(TestContent(text: "Hello, World!")))
        
        print("")
    }
}


fileprivate struct TestContent : ItemContent, Equatable
{
    var text : String
    
    var identifier: Identifier<TestContent> {
        .init(self.text)
    }
    
    func apply(to views: ItemContentViews<TestContent>, for reason: ApplyReason, with info: ApplyItemContentInfo) {
        views.content.text = self.text
    }
    
    typealias ContentView = UILabel
    
    static func createReusableContentView(frame: CGRect) -> UILabel {
        UILabel(frame: frame)
    }
}
