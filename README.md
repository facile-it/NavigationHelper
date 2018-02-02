# NavigationHelper

`NavigationHelper` is a small library with utilities to aid the navigation in iOS and macOS apps.

The main class `SerialHandler` can handle executable actions: each action returns a `Future` for its asynchronous execution, and the class will handle the serial chaining of the actions.

The `NavigationHelperUIKit` library contains extensions of `UIViewController`, `UINavigationController` and `UITabBarController` to make them conform to the `Presenter` protocol.