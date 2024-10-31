import Foundation
import Alamofire

class NetworkManager {
    static let shared = NetworkManager()

    func sendMessageWithStreaming(request: MessageRequest, onChunkReceived: @escaping (String) -> Void, completion: @escaping (Result<String, Error>) -> Void) {
        let url = "https://achatappapi-482205929947.us-central1.run.app/api/chat/send"

        let headers: HTTPHeaders = [
            "Authorization": "Bearer senin_token", 
            "Content-Type": "application/json"
        ]

        AF.request(url, method: .post, parameters: request, encoder: JSONParameterEncoder.default, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    if let jsonString = String(data: data, encoding: .utf8) {
                        let cleanedMessage = jsonString
                            .components(separatedBy: "\n")
                            .filter { $0.hasPrefix("data: ") }
                            .map { $0.replacingOccurrences(of: "data: ", with: "") }
                            .joined()

                        onChunkReceived(cleanedMessage)
                    }
                    completion(.success("Stream tamamlandı"))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
