//
//  APICaller.swift
//  EulerityAppChallenge
//
//  Created by Omar Hegazy on 7/20/23.
//

import Foundation

class APICaller {
    
    // MARK: - GET Request
    
    static func fetchPetsData(completion: @escaping ([Pet]?, Error?) -> Void) {
        let apiUrl = URL(string: "https://eulerity-hackathon.appspot.com/pets")!
        
        URLSession.shared.dataTask(with: apiUrl) { data, _, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "com.example.app", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                let pets = try JSONDecoder().decode([Pet].self, from: data)
                completion(pets, nil)
            } catch {
                completion(nil, error)
            }
        }
        .resume()
    }
    
    // MARK: - POST Request
    
    static func getUploadURL(completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://eulerity-hackathon.appspot.com/upload")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let uploadURL = json?["url"] as? String {
                        completion(.success(uploadURL))
                    } else {
                        let error = NSError(domain: "APICaller", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from the server"])
                        completion(.failure(error))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    static func uploadImage(imageURL: URL, appID: String, originalURL: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let imageFileData = try? Data(contentsOf: imageURL) else {
            let error = NSError(domain: "APICaller", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to load image file data"])
            completion(.failure(error))
            return
        }
        
        APICaller.getUploadURL { result in
            switch result {
            case .success(let uploadURL):
                var request = URLRequest(url: URL(string: uploadURL)!)
                request.httpMethod = "POST"
                let boundary = UUID().uuidString
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                var bodyData = Data()
                bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
                bodyData.append("Content-Disposition: form-data; name=\"appid\"\r\n\r\n".data(using: .utf8)!)
                bodyData.append(appID.data(using: .utf8)!)
                bodyData.append("\r\n".data(using: .utf8)!)
                
                
                bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
                bodyData.append("Content-Disposition: form-data; name=\"original\"\r\n\r\n".data(using: .utf8)!)
                bodyData.append(originalURL.data(using: .utf8)!)
                bodyData.append("\r\n".data(using: .utf8)!)
                
                bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
                bodyData.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
                bodyData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                bodyData.append(imageFileData)
                bodyData.append("\r\n".data(using: .utf8)!)
                
                bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
                
                request.httpBody = bodyData
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                        completion(.success(true))
                    } else {
                        let error = NSError(domain: "APICaller", code: -5, userInfo: [NSLocalizedDescriptionKey: "Image upload failed"])
                        completion(.failure(error))
                    }
                }
                
                task.resume()
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
