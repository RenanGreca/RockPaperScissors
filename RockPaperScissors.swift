//
//  RockPaperScissors.swift
//
//
//  Created by Renan Greca on 06/02/2019.
//

import Foundation

let noPlayers:Int
if CommandLine.argc > 1,
   let val = Int(CommandLine.arguments[1]) {
    noPlayers = val
} else {
    noPlayers = 3
}
let noRounds:Int
if CommandLine.argc > 2,
   let val = Int(CommandLine.arguments[2]) {
    noRounds = val
} else {
    noRounds = 2
}

var processCount = 0

for i in 0..<noPlayers {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["swift", "Player.swift", "\(noPlayers)", "\(noRounds)", "\(i)"]

    task.terminationHandler = { (process) in
        processCount -= 1

        if (processCount == 0) {
            exit(0)
        }
    }
    // print(task.processIdentifier)
    try? task.run()
    processCount += 1
    // task.waitUntilExit()
}

// print(task.terminationStatus)

RunLoop.current.run(mode: .default, before: .distantFuture)