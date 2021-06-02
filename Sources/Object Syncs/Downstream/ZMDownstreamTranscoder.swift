//
//  ZMDownstreamTranscoder.swift
//  WireRequestStrategy
//
//  Created by Bill, Yiu Por Chan on 02.06.21.
//  Copyright © 2021 Wire GmbH. All rights reserved.
//

import Foundation
import WireTransport

public class ZMDownstreamObjectSync: NSObject, ZMObjectSync {
    
    private weak var transcoder: ZMDownstreamTranscoder?
    private var objectsToDownload: ZMSyncOperationSet?
    private var context: NSManagedObjectContext?
//    private var entity: NSEntityDescription?
//    private var predicateForObjectsToDownload: NSPredicate?
    private var filter: NSPredicate? //additional optional predication to filter objectis by not persisted properties
    private(set) var predicateForObjectsToDownload: NSPredicate?
    private(set) var entity: NSEntityDescription?

    //MARK: ZMObjectSync
    public func objectsDidChange(_ objects: Set<NSManagedObject>) {
        for mo in objects {
            guard let mo = mo as? ZMManagedObject else {
                continue
            }
            if mo.entity != entity {
                continue
            }
            if needs(toSyncObject: mo) {
                objectsToDownload?.addObject(toBeSynchronized: mo)
            }
        }
    }
    
    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entity
        request.predicate = predicateForObjectsToDownload
        return request
    }
    
    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        for mo in objects {
            guard let mo = mo as? ZMManagedObject else {
                continue
            }
            if filter == nil || filter?.evaluate(with: mo) == true {
                objectsToDownload?.addObject(toBeSynchronized: mo)
            }
        }
    }
    
    private func needs(toSyncObject object: NSObject?) -> Bool {
        return predicateForObjectsToDownload?.evaluate(with: object) == true && (filter == nil || filter?.evaluate(with: object) == true)
    }
    
    public var hasOutstandingItems: Bool {
        return 0 < objectsToDownload?.count ?? 0
    }
//    override init() {
//    }

    /// Calls @c -initWithTranscoder:entityName:predicate:managedObjectContext:
    /// with @c predicate set to
    /// @code
    /// [NSPredicate predicateWithFormat:@"needsToBeUpdatedFromBackend == YES"]
    /// @endcode
//    init(
//        transcoder: ZMDownstreamTranscoder?,
//        entityName: String?,
//        managedObjectContext moc: NSManagedObjectContext?
//    ) {
//    }

    /// The @c predicate is used to filter objects that need to be downloaded. It should return
    /// @c YES if the object needs to be downloaded and @c NO otherwise.
//    init(
//        transcoder: ZMDownstreamTranscoder?,
//        entityName: String?,
//        predicateForObjectsToDownload: NSPredicate?,
//        managedObjectContext moc: NSManagedObjectContext?
//    ) {
//    }

//    init(
//        transcoder: ZMDownstreamTranscoder?,
//        entityName: String?,
//        predicateForObjectsToDownload: NSPredicate?,
//        filter: NSPredicate?,
//        managedObjectContext moc: NSManagedObjectContext?
//    ) {
//    }

//    required init(
//        transcoder: ZMDownstreamTranscoder?,
//        operationSet: ZMSyncOperationSet?,
//        entityName: String?,
//        predicateForObjectsToDownload: NSPredicate?,
//        filter: NSPredicate?,
//        managedObjectContext moc: NSManagedObjectContext?
//    ) {
//    }

//    @objc
    public init?(
        transcoder: ZMDownstreamTranscoder?,
        operationSet: ZMSyncOperationSet? = ZMSyncOperationSet(),
        entityName: String?,
        predicateForObjectsToDownload: NSPredicate?,
        filter: NSPredicate? = nil,
        managedObjectContext moc: NSManagedObjectContext?
    ) {
        
        ///TODO: guard
//        VerifyReturnNil(transcoder != nil)
//        VerifyReturnNil(operationSet != nil)
//        VerifyReturnNil(entityName != nil)
//        VerifyReturnNil(predicateForObjectsToDownload != nil)
//        VerifyReturnNil(moc != nil)
        
        
        super.init()
        self.transcoder = transcoder
        objectsToDownload = operationSet
        context = moc
        entity = context!.persistentStoreCoordinator?.managedObjectModel.entitiesByName[entityName ?? ""]
//        VerifyReturnNil(entity != nil)
        
        ///TODO: guard
        objectsToDownload!.sortDescriptors = NSClassFromString(entity!.managedObjectClassName)?.sortDescriptorsForUpdating()
        self.predicateForObjectsToDownload = predicateForObjectsToDownload
        self.filter = filter
    }
    
    
    public func nextRequest() -> ZMTransportRequest? {
        weak var transcoder = self.transcoder

        var nextObject: ZMManagedObject?
        
        while true {
            
            nextObject = objectsToDownload?.nextObjectToSynchronize()
            
            if nextObject == nil {
                break
            }

            if false == predicateForObjectsToDownload?.evaluate(with: nextObject) {
                objectsToDownload?.remove(nextObject)
                continue
            }

            let request = transcoder?.request(forFetching: nextObject, downstreamSync: self)
            if request == nil {
                objectsToDownload?.remove(nextObject)
                continue
            }
            request?.setDebugInformationTranscoder(transcoder as! NSObject)
//            objectsToDownload?.addObject(toBeSynchronized: <#T##ZMManagedObject!#>)
            let token = objectsToDownload?.didStartSynchronizingKeys(nil, for: nextObject)
//            ZM_WEAK(self)
            request?.add(ZMCompletionHandler(on: context!, block: { [weak self] response in
//                ZM_STRONG(self)
                self?.processResponse(response, for: nextObject, token: token, transcoder: self?.transcoder)
            }))
            return request
        }

        return nil
    }
    
    func processResponse(_ response: ZMTransportResponse?, for object: ZMManagedObject?, token: Any?, transcoder: ZMDownstreamTranscoder?) {
        let keys = objectsToDownload?.keysForWhichToApplyResultsAfterFinishedSynchronizingSync(withToken: token, for: object, result: response!.result)
        switch response?.result {
            case .tryAgainLater:
                break
            case .success:
                objectsToDownload?.removeUpdatedObject(object, syncToken: token, synchronizedKeys: keys)

                if false == object?.isZombieObject {
                    transcoder?.update(object, with: response, downstreamSync: self)
                }
            case .temporaryError, .permanentError, .expired:
                objectsToDownload?.remove(object)
                transcoder?.delete(object, with: response, downstreamSync: self)
            default:
                break
        }
        object?.managedObjectContext?.enqueueDelayedSave(with: response?.dispatchGroup)
    }
}

public protocol ZMDownstreamTranscoder: NSObjectProtocol {
    func request(forFetching object: ZMManagedObject!, downstreamSync: ZMObjectSync!) -> ZMTransportRequest!
    func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!)
    func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!)
}
