//import Foundation
//
//class OArray<Element> : CollectionType, Indexable, SequenceType, MutableCollectionType, _DestructorSafeContainer {
//    
//    private var _count:Int = 0
//    private var _capacity:Int = 10
//    private var _minimumCapacity:Int = 10
//    private var _pointer:UnsafeMutablePointer<Element>
//    
//    /// Construct an empty Array.
//    init() {
//        _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
//    }
//    
//    /// Construct from an arbitrary sequence with elements of type `Element`.
//    init<S : SequenceType where S.Generator.Element == Element>(_ s: S) {
//        _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
//        var generate = s.generate()
//        while let element:Element = generate.next() {
//            self.append(element)
//        }
//    }
//    
//    /// Construct a Array of `count` elements, each initialized to
//    /// `repeatedValue`.
//    init(count: Int, repeatedValue: Element) {
//        _pointer = UnsafeMutablePointer<Element>.alloc(count)
//        for var i:Int = 0; i < count; i++ {
//            _pointer.advancedBy(i).initialize(repeatedValue)
//        }
//        _capacity = count
//        _count = count
//    }
//    
//    init(capacity: Int) {
//        _capacity = capacity
//        _minimumCapacity = capacity
//        _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
//    }
//    
//    deinit {
//        _pointer.destroy(_count)
//        _pointer.dealloc(_capacity)
//        _pointer = nil
//    }
//    
//    /// Always zero, which is the index of the first element when non-empty.
//    var startIndex: Int { return 0 }
//    
//    /// A "past-the-end" element index; the successor of the last valid
//    /// subscript argument.
//    var endIndex: Int { return _count - 1 }
//    
//    subscript (index: Int) -> Element {
//        get {
////            if index >= _count {
////                fatalError("index(\(index)) out of count(\(_count))")
////            }
//            return _pointer.advancedBy(index).memory
//        }
//        set {
////            if index >= _count {
////                fatalError("index(\(index)) out of count(\(_count))")
////            }
//            _pointer.advancedBy(index).memory = newValue
//        }
//    }
//    
//    
//    /// A type that can represent a sub-range of an `Array`.
////    typealias SubSlice = ArraySlice<Element>
////    subscript (subRange: Range<Int>) -> SubSlice {
////        
////    }
//}
//
//extension OArray  {
//    
//    
//    /// The number of elements the Array stores.
//    var count: Int { return _count }
//    
//    /// The number of elements the `Array` can store without reallocation.
//    var capacity: Int { return _capacity }
//    
//    /// Reserve enough space to store `minimumCapacity` elements.
//    ///
//    /// - Postcondition: `capacity >= minimumCapacity` and the array has
//    ///   mutable contiguous storage.
//    ///
//    /// - Complexity: O(`count`).
//    func reserveCapacity(minimumCapacity: Int) {
//        _minimumCapacity = minimumCapacity
//        if _capacity >= minimumCapacity && _count < _minimumCapacity {
//            resizeUnsafeCapacity(minimumCapacity)
//        } else if _capacity < minimumCapacity {
//            resizeUnsafeCapacity(minimumCapacity)
//        }
//    }
//    
//    private func resizeUnsafeCapacity(minimumCapacity: Int) {
//        let pointer = UnsafeMutablePointer<Element>.alloc(minimumCapacity)
//        pointer.moveInitializeBackwardFrom(_pointer, count: _count)
//        _pointer.dealloc(_capacity)
//        _pointer = pointer
//        _capacity = minimumCapacity
//    }
//    
//    
//    /// Append `newElement` to the Array.
//    ///
//    /// - Complexity: Amortized O(1) unless `self`'s storage is shared with another live array; O(`count`) if `self` does not wrap a bridged `NSArray`; otherwise the efficiency is unspecified..
//    func append(newElement: Element) {
//        if _count == _capacity {
//            resizeUnsafeCapacity(Int(Double(_count) * 1.6) + 1)
//        }
//        _pointer.advancedBy(_count++).initialize(newElement)
//    }
//    
//    /// Append the elements of `newElements` to `self`.
//    ///
//    /// - Complexity: O(*length of result*).
//    func extend<S : SequenceType where S.Generator.Element == Element>(newElements: S) {
//        var generate = newElements.generate()
//        while let element:Element = generate.next() {
//            self.append(element)
//        }
//    }
//    
//    /// Append the elements of `newElements` to `self`.
//    ///
//    /// - Complexity: O(*length of result*).
//    func extend<C : CollectionType where C.Generator.Element == Element>(newElements: C) {
//        for element in newElements {
//            append(element)
//        }
//    }
//    
//    /// Remove an element from the end of the Array in O(1).
//    ///
//    /// - Requires: `count > 0`.
//    func removeLast() -> Element {
//        if _count == 0 {
//            fatalError("can't remove last because count is zero")
//        }
//        let lastPointer = _pointer.advancedBy(--_count)
//        let element = lastPointer.memory
//        lastPointer.destroy()
//        return element
//    }
//    
//    /// Insert `newElement` at index `i`.
//    ///
//    /// - Requires: `i <= count`.
//    ///
//    /// - Complexity: O(`count`).
//    func insert(newElement: Element, atIndex i: Int) {
//        
//    }
//    
//    /// Remove and return the element at index `i`.
//    ///
//    /// Invalidates all indices with respect to `self`.
//    ///
//    /// - Complexity: O(`count`).
//    func removeAtIndex(index: Int) -> Element {
//        return _pointer.memory
//    }
//    
//    /// Remove all elements.
//    ///
//    /// - Postcondition: `capacity == 0` iff `keepCapacity` is `false`.
//    ///
//    /// - Complexity: O(`self.count`).
//    func removeAll(keepCapacity keepCapacity: Bool = false) {
//        _pointer.destroy(_count)
//        if !keepCapacity {
//            _pointer.dealloc(_capacity)
//            _capacity = _minimumCapacity
//            _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
//        }
//    }
//    
//    /// Interpose `self` between each consecutive pair of `elements`,
//    /// and concatenate the elements of the resulting sequence.  For
//    /// example, `[-1, -2].join([[1, 2, 3], [4, 5, 6], [7, 8, 9]])`
//    /// yields `[1, 2, 3, -1, -2, 4, 5, 6, -1, -2, 7, 8, 9]`.
//    func join<S : SequenceType where S.Generator.Element == Array<Element>>(elements: S) -> [Element] {
//        return []
//    }
//}
//////
//////  LinkedDictionary.swift
//////  ToastDemo
//////
//////  Created by 招利 李 on 15/8/2.
//////  Copyright © 2015年 招利 李. All rights reserved.
//////
////
////import Foundation
////
////struct OrderedDictionary<Key : Hashable, Value> : CollectionType, Indexable, SequenceType, DictionaryLiteralConvertible {
////    
////    typealias Element = (Key, Value)
////    typealias Index = DictionaryIndex<Key, Value>
////    
////    
////    
////    private var _keys:Set<Key>
////    private var _values:Array<Value>
////    /// Create an empty dictionary.
////    init() {
////        _keys = Set<Key>()
////        _values = [Value]()
////        
////        let point = UnsafeMutablePointer<Element>.alloc(1)
////        point.move
////        let pp = UnsafeMutableBufferPointer<Element>(start: point, count: 1)
////        
////    }
////    
////    /// Create a dictionary with at least the given number of
////    /// elements worth of storage.  The actual capacity will be the
////    /// smallest power of 2 that's >= `minimumCapacity`.
////    init(minimumCapacity: Int) {
////        _keys = Set<Key>(minimumCapacity: minimumCapacity)
////        _values = Array<Value>()
////    }
////    
////    /// The position of the first element in a non-empty dictionary.
////    ///
////    /// Identical to `endIndex` in an empty dictionary.
////    ///
////    /// - Complexity: Amortized O(1) if `self` does not wrap a bridged
////    ///   `NSDictionary`, O(N) otherwise.
////    var startIndex: DictionaryIndex<Key, Value> {
////        
////    }
////    
////    /// The collection's "past the end" position.
////    ///
////    /// `endIndex` is not a valid argument to `subscript`, and is always
////    /// reachable from `startIndex` by zero or more applications of
////    /// `successor()`.
////    ///
////    /// - Complexity: Amortized O(1) if `self` does not wrap a bridged
////    ///   `NSDictionary`, O(N) otherwise.
////    var endIndex: DictionaryIndex<Key, Value> {
////    
////    }
////    
////    /// Returns the `Index` for the given key, or `nil` if the key is not
////    /// present in the dictionary.
////    func indexForKey(key: Key) -> DictionaryIndex<Key, Value>? {
////        
////    }
////    
////    subscript (position: DictionaryIndex<Key, Value>) -> (Key, Value) {
////    
////    }
////    
////    subscript (key: Key) -> Value? {
////        
////    }
////    
////    /// Update the value stored in the dictionary for the given key, or, if they
////    /// key does not exist, add a new key-value pair to the dictionary.
////    ///
////    /// Returns the value that was replaced, or `nil` if a new key-value pair
////    /// was added.
////    mutating func updateValue(value: Value, forKey key: Key) -> Value? {
////        
////    }
////    
////    /// Remove the key-value pair at `index`.
////    ///
////    /// Invalidates all indices with respect to `self`.
////    ///
////    /// - Complexity: O(`count`).
////    mutating func removeAtIndex(index: DictionaryIndex<Key, Value>) {
////        
////    }
////    
////    /// Remove a given key and the associated value from the dictionary.
////    /// Returns the value that was removed, or `nil` if the key was not present
////    /// in the dictionary.
////    mutating func removeValueForKey(key: Key) -> Value? {
////        
////    }
////    
////    /// Remove all elements.
////    ///
////    /// - Postcondition: `capacity == 0` if `keepCapacity` is `false`, otherwise
////    ///   the capacity will not be decreased.
////    ///
////    /// Invalidates all indices with respect to `self`.
////    ///
////    /// - parameter keepCapacity: If `true`, the operation preserves the
////    ///   storage capacity that the collection has, otherwise the underlying
////    ///   storage is released.  The default is `false`.
////    ///
////    /// Complexity: O(`count`).
////    mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
////    }
////    
////    /// The number of entries in the dictionary.
////    ///
////    /// - Complexity: O(1).
////    var count: Int { return 0 }
////    
////    /// Return a *generator* over the (key, value) pairs.
////    ///
////    /// - Complexity: O(1).
////    func generate() -> DictionaryGenerator<Key, Value> {}
////    
////    /// Create an instance initialized with `elements`.
////    init(dictionaryLiteral elements: (Key, Value)...) {
////        
////    }
////    
////    /// A collection containing just the keys of `self`.
////    ///
////    /// Keys appear in the same order as they occur as the `.0` member
////    /// of key-value pairs in `self`.  Each key in the result has a
////    /// unique value.
//////    var keys: LazyForwardCollection<MapCollection<[Key : Value], Key>> {
//////        return LazyForwardCollection<MapCollection<[Key : Value], Key>>(keys)
//////    }
////    
////    /// A collection containing just the values of `self`.
////    ///
////    /// Values appear in the same order as they occur as the `.1` member
////    /// of key-value pairs in `self`.
//////    var values: LazyForwardCollection<MapCollection<[Key : Value], Value>> {
//////    }
////    
////    /// `true` iff `count == 0`.
////    var isEmpty: Bool { count == 0 }
////}
////
