# Changelog

## 0.2.1

🔧 **Documentation & API Fixes**

### 📚 Documentation Updates
- **Fixed README Examples**: Updated all examples to match actual main.dart implementation
- **Complete Invoice Style Guide**: Added exact invoice implementation from main.dart with proper wrap text and dynamic height
- **Bluetooth Connect/Disconnect Guide**: Added comprehensive guide with loading states
- **Parameter Reference**: Complete customization guide for all parameters

### 🛠️ API Consistency
- **README now matches main.dart**: All examples are now consistent with working implementation
- **Invoice Style Example**: Shows proper 2-menu example with `_printSingleMenuStickerOnly` method
- **Text Wrapping**: Includes `_wrapText` helper for automatic text wrapping
- **Dynamic Height**: Proper `clamp(15.0, 30.0)` implementation

### 📖 New Documentation Sections
- Font size guide (Font 1-8 with size multipliers explanation)
- Complete parameter reference for customization
- Bluetooth scanning with loading states
- Left-right same line positioning examples

## 0.2.0

🎉 **Major Feature Update - Custom Sticker API & Invoice Templates**

### 🆕 New Features
- **Custom Sticker API**: Complete helper for TSPL sticker printing with easy-to-use `StickerText` and `StickerBarcode` classes
- **Text Alignment**: Support for 'left', 'center', 'right' alignment with automatic positioning
- **4-Side Margins**: Full control with `marginLeft`, `marginTop`, `marginRight`, `marginBottom`
- **Invoice Style Templates**: Ready-to-use invoice printing with customer names, timestamps, and modifications
- **Built-in Templates**: `printProductSticker40x30()` and `printAddressSticker58x40()` for common use cases
- **Auto Text Wrapping**: Smart text wrapping that preserves whole words
- **Dynamic Heights**: Automatic sticker height calculation based on content

### 🔧 Improvements
- **Enhanced Documentation**: Comprehensive examples and parameter explanations
- **Better Font Support**: Validated font ranges (1-8) with size multipliers
- **Orientation Fix**: TSPL `DIRECTION 0` for proper sticker orientation
- **Multi-line Support**: Easy handling of multiple text lines with proper spacing

### 📚 New Examples
- Invoice style printing with customer data
- Product and address label templates  
- Text alignment demonstrations
- Left-right same line positioning
- Full margin control examples

### 🐛 Bug Fixes
- Fixed upside-down text in TSPL stickers
- Corrected text positioning calculations
- Improved error handling in connection management

## 0.1.3

- Fix repository URL and add more examples.

## 0.1.2

- Fix repository URL to point to the package subdirectory in the monorepo for pub.dev verification.

## 0.1.1

- Add example/, LICENSE, README improvements, and API dartdoc.
- Fix analyzer warnings and formatting.
- Prep for pub.dev publishing flow and improve documentation.

## 0.1.0

- Initial release of the federated interface package.
- ESC/POS, TSPL, CPCL support via builders.
- Role-based printer mapping.
- Android Bluetooth Classic and TCP; iOS TCP.
- Basic receipt renderer and cash drawer command.

## 0.1.3

- README: update install snippet to ^0.1.3 and add full example app.
- Public exports for builders/renderers; package example uses them.