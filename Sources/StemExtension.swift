import Foundation
import SwiftUI

/// Расширение AppModel для добавления методов стемсов, видимых в SwiftUI без dynamicMemberLookup проблем.
extension AppModel {
    func separateStems(for track: Track) {
        Task {
            do {
                let stems = try await CoreMLStemSeparator.separate(trackURL: track.url) { progress in
                    print("Stem separation progress: \(Int(progress * 100))%")
                }
                
                await MainActor.run {
                    guard let currentPlaylistID = selectedPlaylistID,
                          let playlistIndex = state.playlists.firstIndex(where: { $0.id == currentPlaylistID }) else {
                        return
                    }
                    
                    let vocalTrack = Track(
                        url: stems.vocalFileURL,
                        name: "\(track.name) [Вокал]",
                        duration: track.duration
                    )
                    let instTrack = Track(
                        url: stems.instrumentalFileURL,
                        name: "\(track.name) [Инструментал]",
                        duration: track.duration
                    )
                    
                    state.playlists[playlistIndex].tracks.append(vocalTrack)
                    state.playlists[playlistIndex].tracks.append(instTrack)
                    StorageManager.save(state)
                }
            } catch {
                print("Failed to separate stems: \(error)")
            }
        }
    }
}
