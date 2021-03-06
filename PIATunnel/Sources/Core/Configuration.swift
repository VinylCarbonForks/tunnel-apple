//
//  Configuration.swift
//  PIATunnel
//
//  Created by Davide De Rosa on 9/1/17.
//  Copyright © 2018 London Trust Media. All rights reserved.
//

import Foundation

struct Configuration {
    
    // MARK: Session
    
    static let logsSensitiveData = false

    static let usesReplayProtection = true

    static let usesDataOptimization = true

    static let tickInterval = 0.2
    
    static let hardResetTimeout = 2.0
    
    static let connectionTimeout = 10.0
    
    static let pingInterval = 10.0
    
    static let pingTimeout = 120.0
    
    static let retransmissionLimit = 0.1
    
    static let softResetDelay = 5.0
    
    static let softConnectionTimeout = 120.0
    
    static let maxOutLength = 1000

    // MARK: Authentication
    
    static let peerInfo = "IV_VER=2.3.98\n"
    
    static let randomLength = 32
    
    // MARK: Keys
    
    static let label1 = "OpenVPN master secret"
    
    static let label2 = "OpenVPN key expansion"
    
    static let preMasterLength = 48
    
    static let keyLength = 64
    
    static let keysCount = 4
}
