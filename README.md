swift-2048
==========

A port of [iOS-2048](https://github.com/austinzheng/iOS-2048) to Apple's new Swift language. The game is present and working, but a number of auxiliary features haven't yet been implemented.

Like the original Objective-C version, swift-2048 does not rely upon SpriteKit. See the description for iOS-2048 for more information.

Instructions
------------

You will need the Xcode 6 Developer Preview to build and run the project. However, it should run under either iOS 7 or iOS 8 (on the simulator).

Tap the button to play the game. Swipe to move the tiles.

Thoughts on Swift
-----------------

Swift is great. Pattern matching, tuples, and typeclasses are amazing. Programming in Swift feels much closer to programming in Scala than in Objective-C. Types are important again.

It's a little disappointing that Apple hasn't provided closure-based callbacks for UIKit controls. Selectors seem pretty hacky in Swift, but they do work.

Still have no idea how to make things private, public, or protected. In Objective-C you could hide internal details away in the .m file. In Swift, everything is exposed by default. Apparently this is something that will be added into the language before release; there will also be a flag to disable it (useful for exposing methods for unit testing).

Xcode is as unstable as always. The background compiler/code analyzer kept on crashing and restarting itself. Xcode was functional enough to allow the project to be brought to some state of completion. The debugger is horribly broken though. (Note that Xcode 6 DP is obviously beta software.)

### Features Swift has that Objective-C lacks
(Not comprehensive)

- Tuples
- Tagged enums (similar to Scala typeclasses)
- Primitive types treated like objects (actually structs) - extensions can declare new methods upon ``Int``, for example
- Enums and structs that support functions and constructors
- ``override`` keyword to explicitly denote a method overriding a superclass implementation
- C++ style function overloading
- Optional function arguments with default values
- Nested functions
- Pattern matching (match with arbitrary conditionals on values, ranges, tuple structure, enums, or types)
- Generics (type reification, not type erasure)
- Typed containers
- Safe typecasting
- Optionals (and optional chaining, implicitly unwrapped optionals, ``weak`` vs ``unowned``, ...)
- Overflow-safe arithmetic
- ``@auto_closure`` attribute, allowing for a very basic form of pass-by-name (as opposed to pass-by-value) function arguments
- ``@final`` attribute, to prevent overriding
- Other attributes, which have a purpose similar to Java annotations or Python decorators
- Type properties (analogous to class methods; must be computed for classes, but can be stored for enums and structs)
- Syntactical sugar for function currying
- Operator overloading
- Custom operators
- Arbitrary behavior for subscripts
- REPL
- Multiple forms of closure literal convenience syntax
- Capture lists in closure declarations, to avoid retain cycles when using closures
- Native range operators and limited array slicing (``..`` and ``...``)


### Objective-C features with no direct native Swift idiom
(AFAIK; some of these might be available through interop)

- Method swizzling
- Key-Value Observing (KVO)
- Adding or modifying methods and classes at runtime
- Invocations
- Message proxying
- Selectors


### Features I wish Swift had

- Better support for n-dimensional array initialization
- Tuples usable as dictionary keys (although there are technical issues)
- Python/MATLAB-style array slicing
- Abstract methods


License
-------
(c) 2014 Austin Zheng. Released under the terms of the MIT license.

2048 by Gabriele Cirulli (http://gabrielecirulli.com/). The original game can be found at http://gabrielecirulli.github.io/2048/, as can all relevant attributions. 2048 is inspired by an iOS game called "Threes", by Asher Vollmer.
