//
//  ListLayoutAttributes.swift
//  Listable
//
//  Created by Kyle Van Essen on 6/7/20.
//

import Foundation


public struct ListLayoutAttributes : Equatable {
    
    var contentSize : CGSize
    
    var header : Supplementary?
    var footer : Supplementary?
    var overscrollFooter : Supplementary?
    
    var sections : [Section]
    
    public struct Section : Equatable {
        var frame : CGRect
        
        var header : Supplementary?
        var footer : Supplementary?
        var items : [Item]
    }
    
    public struct Supplementary : Equatable {
        var frame : CGRect
    }
    
    public struct Item : Equatable {
        var frame : CGRect
    }
}
