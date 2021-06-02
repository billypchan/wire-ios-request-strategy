//
//  ZMDownstreamObjectSyncWithWhitelist.swift
//  WireRequestStrategy
//
//  Created by Bill, Yiu Por Chan on 02.06.21.
//  Copyright © 2021 Wire GmbH. All rights reserved.
//

import Foundation

//class ZMDownstreamObjectSyncWithWhitelist: ZMDownstreamTranscoder {
//}

public class ZMDownstreamObjectSyncWithWhitelist: NSObject, ZMObjectSync, ZMDownstreamTranscoder {
    public func request(forFetching object: ZMManagedObject!, downstreamSync: ZMObjectSync!) -> ZMTransportRequest! {
        return transcoder?.request(forFetching: object, downstreamSync: self)
    }
    
    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
         transcoder?.delete(object, with: response, downstreamSync: self)
    }
    
    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        transcoder?.update(object, with: response, downstreamSync: self)
    }
    
    public func objectsDidChange(_ objects: Set<NSManagedObject>) {
        ///TODO: check conversion
        let whitelistedObjectsThatChanges: NSMutableSet = NSMutableSet(object: whitelist!)
        
        
        whitelistedObjectsThatChanges.intersect(objects)
        innerDownstreamSync?.objectsDidChange(whitelistedObjectsThatChanges as! Set<NSManagedObject>)
    }
    
    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        // I don't want to fetch. Only objects that are whitelisted should go through
        return nil
    }
    
    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        // no-op
    }
    
    public var hasOutstandingItems: Bool
//    func hasOutstandingItems() -> Bool
    {
        return innerDownstreamSync?.hasOutstandingItems ?? false
    }
    private var whitelist: NSMutableSet?
    
    /// actually it is alway created when init, but it is depends on self so it has to be a var
    private var innerDownstreamSync: ZMDownstreamObjectSync?
    
    private weak var transcoder: ZMDownstreamTranscoder?

    /// @param predicateForObjectsToDownload the predicate that will be used to select which object to download
    public init(
        transcoder: ZMDownstreamTranscoder?,
        entityName: String?,
        predicateForObjectsToDownload: NSPredicate?,
        managedObjectContext moc: NSManagedObjectContext?
    ) {
        super.init()
        
        self.transcoder = transcoder
        innerDownstreamSync = ZMDownstreamObjectSync(transcoder: self, entityName: entityName, predicateForObjectsToDownload: predicateForObjectsToDownload, filter: nil, managedObjectContext: moc)!
        whitelist = []

    }

    /// Adds an object to the whitelist. It will later be removed once downloaded and not matching the whitelist predicate
    public func whiteListObject(_ object: ZMManagedObject) {
        whitelist?.add(object)
        innerDownstreamSync?.objectsDidChange(
             Set<NSManagedObject>([object])
        )
    }

    /// Returns a request to download the next object
    public func nextRequest() -> ZMTransportRequest? {
        return innerDownstreamSync?.nextRequest()
    }
}
