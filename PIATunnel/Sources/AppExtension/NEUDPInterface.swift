//
//  NEUDPInterface.swift
//  PIATunnel
//
//  Created by Davide De Rosa on 8/27/17.
//  Copyright © 2018 London Trust Media. All rights reserved.
//

import Foundation
import NetworkExtension

class NEUDPInterface: LinkInterface {
    private let udp: NWUDPSession
    
    private let maxDatagrams: Int
    
    var remoteAddress: String? {
        guard let endpoint = udp.resolvedEndpoint as? NWHostEndpoint else {
            return nil
        }
        return endpoint.hostname
    }

    var packetBufferSize: Int {
        return maxDatagrams
    }

    init(udp: NWUDPSession, maxDatagrams: Int = 200) {
        self.udp = udp
        self.maxDatagrams = maxDatagrams
    }
    
    func setReadHandler(_ handler: @escaping ([Data]?, Error?) -> Void) {
        udp.setReadHandler(handler, maxDatagrams: maxDatagrams)
    }
    
    func writePacket(_ packet: Data, completionHandler: ((Error?) -> Void)?) {
        udp.writeDatagram(packet) { (error) in
            completionHandler?(error)
        }
    }
    
    func writePackets(_ packets: [Data], completionHandler: ((Error?) -> Void)?) {
        udp.writeMultipleDatagrams(packets) { (error) in
            completionHandler?(error)
        }
    }
}
