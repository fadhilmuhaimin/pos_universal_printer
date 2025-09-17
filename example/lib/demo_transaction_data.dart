// Sample transaction data mimicking the user's FullTransactionModel structure
// Simplified for demo: only fields needed for printing logic.

class VoucherData {
  VoucherData({required this.type, required this.amount});
  final String type; // 'nominal' or 'percentage'
  final double amount;
}

class ProductModelDemo {
  ProductModelDemo({
    required this.id,
    required this.name,
    required this.price,
    required this.totalPrice,
    this.totalPriceDisc,
  });
  final int id;
  final String name;
  final int price; // unit price
  final double totalPrice; // price * qty + additions etc.
  final double? totalPriceDisc; // discount amount for product
}

class SelectedVariantDemo {
  SelectedVariantDemo({required this.id, required this.name, required this.price});
  final int id;
  final String name;
  final int price;
}

class SelectedAdditionDemo {
  SelectedAdditionDemo({required this.id, required this.name, required this.price});
  final int id;
  final String name;
  final int price;
}

class TransactionLineDemo {
  TransactionLineDemo({
    required this.product,
    required this.quantity,
    this.selectedVariants = const [],
    this.selectedAdditions = const [],
    this.notes = '',
  });
  final ProductModelDemo product;
  final int quantity;
  final List<SelectedVariantDemo> selectedVariants;
  final List<SelectedAdditionDemo> selectedAdditions;
  final String notes;
}

class FullTransactionDemo {
  FullTransactionDemo({
    required this.transactions,
    required this.discount,
    required this.tax,
    required this.voucher,
    required this.customerName,
    required this.paymentMethod,
    required this.orderType,
  });
  final List<TransactionLineDemo> transactions;
  final double discount; 
  final double tax;
  final VoucherData? voucher;
  final String customerName;
  final String paymentMethod; // e.g. Tunai
  final String orderType; // dine_in / take_away
}

FullTransactionDemo sample56mmTransaction() {
  return FullTransactionDemo(
    customerName: 'John test 2lasjdnlkasda1212s',
    paymentMethod: 'Tunai',
    orderType: 'dine_in',
    // Updated discount/tax to reflect larger combined transaction (demo values)
    discount: 8400.0,
    tax: 14860.0, // ~10% after discount
    voucher: VoucherData(type: 'nominal', amount: 8400.0),
    transactions: [
      // Food line
      TransactionLineDemo(
        product: ProductModelDemo(
          id: 21,
          name: 'Nasi Goreng Merah',
          price: 25000,
          totalPrice: 29000, // includes addition
          totalPriceDisc: null,
        ),
        quantity: 1,
        selectedVariants: [
          SelectedVariantDemo(id: 26, name: 'Normal', price: 0),
        ],
        selectedAdditions: [
          SelectedAdditionDemo(id: 14, name: 'Sambel Mata Spesial', price: 4000),
        ],
        notes: '',
      ),
      // Existing single beverage in original sample
      // TransactionLineDemo(
      //   product: ProductModelDemo(
      //     id: 603,
      //     name: 'Kopi Susu Klasik',
      //     price: 13000,
      //     totalPrice: 13000,
      //     totalPriceDisc: null,
      //   ),
      //   quantity: 1,
      // ),
      // Additional beverage lines integrated so cashier receipt & sticker source are consistent
      ...sampleBeverageLines(),
    ],
  );
}

// New: sample beverage-only transaction lines (3 drinks) for sticker-by-sticker demo
List<TransactionLineDemo> sampleBeverageLines() {
  return [
    // TransactionLineDemo(
    //   product: ProductModelDemo(
    //     id: 701,
    //     name: 'Es Kopi Susu Aren1234567',
    //     price: 18000,
    //     // quantity 3 with addition Extra Shot 5000 each => (18000+5000)*3 = 69000
    //     totalPrice: 69000,
    //     totalPriceDisc: null,
    //   ),
    //   quantity: 1, // demonstrate multi-quantity => multiple stickers
    //   selectedVariants: [
    //     SelectedVariantDemo(id: 91, name: '12kasndlksandlsandlasdasdsad3', price: 0),
    //     SelectedVariantDemo(id: 91, name: '456', price: 0),
    //   ],
    //   selectedAdditions: [
    //     SelectedAdditionDemo(id: 301, name: '789101112131415161718192021', price: 5000),
    //     SelectedAdditionDemo(id: 301, name: '181293123aqwe2130', price: 5000),
    //   ],
    //   notes: 'sadsa',
    // ),
    // TransactionLineDemo(
    //   product: ProductModelDemo(
    //     id: 702,
    //     name: 'Matcha Latte Dingin',
    //     price: 23000,
    //     // addition Oat Milk 4000 => 27000
    //     totalPrice: 27000,
    //     totalPriceDisc: null,
    //   ),
    //   quantity: 1,
    //   selectedVariants: [
    //     SelectedVariantDemo(id: 92, name: 'Oat Milk', price: 4000),
    //   ],
    //   selectedAdditions: [
    //     SelectedAdditionDemo(id: 302, name: 'Boba Pearl', price: 6000),
    //   ],
    //   notes: 'Manis normal',
    // ),
    TransactionLineDemo(
      product: ProductModelDemo(
        id: 703,
        name: 'Thai Tea Original',
        price: 15000,
        // addition Pudding 4000 => 19000
        totalPrice: 19000,
        totalPriceDisc: null,
      ),
      quantity: 1,
      selectedVariants: [
        SelectedVariantDemo(id: 93, name: 'Regular Ice', price: 0),
        SelectedVariantDemo(id: 93, name: 'Regular Makan Disini', price: 0),
        SelectedVariantDemo(id: 93, name: 'Regular Ice', price: 0),
      ],
      selectedAdditions: [
        SelectedAdditionDemo(id: 303, name: 'Pudding', price: 4000),
      ],
      notes: 'Pisah Ketupat',
    ),
  
  ];
}

/// Helper to decide if a transaction line is a beverage (simple name-based heuristic).
bool isBeverageLine(TransactionLineDemo line) {
  final n = line.product.name.toLowerCase();
  const keywords = ['kopi', 'tea', 'latte', 'matcha', 'aren'];
  return keywords.any((k) => n.contains(k));
}
