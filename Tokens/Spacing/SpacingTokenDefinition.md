# Spacing Tokens Definition

Diese Tokens werden für einheitliche Abstände innerhalb des Systems verwendet. Die Tokens sind aus dem Figma Design System übernommen und als CGFloat-Erweiterungen implementiert, um sie einfach in SwiftUI verwenden zu können.

## Token-Übersicht

| Token Name | Beschreibung | Wert | Verwendung |
|------------|--------------|------|------------|
| spacingXXS | Extra Extra Small | 0 | Kein Abstand |
| spacingXS | Extra Small | 4 | Minimale Abstände, z.B. zwischen Icons und Text |
| spacingS | Small | 8 | Kleine Abstände innerhalb von Komponenten |
| spacingDefault | Default | 16 | Standard-Abstände, häufigste Verwendung |
| spacingL | Large | 24 | Größere Abstände zwischen Sektionen |
| spacingXL | Extra Large | 40 | Große Abstände zwischen Hauptbereichen |
| spacingXXL | Extra Extra Large | 64 | Maximale Abstände, z.B. Hero-Sektionen |

## Verwendung in SwiftUI

Die Tokens verwenden semantische Namen für bessere Lesbarkeit:
```swift
VStack {
Text("Titel")
Spacer().frame(height: .spacingDefault)
Text("Beschreibung")
}
.padding(.spacingL)
```
```swift
HStack(spacing: .spacingS) {
Image(systemName: "star")
Text("Favorit")
}
.padding(.horizontal, .spacingXL)
```

## Definition der Tokens

Die Tokens sind als Extension von CGFloat definiert und entsprechen 1:1 dem Figma Design System:
```swift
public extension CGFloat {
static let spacingXXS: CGFloat = 0
static let spacingXS: CGFloat = 4
static let spacingS: CGFloat = 8
static let spacingDefault: CGFloat = 16
static let spacingL: CGFloat = 24
static let spacingXL: CGFloat = 40
static let spacingXXL: CGFloat = 64
}
```
