////
////  OrderedSet.swift
////  ToastDemo
////
////  Created by 招利 李 on 15/8/2.
////  Copyright © 2015年 招利 李. All rights reserved.
////
//
//import Foundation
//
//struct OrderedSet<Element : Hashable> : Hashable, Equatable, CollectionType, Indexable, SequenceType, ArrayLiteralConvertible {
//    typealias Index = Int
//    
//    private var indexMap:[Int:Index]
//    private var contents:[UnsafeMutablePointer<Element>] = []
//    
//    /// Create an empty set with at least the given number of
//    /// elements worth of storage.  The actual capacity will be the
//    /// smallest power of 2 that's >= `minimumCapacity`.
//    init(minimumCapacity: Int) {
//        indexMap = [Int:Index](minimumCapacity: minimumCapacity)
//    }
//    
//    /// The position of the first element in a non-empty set.
//    ///
//    /// This is identical to `endIndex` in an empty set.
//    ///
//    /// - Complexity: Amortized O(1) if `self` does not wrap a bridged
//    ///   `NSSet`, O(N) otherwise.
//    var startIndex: Index { return 0 }
//    
//    /// The collection's "past the end" position.
//    ///
//    /// `endIndex` is not a valid argument to `subscript`, and is always
//    /// reachable from `startIndex` by zero or more applications of
//    /// `successor()`.
//    ///
//    /// - Complexity: Amortized O(1) if `self` does not wrap a bridged
//    ///   `NSSet`, O(N) otherwise.
//    var endIndex: Index { return contents.count - 1 }
//    
//    /// Returns `true` if the set contains a member.
//    func contains(member: Element) -> Bool {
//        return indexMap[member.hashValue] != nil
//    }
//    
//    /// Returns the `Index` of a given member, or `nil` if the member is not
//    /// present in the set.
//    func indexOf(member: Element) -> Index? {
//        return indexMap[member.hashValue]
//    }
//    
//    /// Insert a member into the set.
//    mutating func insert(member: Element, atIndex:Index) {
//        
//    }
//    mutating func append(member: Element) {
//        let hashValue = member.hashValue
//        if indexMap[hashValue] != nil { return }
//        
//        indexMap[hashValue] = contents.count
//        
//        let pointer = UnsafeMutablePointer<Element>.alloc(1)
//        pointer.initialize(member)
//        contents.append(pointer)
//    }
//    
//    /// Remove the member from the set and return it if it was present.
//    mutating func remove(member: Element) -> Element?
//    
//    /// Remove the member referenced by the given index.
//    mutating func removeAtIndex(index: SetIndex<Element>)
//    
//    /// Erase all the elements.  If `keepCapacity` is `true`, `capacity`
//    /// will not decrease.
//    mutating func removeAll(keepCapacity keepCapacity: Bool = default)
//    
//    /// Remove a member from the set and return it.
//    ///
//    /// - Requires: `count > 0`.
//    mutating func removeFirst() -> Element
//    
//    /// The number of members in the set.
//    ///
//    /// - Complexity: O(1).
//    var count: Int { get }
//    subscript (position: SetIndex<Element>) -> Element { get }
//    
//    /// Return a *generator* over the members.
//    ///
//    /// - Complexity: O(1).
//    func generate() -> SetGenerator<Element>
//    init(arrayLiteral elements: Element...)
//    
//    /// Create an empty `Set`.
//    init()
//    
//    /// Create a `Set` from a finite sequence of items.
//    init<S : SequenceType where S.Generator.Element == Element>(_ sequence: S)
//    
//    /// Returns true if the set is a subset of a finite sequence as a `Set`.
//    func isSubsetOf<S : SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool
//    
//    /// Returns true if the set is a subset of a finite sequence as a `Set`
//    /// but not equal.
//    func isStrictSubsetOf<S : SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool
//    
//    /// Returns true if the set is a superset of a finite sequence as a `Set`.
//    func isSupersetOf<S : SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool
//    
//    /// Returns true if the set is a superset of a finite sequence as a `Set`
//    /// but not equal.
//    func isStrictSupersetOf<S : SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool
//    
//    /// Returns true if no members in the set are in a finite sequence as a `Set`.
//    func isDisjointWith<S : SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool
//    
//    /// Return a new `Set` with items in both this set and a finite sequence.
//    func union<S : SequenceType where S.Generator.Element == Element>(sequence: S) -> Set<Element>
//    
//    /// Insert elements of a finite sequence into this `Set`.
//    mutating func unionInPlace<S : SequenceType where S.Generator.Element == Element>(sequence: S)
//    
//    /// Return a new set with elements in this set that do not occur
//    /// in a finite sequence.
//    func subtract<S : SequenceType where S.Generator.Element == Element>(sequence: S) -> Set<Element>
//    
//    /// Remove all members in the set that occur in a finite sequence.
//    mutating func subtractInPlace<S : SequenceType where S.Generator.Element == Element>(sequence: S)
//    
//    /// Return a new set with elements common to this set and a finite sequence.
//    func intersect<S : SequenceType where S.Generator.Element == Element>(sequence: S) -> Set<Element>
//    
//    /// Remove any members of this set that aren't also in a finite sequence.
//    mutating func intersectInPlace<S : SequenceType where S.Generator.Element == Element>(sequence: S)
//    
//    /// Return a new set with elements that are either in the set or a finite
//    /// sequence but do not occur in both.
//    func exclusiveOr<S : SequenceType where S.Generator.Element == Element>(sequence: S) -> Set<Element>
//    
//    /// For each element of a finite sequence, remove it from the set if it is a
//    /// common element, otherwise add it to the set. Repeated elements of the
//    /// sequence will be ignored.
//    mutating func exclusiveOrInPlace<S : SequenceType where S.Generator.Element == Element>(sequence: S)
//    var hashValue: Int { get }
//    
//    /// `true` if the set is empty.
//    var isEmpty: Bool { get }
//    
//    /// The first element obtained when iterating, or `nil` if `self` is
//    /// empty.  Equivalent to `self.generate().next()`.
//    var first: Element? { get }
//}
//
//extension OrderedSet : CustomStringConvertible, CustomDebugStringConvertible {
//    
//    /// A textual representation of `self`.
//    var description: String { get }
//    
//    /// A textual representation of `self`, suitable for debugging.
//    var debugDescription: String { get }
//}
//
//extension OrderedSet : _Reflectable {
//}
