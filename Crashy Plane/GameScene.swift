//
//  GameScene.swift
//  Crashy Plane
//
//  Created by dly on 8/13/18.
//  Copyright © 2018 dly. All rights reserved.
//

import SpriteKit
import GameplayKit

enum GameState {
    case showingLogo
    case playing
    case dead
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var backgroundMusic: SKAudioNode!
    
    var logo: SKSpriteNode!
    var gameOver: SKSpriteNode!
    var gameState = GameState.showingLogo

    override func didMove(to view: SKView) {
        createPlayer()
        createSky()
        createBackground()
        createGround()
        createScore()
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        
        if let musicURL = Bundle.main.url(forResource: "music", withExtension: "m4a") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
        
        createLogos()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState {
        case .showingLogo:
            gameState = .playing
            
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            let wait = SKAction.wait(forDuration: 0.5)
            let activatePlayer = SKAction.run { [unowned self] in
                self.player.physicsBody?.isDynamic = true
                self.startRocks()
            }
            
            let sequence = SKAction.sequence([fadeOut, wait, activatePlayer, remove])
            logo.run(sequence)
            
        case .playing:
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)                                           // make the physics a bit more realistic and it effectively neutralizes any existing upward velocity the player has before applying the new movement. Without that, the player could tap multiple times quickly and apply a huge upwards force to the plane, sending them miles off the top of the screen
            player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 20))                                       // give the player a push upwards every time the player taps the screen
            
        case .dead:
            // new fresh game scene as oppose to reseting everything
            let scene = GameScene(fileNamed: "GameScene")!
            let transition = SKTransition.moveIn(with: SKTransitionDirection.right, duration: 1)
            self.view?.presentScene(scene, transition: transition)
        }
    }
    
    func createPlayer() {
        let playerTexture = SKTexture(imageNamed: "player-1")
        player = SKSpriteNode(texture: playerTexture)
        player.zPosition = 10
        player.position = CGPoint(x: frame.width / 6, y: frame.height * 0.75)
        
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(texture: playerTexture, size: playerTexture.size())          // sets up pixel-perfect physics using the sprite of the plane
        player.physicsBody!.contactTestBitMask = player.physicsBody!.collisionBitMask                   // makes SpriteKit tell us whenever the player collides with anything
        player.physicsBody?.isDynamic = false                                                           // makes the plane respond to physics. Change to true after game begins
        player.physicsBody?.collisionBitMask = 0                                                        // makes the plane bounce off nothing
        
        let frame2 = SKTexture(imageNamed: "player-2")
        let frame3 = SKTexture(imageNamed: "player-3")
        let animation = SKAction.animate(with: [playerTexture, frame2, frame3, frame2], timePerFrame: 0.01)
        let runForever = SKAction.repeatForever(animation)
        
        player.run(runForever)
    }
    
    func createSky() {
        let topSky = SKSpriteNode(color: UIColor(hue: 0.55, saturation: 0.14, brightness: 0.97, alpha: 1), size: CGSize(width: frame.width, height: frame.height * 0.67))
        topSky.anchorPoint = CGPoint(x: 0.5, y: 1)
        
        let bottomSky = SKSpriteNode(color: UIColor(hue: 0.55, saturation: 0.16, brightness: 0.96, alpha: 1), size: CGSize(width: frame.width, height: frame.height * 0.33))
        bottomSky.anchorPoint = CGPoint(x: 0.5, y: 1)
        
        topSky.position = CGPoint(x: frame.midX, y: frame.height)
        bottomSky.position = CGPoint(x: frame.midX, y: bottomSky.frame.height)
        
        addChild(topSky)
        addChild(bottomSky)
        
        topSky.zPosition = -40
        bottomSky.zPosition = -40
    }
    
    func createBackground() {
        let backgroundTexture = SKTexture(imageNamed: "background")
        
        for i in 0 ... 1 {
            let background = SKSpriteNode(texture: backgroundTexture)
            background.zPosition = -30
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: (backgroundTexture.size().width * CGFloat(i)) - CGFloat(1 * i) , y: 100)
            addChild(background)
            
            let moveLeft = SKAction.moveBy(x: -backgroundTexture.size().width, y: 0, duration: 20)
            let moveReset = SKAction.moveBy(x: backgroundTexture.size().width, y: 0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            background.run(moveForever)
        }
    }
    
    func createGround() {
        let groundTexture = SKTexture(imageNamed: "ground")
        
        for i in 0 ... 1 {
            let ground = SKSpriteNode(texture: groundTexture)
            ground.zPosition = -10
            ground.position = CGPoint(x: (groundTexture.size().width / 2.0 + (groundTexture.size().width * CGFloat(i))), y: groundTexture.size().height / 2)
        
            addChild(ground)
            
            ground.physicsBody = SKPhysicsBody(texture: ground.texture!, size: ground.texture!.size())      // sets up pixel-perfect collision for the ground sprites
            ground.physicsBody?.isDynamic = false                                                           // plane hits the ground, but they won't get moved by the physics
            
            let moveLeft = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
            let moveReset = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            ground.run(moveForever)
        }
    }
    
    func createRocks() {
        let rockTexture = SKTexture(imageNamed: "rock")
        
        let topRock = SKSpriteNode(texture: rockTexture)
        topRock.physicsBody = SKPhysicsBody(texture: rockTexture, size: rockTexture.size())                 //  pixel-perfect physics collision for the rocks. Per-pixel collision detection is substantially slower than rectangle- and circle-based detection, but in our simple game it's perfectly OK
        topRock.physicsBody?.isDynamic = false
        
        topRock.zRotation = .pi
        topRock.xScale = -1.0
        
        let bottomRock = SKSpriteNode(texture: rockTexture)
        bottomRock.physicsBody = SKPhysicsBody(texture: rockTexture, size: rockTexture.size())
        bottomRock.physicsBody?.isDynamic = false
        
        topRock.zPosition = -20
        bottomRock.zPosition = -20
        
        // sprite positioned just after the rocks and will be used to track when the player has passed throught the rocks safely - contact will score a point
        let rockCollision = SKSpriteNode(color: UIColor.clear, size: CGSize(width: 32, height: frame.height))
        rockCollision.physicsBody = SKPhysicsBody(rectangleOf: rockCollision.size)                  // rectangle physics collision for the rectangle
        rockCollision.physicsBody?.isDynamic = false
    
        rockCollision.name = "scoreDetect"
        
        addChild(topRock)
        addChild(bottomRock)
        addChild(rockCollision)
        
        // determine where the safe gap in the rocks should be
        let xPosition = frame.width + topRock.frame.width
        
        let max = Int(frame.height / 3)
        let rand = GKRandomDistribution(lowestValue: -50, highestValue: max)
        let yPosition = CGFloat(rand.nextInt())
        
        let rockDistance: CGFloat = 70              // width of the gap between rocks, make it smaller to make game harder
        
        // position the rocks just off the right edge of the screen, then animate them across to the left edge. When they are safely off the left edge, remove them from the game.
        topRock.position = CGPoint(x: xPosition, y: yPosition + topRock.size.height + rockDistance)
        bottomRock.position = CGPoint(x: xPosition, y: yPosition - rockDistance)
        rockCollision.position = CGPoint(x: xPosition + (rockCollision.size.width * 2), y: frame.midY)
        
        let endPosition = frame.width + (topRock.frame.width * 2)
        
        let moveAction = SKAction.moveBy(x: -endPosition, y: 0, duration: 6.2)
        let moveSequence = SKAction.sequence([moveAction, SKAction.removeFromParent()])
        topRock.run(moveSequence)
        bottomRock.run(moveSequence)
        rockCollision.run(moveSequence)
    }
    
    func startRocks() {
        let create = SKAction.run { [unowned self] in
            self.createRocks()
        }
        
        let wait = SKAction.wait(forDuration: 3)
        let sequence = SKAction.sequence([create, wait])
        let repeatForever = SKAction.repeatForever(sequence)
        
        run(repeatForever)
    }
    
    func createScore() {
        scoreLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        scoreLabel.fontSize = 24
        
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 40)
        scoreLabel.text = "Score: 0"
        scoreLabel.fontColor = UIColor.black
        
        addChild(scoreLabel)
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard player != nil else { return }
        
        // effects - player is moving upwards the plane tilts up a little, and when the player is falling the plane tilts down
        let value = player.physicsBody!.velocity.dy * 0.001
        let rotate = SKAction.rotate(toAngle: value, duration: 0.1)
        
        player.run(rotate)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // touch the score rectangle
        if contact.bodyA.node?.name == "scoreDetect" || contact.bodyB.node?.name == "scoreDetect" {
            if contact.bodyA.node == player {
                contact.bodyB.node?.removeFromParent()
            } else {
                contact.bodyA.node?.removeFromParent()
            }
            
            let sound = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
            run(sound)
            
            score += 1
            
            return
        }
        
        guard contact.bodyA.node != nil && contact.bodyB.node != nil else { return }
        
        
        // touch any rock or the ground
        if contact.bodyA.node == player || contact.bodyB.node == player {
            if let explosion = SKEmitterNode(fileNamed: "PlayerExplosion") {
                explosion.position = player.position
                addChild(explosion)
            }
            
            let sound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
            run(sound)
            
            gameOver.alpha = 1
            gameState = .dead
            backgroundMusic.run(SKAction.stop())
            
            player.removeFromParent()
            speed = 0
        }
    }
    
    func createLogos() {
        logo = SKSpriteNode(imageNamed: "logo")
        logo.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(logo)
        
        gameOver = SKSpriteNode(imageNamed: "gameover")
        gameOver.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOver.alpha = 0          // initially invisible
        addChild(gameOver)
    }
    
    
}
