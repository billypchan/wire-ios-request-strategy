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

class ZMDownstreamObjectSyncWithWhitelist: NSObject, ZMObjectSync, ZMDownstreamTranscoder {
    func request(forFetching object: ZMManagedObject!, downstreamSync: ZMObjectSync!) -> ZMTransportRequest! {
        return transcoder?.request(forFetching: object, downstreamSync: self)
    }
    
    func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
         transcoder?.delete(object, with: response, downstreamSync: self)
    }
    
    func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        transcoder?.update(object, with: response, downstreamSync: self)
    }
    
    func objectsDidChange(_ objects: Set<NSManagedObject>) {
        ///TODO: check conversion
        let whitelistedObjectsThatChanges: NSMutableSet = NSMutableSet(object: whitelist!)
        
        
        whitelistedObjectsThatChanges.intersect(objects)
        innerDownstreamSync?.objectsDidChange(whitelistedObjectsThatChanges as! Set<NSManagedObject>)
    }
    
    func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        // I don't want to fetch. Only objects that are whitelisted should go through
        return nil
    }
    
    func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        // no-op
    }
    
    var hasOutstandingItems: Bool
//    func hasOutstandingItems() -> Bool
    {
        return innerDownstreamSync?.hasOutstandingItems ?? false
    }
    private var whitelist: Set<AnyHashable>?
    
    /// actually it is alway created when init, but it is depends on self so it has to be a var
    private var innerDownstreamSync: ZMDownstreamObjectSync?
    
    private weak var transcoder: ZMDownstreamTranscoder?

    /// @param predicateForObjectsToDownload the predicate that will be used to select which object to download
    init(
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
    func whiteListObject(_ object: ZMManagedObject?) {
    }

    /// Returns a request to download the next object
    func nextRequest() -> ZMTransportRequest? {
        return innerDownstreamSync?.nextRequest()
    }
}
