# Changelog

## 0.2.7

### 🆕 Advanced Sticker Customization
- **Enhanced BeverageStickerPrinter**: New modular sticker printing class for restaurants/cafes with per-quantity sticker support
- **Font Weight Control**: Added `StickerWeight` enum (normal, semiBold, bold) with TSPL SETBOLD mapping and software-bold fallback
- **Flexible Layout Controls**: Configurable spacing parameters (`detailsLineHeightMm`, `afterDetailsSpacingMm`, `timeBlockMm`, etc.)
- **Smart Details Processing**: 
  - Combined character budget for variants + additions + notes with configurable separator
  - Intelligent text wrapping with character-based cutting for consistent line breaks
  - Configurable max lines limit to prevent overflow
  - Auto-grow height option for dynamic label sizing
- **Debug Support**: Built-in debug logging for details processing and character counting
- **Clean Architecture**: Refactored details processing into maintainable helper methods

### 🔧 Code Quality
- Improved text wrapping algorithm for better handling of spaced content
- Cleaner separation of concerns in sticker generation logic
- Enhanced configurability for production use cases

## 0.2.6

### 🔧 Lint Fix
- Wrap single-line if statements in `looksLikeImage` with braces (style hint from analyzer).
- No behavioral changes; improves code style conformity.

## 0.2.5

### 📖 Documentation
- Bump install snippet to `^0.2.5` (previous README still showed 0.2.4)
- No code changes; publish to sync README/version on pub.dev

## 0.2.4

### 📖 Documentation & Compat Enhancements
- Added Blue Thermal Printer migration section (compat facade usage & mapping).
- Added logo / image printing guide with `printLogoAndLines` and `preferBitImage` fallback notes.
- Added troubleshooting matrix (label feed, margins, black logo, scan freeze).
- Added logging & versioning policy sections.
- No runtime code changes; docs-only release.

## 0.2.3

### 🖼 Logo & Image Printing (Compat Layer)
- Added `printLogoAndLines(assetLogoPath:, lines:, preferBitImage:)` for single‑payload (logo + text) printing.
- Legacy ESC * bit‑image fallback (`preferBitImage: true`) for printers that reject GS v 0 raster.
- Threshold tuning (logoThreshold) documented for balancing contrast vs fill.

### 🔄 Blue Thermal Printer Compatibility
- Added `BlueThermalCompatPrinter` facade (methods: `printCustom`, `printLeftRight`, `printNewLine`, `printImageBytes`, `printBarcode`, `printQRcode`, `paperCut`)
- Simple migration path from `blue_thermal_printer` with almost no code changes
- Added alignment + size enums (`Align`, `Size`) mirroring legacy API values

### ✨ Improvements
- Restored legacy style left‑right padded alignment with truncation & tail preservation.
- Reduced Bluetooth fragmentation by batching logo + lines before send.
- Added detailed debug logging around image pipeline and bit‑image fallback path.

### � Features
- Receipt compat + existing multi‑role architecture (cashier/kitchen/sticker)
- Works alongside sticker invoice system (Levels 1–4)

### �📖 Documentation
- README updated (logo printing guide, migration, troubleshooting table).
- README restructured: quick overview, migration guide, method mapping table.
- Added examples for compat receipt + sticker APIs.

### 🔧 Internal
- Added rawBytesToBitImage helper to image utils for direct conversion.
- Prefer single builder flush to minimize partial writes on slower modules.
- No breaking changes to existing public APIs.

### 🔄 Blue Thermal Printer Compatibility
- Added `BlueThermalCompatPrinter` facade (methods: `printCustom`, `printLeftRight`, `printNewLine`, `printImageBytes`, `printBarcode`, `printQRcode`, `paperCut`)
- Simple migration path from `blue_thermal_printer` with almost no code changes
- Added alignment + size enums (`Align`, `Size`) mirroring legacy API values

### 📦 Features
- Receipt compat + existing multi‑role architecture (cashier/kitchen/sticker)
- Works alongside sticker invoice system (Levels 1–4)

### 📖 Documentation
- README restructured: quick overview, migration guide, method mapping table
- Added examples for compat receipt + sticker APIs

### 🛠 Internal
- No breaking changes to existing public APIs
- Version bump for pub.dev release

## 0.2.2

### 🚀 NEW: 3-Level API for Better User Experience

**LEVEL 1: Super Simple (ONE-LINER)**
- Added `CustomStickerPrinter.printInvoice()` - Print invoice dengan 1 line code
- Perfect untuk pemula yang ingin langsung pakai

**LEVEL 2: Template with Options (CUSTOMIZABLE)**  
- Added `CustomStickerPrinter.printInvoiceSticker()` - Template dengan opsi customization
- Added `StickerSize` enum: `mm40x30`, `mm58x40`, `mm40x25`, `mm32x20`
- Added `FontSize` enum: `small`, `medium`, `large`

**LEVEL 3: Multi-Menu Restaurant Style (PROFESSIONAL)**
- Added `CustomStickerPrinter.printRestaurantOrder()` - Print multiple menu items
- Added `MenuItem` class untuk data structure
- Setiap menu = 1 sticker terpisah (perfect untuk restoran)

**LEVEL 4: Full Custom (ADVANCED)**
- Existing `CustomStickerPrinter.printSticker()` dengan kontrol penuh

### 📖 Documentation 
- Updated README dengan 4 level complexity examples
- Improved public documentation untuk adoption yang lebih mudah
- Added comprehensive parameter guides

## 0.2.2

* Update README to full English for international developers
* Improved examples with English menu items
* Enhanced professional documentation

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