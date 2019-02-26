//
//  GameManager.swift
//  
//
//  Created by Renan Greca on 06/02/2019.
//

import Foundation

// MARK: Constants

let notificationCenter = DistributedNotificationCenter.default()
let pid: Int32 = ProcessInfo.processInfo.processIdentifier

// MARK: Command-line arguments

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
let shouldPrintLog:Bool
if CommandLine.argc > 3,
   let val = Int(CommandLine.arguments[3]),
   val == 1 {
    shouldPrintLog = true
} else {
    shouldPrintLog = false
}

func printLog(_ string: String) {
    if shouldPrintLog {
        print("#\(pid) - \(string)")
    }
}

// MARK: Enums

/**
    Traditional rock-paper-scissors items
*/
enum Item: Int, CaseIterable {
    case rock
    case paper
    case scissors
    
    /**
        Checks if the item beats another item
    */
    func beats(_ play: Item) -> Bool {
        switch self {
        case .rock:
            // Rock beats scissors
            return play == .scissors
        case .paper:
            // Paper beats rock
            return play == .rock
        case .scissors:
            // Scissors beats paper
            return play == .paper
        }
    }

    /**
        Generates a random item
    */
    static var random: Item {
        return Item.allCases.randomElement()!
    }

    /**
        String value for each item
    */
    var description: String {
        switch self {
        case .rock:
            return "Rock"
        case .paper:
            return "Paper"
        case .scissors:
            return "Scissors"
        }
    }
}

/**
    State of the current process
*/
enum State {
    case waiting
    case playing
    case counting
}

// MARK: Classes

/**
    One player of the current match
*/
class Player: Equatable {
    let pid: Int32
    var score = 0

    init(pid: Int32) {
        self.pid = pid
    }

    func incrementScore() {
        self.score += 1
    }

    static func == (lhs: Player, rhs: Player) -> Bool {
        return
            lhs.pid == rhs.pid
    }
}

typealias Play = (playerID: Int32, item: Item)

/**
    Main class for managing the game in this process
*/
class GameManager {

    // Notification identifiers
    let beginNotification = NSNotification.Name(rawValue: "player.begin")
    let playNotification = NSNotification.Name(rawValue: "player.sendItem")

    // Game management variables
    var round = 0
    var receivedPlays:[Play] = []
    var players:[Int32:Player] = [pid: Player(pid: pid)]

    /**
        Begin by adding the notification observers
    */
    init() {
        printLog("joining match")

        notificationCenter.addObserver(self, 
                                       selector: #selector(receiveBegin(notification:)),
                                       name: beginNotification,
                                       object: nil)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(receivePlay(notification:)),
                                       name: playNotification,
                                       object: nil)
    }

    /**
        Send and reply to a handshake
    */
    func sendHello() {
        postNotification(name: beginNotification, userInfo: ["message": "Hello there!", "pid": pid])
    }

    func replyHello() {
        postNotification(name: beginNotification, userInfo: ["message": "General Kenobi!", "pid": pid])
    }

    /**
        Unless it's time to end the game, start a round
    */
    func startRound() {
        if round < noRounds {
            printLog("starting round")
            self.receivedPlays = []
            self.round += 1
            sendPlay()
        } else {
            printLog("exiting")
            exit(0)
        }        
    }

    /**
        Send a play
    */
    func sendPlay() {
        let item = Item.random
        printLog("playing \(item.description)")
        self.receivedPlays.append((playerID: pid, item: item))
        postNotification(name: playNotification, userInfo: ["message": "Take this!", "pid": pid, "item": item.rawValue])
    }

    @objc func receivePlay(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let itemID = userInfo["item"] as? Int,
              let item = Item(rawValue: itemID),
              let notificationProcess = userInfo["pid"] as? Int32,
              notificationProcess != pid else {
                return
        }

        printLog("Player \(notificationProcess) played \(item.description)")
        self.receivedPlays.append((playerID: notificationProcess, item: item))

        if (self.receivedPlays.count == players.count) {
            countPoints()
            startRound()
        }
    }

    func countPoints() {
        for (player1, item1) in self.receivedPlays {
            for (player2, item2) in self.receivedPlays {
                if player1 == player2 {
                    continue
                }
                if (item1.beats(item2)) {
                    players[player1]?.incrementScore()
                }
            }
        }
        

        printLog("result of round \(round):")
        for (playerID, player) in players {
            printLog("player \(playerID) has \(player.score) points")
        }
    }

    @objc func receiveBegin(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let message = userInfo["message"] as? String,
              let notificationProcess = userInfo["pid"] as? Int32,
              notificationProcess != pid else {
                return
        }

        let player = Player(pid: notificationProcess)
        if players[notificationProcess] == nil {
            printLog("player #\(notificationProcess) says: \(message)")
            players[notificationProcess] = player
            self.replyHello()

            if players.count == noPlayers {
                self.startRound()
            }
        }
    }

    /**
        Helper method to send notifications
    */
    func postNotification(name: NSNotification.Name, userInfo: [String:Any]) {
        // let r = UInt32.random(in: 1..<5)
        // sleep(r)
        notificationCenter.postNotificationName(name,
                                                object: nil,
                                                userInfo: userInfo,
                                                options: [DistributedNotificationCenter.Options.deliverImmediately, .postToAllSessions])
    }
}

let player = GameManager()
player.sendHello()

RunLoop.current.run(mode: .default, before: .distantFuture)