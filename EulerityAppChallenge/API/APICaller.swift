//
//  APICaller.swift
//  EulerityAppChallenge
//
//  Created by Omar Hegazy on 7/20/23.
//

import Foundation

class APICaller {
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
}
