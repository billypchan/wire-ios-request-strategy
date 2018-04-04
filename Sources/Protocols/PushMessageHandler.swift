//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import WireDataModel

@objc public protocol PushMessageHandler: NSObjectProtocol {
    
    /// Create a notification for the message if needed
    ///
    /// - Parameter genericMessage: generic message that was received
    @objc(processGenericMessage:)
    func process(_ genericMessage: ZMGenericMessage)
    
    
    /// Creates a notification for the message if needed
    ///
    /// - Parameter message: message that was received
    @objc(processMessage:)
    func process(_ message: ZMMessage)
    
    
    /// Shows a notification for a failure to send
    ///
    /// - Parameter message: message that failed to send
    func didFailToSend(_ message: ZMMessage)
}
