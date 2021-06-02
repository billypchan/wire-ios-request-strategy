//
//  ZMAbstractRequestStrategy.swift
//  WireRequestStrategy
//
//  Created by Bill, Yiu Por Chan on 02.06.21.
//  Copyright © 2021 Wire GmbH. All rights reserved.
//

import Foundation

extension ZMAbstractRequestStrategy: RequestStrategy {
    public func nextRequest() -> ZMTransportRequest? {
        if configuration(configuration, isSubsetOfPrerequisites: AbstractRequestStrategy.prerequisites(forApplicationStatus: applicationStatus)) {
            return nextRequestIfAllowed()
        }

        return nil
    }
}
