import Foundation

class ChatViewModel {
    var onMessageReceived: ((String) -> Void)?
    var onStreamCompleted: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    func sendMessage(message: String) {
        let request = MessageRequest(message: message)
        
        NetworkManager.shared.sendMessageWithStreaming(
            request: request,
            onChunkReceived: { [weak self] chunk in
                self?.onMessageReceived?(chunk)
            },
            completion: { [weak self] result in
                switch result {
                case .success(_):
                    self?.onStreamCompleted?()
                case .failure(let error):
                    self?.onError?(error)
                }
            }
        )
    }
}
