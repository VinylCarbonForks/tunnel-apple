//
//  EncryptionProxy.swift
//  PIATunnel
//
//  Created by Davide De Rosa on 2/8/17.
//  Copyright © 2018 London Trust Media. All rights reserved.
//

import Foundation
import __PIATunnelNative

/// Bridges native encryption for high-level operations.
public class EncryptionProxy {
    private let box: CryptoBox
    
    /**
     Initializes the PRNG. Must be issued before using `SessionProxy`.
 
     - Parameter seedLength: The length in bytes of the pseudorandom seed that will feed the PRNG.
     */
    public static func prepareRandomNumberGenerator(seedLength: Int) -> Bool {
        let seed: ZeroingData
        do {
            seed = try SecureRandom.safeData(length: seedLength)
        } catch {
            return false
        }
        return CryptoBox.preparePRNG(withSeed: seed.bytes, length: seed.count)
    }
    
    // Ruby: keys_prf
    private static func keysPRF(_ label: String,
                                _ secret: ZeroingData,
                                _ clientSeed: ZeroingData,
                                _ serverSeed: ZeroingData,
                                _ clientSessionId: Data?,
                                _ serverSessionId: Data?,
                                _ size: Int) -> ZeroingData {
        
        let seed = Z(label)
        seed.append(clientSeed)
        seed.append(serverSeed)
        if let csi = clientSessionId {
            seed.append(Z(csi))
        }
        if let ssi = serverSessionId {
            seed.append(Z(ssi))
        }
        let len = secret.count / 2
        let lenx = len + (secret.count & 1)
        let secret1 = secret.withOffset(0, count: lenx)!
        let secret2 = secret.withOffset(len, count: lenx)!
        
        let hash1 = keysHash("md5", secret1, seed, size)
        let hash2 = keysHash("sha1", secret2, seed, size)
        
        let prf = Z()
        for i in 0..<hash1.count {
            let h1 = hash1.bytes[i]
            let h2 = hash2.bytes[i]
            
            prf.append(Z(h1 ^ h2))
        }
        return prf
    }
    
    // Ruby: keys_hash
    private static func keysHash(_ digestName: String, _ secret: ZeroingData, _ seed: ZeroingData, _ size: Int) -> ZeroingData {
        let out = Z()
        let buffer = Z(count: CryptoBoxMaxHMACLength)
        var chain = EncryptionProxy.hmac(buffer, digestName, secret, seed)
        while (out.count < size) {
            out.append(EncryptionProxy.hmac(buffer, digestName, secret, chain.appending(seed)))
            chain = EncryptionProxy.hmac(buffer, digestName, secret, chain)
        }
        return out.withOffset(0, count: size)
    }
    
    // Ruby: hmac
    private static func hmac(_ buffer: ZeroingData, _ digestName: String, _ secret: ZeroingData, _ data: ZeroingData) -> ZeroingData {
        var length = 0
        
        CryptoBox.hmac(withDigestName: digestName,
                       secret: secret.bytes,
                       secretLength: secret.count,
                       data: data.bytes,
                       dataLength: data.count,
                       hmac: buffer.mutableBytes,
                       hmacLength: &length)
        
        return buffer.withOffset(0, count: length)
    }
    
    convenience init(_ cipher: String, _ digest: String, _ auth: Authenticator,
                     _ sessionId: Data, _ remoteSessionId: Data) {
        
        guard let serverRandom1 = auth.serverRandom1, let serverRandom2 = auth.serverRandom2 else {
            fatalError("Configuring encryption without server randoms")
        }
        
        let masterData = EncryptionProxy.keysPRF(Configuration.label1, auth.preMaster, auth.random1,
                                                 serverRandom1, nil, nil,
                                                 Configuration.preMasterLength)
        
        let keysData = EncryptionProxy.keysPRF(Configuration.label2, masterData, auth.random2,
                                               serverRandom2, sessionId, remoteSessionId,
                                               Configuration.keysCount * Configuration.keyLength)
        
        var keysArray = [ZeroingData]()
        for i in 0..<Configuration.keysCount {
            let offset = i * Configuration.keyLength
            let zbuf = keysData.withOffset(offset, count: Configuration.keyLength)!
            keysArray.append(zbuf)
        }
        
        let cipherEncKey = keysArray[0]
        let hmacEncKey = keysArray[1]
        let cipherDecKey = keysArray[2]
        let hmacDecKey = keysArray[3]
        
        self.init(cipher, digest, cipherEncKey, cipherDecKey, hmacEncKey, hmacDecKey)
    }
    
    init(_ cipher: String, _ digest: String, _ cipherEncKey: ZeroingData, _ cipherDecKey: ZeroingData, _ hmacEncKey: ZeroingData, _ hmacDecKey: ZeroingData) {
        box = CryptoBox(cipherAlgorithm: cipher, digestAlgorithm: digest)
        box.configure(withCipherEncKey: cipherEncKey.bytes, cipherDecKey: cipherDecKey.bytes, hmacEncKey: hmacEncKey.bytes, hmacDecKey: hmacDecKey.bytes)
    }
    
    func encrypter() -> Encrypter {
        return box.encrypter()
    }

    func decrypter() -> Decrypter {
        return box.decrypter()
    }
}
