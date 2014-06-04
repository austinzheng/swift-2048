swift-2048
==========

A port of [iOS-2048](https://github.com/austinzheng/iOS-2048) to Apple's new Swift language. The game is present and working, but the score screen has not been implemented, nor have the (rather useless) button-based controls.

Like the original Objective-C version, swift-2048 does not rely upon SpriteKit. See the description for iOS-2048 for more information.

Instructions
------------

You will need the Xcode 6 Developer Preview to build and run the project. However, it should run under either iOS 7 or iOS 8 (on the simulator).

Tap the button to play the game. Swipe to move the tiles.

Thoughts on Swift
-----------------

Swift is great. Pattern matching, tuples, and typeclasses are amazing. Programming in Swift feels much closer to programming in Scala than in Objective-C. Types are important again.

It's a little disappointing that Apple hasn't provided closure-based callbacks for UIKit controls. Selectors seem pretty hacky in Swift, but they do work.

Still have no idea how to make things private, public, or protected. In Objective-C you could hide internal details away in the .m file. In Swift, everything is exposed by default.

Initializing n-dimensional arrays is painful.

Xcode is as unstable as always. The background compiler/code analyzer kept on crashing and restarting itself. Xcode was functional enough to allow the project to be brought to some state of completion. The debugger is horribly broken though.

License
-------
(c) 2014 Austin Zheng. Released under the terms of the MIT license.

2048 by Gabriele Cirulli (http://gabrielecirulli.com/). The original game can be found at http://gabrielecirulli.github.io/2048/, as can all relevant attributions. 2048 is inspired by an iOS game called "Threes", by Asher Vollmer.
