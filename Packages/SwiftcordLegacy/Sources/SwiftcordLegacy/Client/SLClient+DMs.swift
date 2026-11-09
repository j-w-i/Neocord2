//
//  File.swift
//  
//
//  Created by JWI on 1/11/2025.
//

import Foundation

extension SLClient {
    ///Function to get the DM Channels, returns an error and an array of channel dictionaries
    public func getDMChannels(completion: @escaping ([[String: Any]], Error?) -> ()) {
        self.request(.getDMChannels) { data, error in
            if let data = data {
                let channelArray = data as? [[String: Any]]
                guard let channelArray = channelArray else { return }
                completion(channelArray, nil)
            }
        }
        
    }
    
    ///Function to get the DM Channels in the format of protocol DMChannel, which is either a GroupDM or a DM struct. Returns a dictionary with ChannelID Snowflake keys and DMChannels.
    public func getDMs(completion: @escaping ([Snowflake: DMChannel], Error?) -> ()) {
        self.getRelationships { relationships, error in
            
            self.getDMChannels() { channelArray, error in
                for channel in channelArray {
                    let type = channel["type"] as? Int
                    switch type {
                    case 1:
                        let dm = DM(self, channel, relationships)
                        
                        guard let dm = dm else { return }
                        
                        self.dms[dm.id!] = dm
                    case 3:
                        let groupDM = GroupDM(self, channel)
                        guard let groupDM = groupDM else {
                            return
                        }
                        self.dms[groupDM.id!] = groupDM
                    default:
                        break
                    }
                }
                completion(self.dms, nil)
            }
            
        }
    }
}
