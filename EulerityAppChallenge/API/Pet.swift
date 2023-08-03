//
//  APICaller.swift
//  EulerityAppChallenge
//
//  Created by Omar Hegazy on 7/19/23.
//

import Foundation

struct Pet: Decodable {
    let title: String
    let description: String
    let url: URL
    let created: String
}
