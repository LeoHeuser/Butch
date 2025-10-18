# Color Tokens Definition
This file explains how a color token is defined and applied within Swift to make it usable for SwiftUI. The ButchSDK uses SwiftUI for component definition to keep components scalable, performant, and reliable throughout all of Apple's native operating systems (like iOS, iPadOS, macOS, etc.).

## Differentiation between Primitive Tokens and Semantic Tokens
We differentiate between Primitive Tokens and Semantic Tokens. These Primitive Tokens contain the pure colors that are available in the overall system. They are like the color palette for the system from which the Semantic Tokens can use these colors.

### Primitive Color Tokens
They are plain and super easy.
```swift
swiftstatic let blackAlpha080 = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.8)   // 80% black
```
Primitive Color Tokens will always be provided as part of the sRGB spectrum and defined in RGB + Alpha spectrum as seen in the example above.

### Semantic Color Tokens
The application in code will happen with Semantic Tokens. These tokens are specifically linked to a purpose within the system. They apply to UI items like in this example of "background/primary". This means this is a set of colors that apply to the background elements which are primary in the visual hierarchy for a background element.

You apply a Semantic Color Token depending on light and dark theme. These will be differentiated due to better contrast and better level of adjustment for UI quality.
```swift
swiftstatic var textPrimary: Color {
adaptiveColor(light: .blackAlpha100, dark: .whiteAlpha100)
}
```
