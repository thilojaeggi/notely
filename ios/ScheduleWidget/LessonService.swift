//
//  LessonService.swift
//  ScheduleWidgetExtension
//
//  Created by Thilo on 07.08.22.
//

import Foundation

public struct LessonService {
    public static func getStatus(client: NetworkClient, completion: (([Lesson]) -> Void)? = nil) {
        runStatusRequest(.lesson, on: client, completion: completion)
    }

    private static func runStatusRequest(_ request: URLRequest,
                                         on client: NetworkClient,
                                         completion: (([Lesson]) -> Void)? = nil) {
        client.executeRequest(request: request) { result in
            switch result {
            case .success(let data):
                let decoder = JSONDecoder()
                do {
                    let lesson = try decoder.decode([Lesson].self, from: data)
                    completion?(lesson)
                } catch {
                    print(error.localizedDescription)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
