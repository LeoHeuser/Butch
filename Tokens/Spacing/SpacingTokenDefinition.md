# Spacing Tokens Definition
These tokens are used for uniform spacing within the system. The tokens should be easily used like a normal numeric value. The tokens should be used like this example:
```swift
VStack {
// Content of the VStack
}
.padding(.spacing8)
'''

## Definition of the token itself
The token itself will be defined as follows to be used within the system. The token itself is an extension of CGFloat to be easily accessible within the system.
```swift
swiftstatic let spacing4: CGFloat = 4
'''
