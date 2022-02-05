# Memo

[![Version](https://img.shields.io/cocoapods/v/Memo.svg?style=flat)](https://cocoapods.org/pods/Memo)
[![License](https://img.shields.io/cocoapods/l/Memo.svg?style=flat)](https://cocoapods.org/pods/Memo)
[![Platform](https://img.shields.io/cocoapods/p/Memo.svg?style=flat)](https://cocoapods.org/pods/Memo)

Memo is a lightweight framework to make inter-device communication simple. It wraps the Multipeer Connectivity framework
and provides some of the boilerplate involved in setting up communication such as compatability checks and reconnect
detection.

## Requirements

* iOS 13 or later
* macOS 11.0 or later

## Installation

Memo is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your
Podfile:

```ruby
pod 'Memo'
```

## Background

Memo started out as part of the [Hexadecimal Keyboard and HexConnect](http://hexadecimalapp.com) apps. It was extracted
and rewritten (it originally used Bonjour directly, rather than MPC) as a general purpose framework for taking the
boilerplate out of building similar developer tools.

## License

Memo is available under the Apache License, Version 2.0. See the `LICENSE` file for more info.
