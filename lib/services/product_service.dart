import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class ProductService {
  static final Set<String> _processedDemoStockOrders = <String>{};
  static Future<void>? _seedInProgress;

  static final List<Map<String, dynamic>> _sampleMaps = <Map<String, dynamic>>[
    {
      'name': "Men's Compression Shirt",
      'description': 'High-performance compression shirt with breathable mesh panels for intense workouts.',
      'price': 24.99,
      'imageUrl': 'lib/img/compression shirt.jpg',
      'stock': 60,
      'category': 'Apparel',
      'features': [
        '[Breathable Design] mesh panels for airflow',
        '[Moisture-Wicking] fabric keeps you dry',
        '[4-Way Stretch] full range of motion',
        '[Slim Fit] ergonomic compression fit',
      ],
    },
    {
      'name': 'SPORTNOW Adjustable Dumbbell',
      'description': 'Space-saving adjustable dumbbell for home and gym strength training.',
      'price': 24.99,
      'imageUrl': 'lib/img/dumbell.jpg',
      'stock': 20,
      'category': 'Equipment',
      'features': [
        '[Quick Lock] fast weight adjustment',
        '[Compact] space-saving home design',
        '[Non-Slip Grip] secure handling',
        '[Durable] steel construction',
      ],
    },
    {
      'name': 'HPYGN Resistance Bands',
      'description': 'Five resistance levels with handles and door anchor.',
      'price': 24.99,
      'imageUrl': 'lib/img/resistance bands set.jpg',
      'stock': 50,
      'category': 'Accessories',
      'features': [
        '[5 Levels] progressive resistance',
        '[Door Anchor] versatile workouts',
        '[Handles] comfortable foam grips',
        '[Portable] travel-friendly bag',
      ],
    },
    {
      'name': 'Optimum Nutrition Gold Standard Whey',
      'description': 'High-protein whey blend for muscle recovery and growth.',
      'price': 24.99,
      'imageUrl': 'lib/img/whey protine.jpg',
      'stock': 25,
      'category': 'Supplements',
      'features': [
        '[24g Protein] per serving',
        '[5.5g BCAAs] muscle recovery',
        '[Mixes Easily] smooth texture',
        '[Award-Winning] trusted brand',
      ],
    },
    {
      'name': 'Micronized Creatine Powder',
      'description':
          'Micronized creatine for strength, power, and performance.',
      'price': 24.99,
      'imageUrl': 'lib/img/crreatine.jpg',
      'stock': 30,
      'category': 'Supplements',
      'features': [
        '[5g Creatine] per serving',
        '[Micronized] easy absorption',
        '[Unflavored] mix with any drink',
        '[Strength] boost power output',
      ],
    },
    {
      'name': 'Tunturi Kettlebells',
      'description':
          'Cast-iron kettlebell for swings, squats, and full-body workouts.',
      'price': 24.99,
      'imageUrl': 'lib/img/kettel bell.jpg',
      'stock': 18,
      'category': 'Equipment',
      'features': [
        '[Cast Iron] durable build',
        '[Wide Handle] secure grip',
        '[Flat Base] stable storage',
        '[Full-Body] versatile training',
      ],
    },
    {
      'name': 'Premium Yoga Mat',
      'description': 'Non-slip 6mm yoga mat for yoga, pilates, and stretching.',
      'price': 29.99,
      'imageUrl': 'lib/img/yoga mat.jpg',
      'stock': 35,
      'category': 'Accessories',
      'features': [
        '[Non-Slip] grip surface',
        '[6mm Cushion] joint support',
        '[Lightweight] easy to carry',
      ],
    },
    {
      'name': 'Gym Training Gloves',
      'description': 'Padded grip gloves with wrist support for weightlifting.',
      'price': 19.99,
      'imageUrl': 'lib/img/training gloves.jpg',
      'stock': 40,
      'category': 'Apparel',
      'features': [
        '[Padded Palm] grip protection',
        '[Wrist Strap] added support',
        '[Breathable] mesh back',
      ],
    },
    {
      'name': 'Insulated Sports Water Bottle (1L)',
      'description':
          'Stainless steel bottle that keeps drinks cold for 24 hours.',
      'price': 14.99,
      'imageUrl': 'lib/img/water bottle.jpg',
      'stock': 75,
      'category': 'Accessories',
      'features': [
        '[1L Capacity] all-day hydration',
        '[Insulated] 24-hour cold',
        '[Leak-Proof] secure lid',
      ],
    },
    {
      'name': 'Foam Roller',
      'description':
          'High-density foam roller for muscle recovery and massage.',
      'price': 22.50,
      'imageUrl': 'lib/img/roller mat.jpg',
      'stock': 28,
      'category': 'Accessories',
      'features': [
        '[High-Density] firm pressure',
        '[Textured] muscle relief',
        '[Easy Clean] wipe down surface',
      ],
    },
    {
      'name': 'jumping rope',
      'description':
          'Durable jump rope with adjustable length for cardio workouts.',
      'price': 22.50,
      'imageUrl': 'lib/img/jumping rope.jpg',
      'stock': 28,
      'category': 'Accessories',
      'features': [
        '[Adjustable Length] customize your workout',
        '[Durable Construction] built to last',
        '[Smooth Rotation] reduce friction during jumps',
      ],
    },
     {
      'name': 'gym shoes for men',
      'description':
          'Durable gym shoes with breathable mesh and cushioned sole for comfort during workouts.',
      'price': 3999.99,
      'imageUrl': 'lib/img/gym shoes.jpg',
      'stock': 30,
      'category': 'Apparel',
      'features': [
        '[Breathable Mesh] keeps feet cool and dry',
        '[Cushioned Sole] provides comfort and support',
        '[Durable Construction] built to withstand intense workouts',
      ],
    },
  ];

  static List<Product> _demoProducts() => _sampleMaps
      .asMap()
      .entries
      .map(
        (e) => Product.fromMap(
          Map<String, dynamic>.from(e.value),
          'demo_${e.key}',
        ),
      )
      .toList();

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      // Firebase is not available on this platform (e.g. Windows/Linux).
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _products =>
      _db?.collection('products');

  Stream<List<Product>> streamProducts() async* {
    final products = _products;
    if (products == null) {
      yield _demoProducts();
      return;
    }

    try {
      await for (final snap in products.orderBy('name').snapshots()) {
        final items = snap.docs
            .map((d) => Product.fromMap(d.data(), d.id))
            .toList();
        developer.log('Loaded ${items.length} products from Firestore');
        yield items;
      }
    } catch (e, st) {
      developer.log(
        'Product stream failed; using demo data',
        error: e,
        stackTrace: st,
      );
      yield _demoProducts();
    }
  }

  Future<Product?> getProduct(String id) async {
    final products = _products;
    if (products == null) {
      return _demoProducts().firstWhere(
        (p) => p.id == id,
        orElse: () => _demoProducts().first,
      );
    }

    try {
      final doc = await products.doc(id).get();
      if (!doc.exists) return null;
      return Product.fromMap(doc.data() ?? {}, doc.id);
    } catch (e, st) {
      developer.log('getProduct failed', error: e, stackTrace: st);
      return _demoProducts().firstWhere(
        (p) => p.id == id,
        orElse: () => _demoProducts().first,
      );
    }
  }

  /// Decreases inventory once for a payment-confirmed order.
  ///
  /// Firestore products are updated atomically and protected against duplicate
  /// webhook/status handling by a per-order marker. Bundled demo inventory is
  /// only held in memory because it has no backing database.
  Future<void> decrementStockForOrder({
    required String orderId,
    required Map<String, int> quantities,
  }) async {
    if (orderId.isEmpty || quantities.isEmpty) {
      throw ArgumentError('An order ID and at least one product are required.');
    }
    if (quantities.values.any((quantity) => quantity <= 0)) {
      throw ArgumentError('Product quantities must be positive.');
    }

    final demoEntries = quantities.entries
        .where((entry) => entry.key.startsWith('demo_'))
        .toList();
    if (demoEntries.length == quantities.length) {
      if (_processedDemoStockOrders.contains(orderId)) return;

      final stockUpdates = <(int, int)>[];
      for (final entry in demoEntries) {
        final index = int.tryParse(entry.key.substring('demo_'.length));
        if (index == null || index < 0 || index >= _sampleMaps.length) {
          throw StateError('The product ${entry.key} is no longer available.');
        }
        final stock = (_sampleMaps[index]['stock'] as num? ?? 0).toInt();
        if (stock < entry.value) {
          throw StateError(
            'Not enough stock for ${_sampleMaps[index]['name']}.',
          );
        }
        stockUpdates.add((index, stock - entry.value));
      }
      for (final (index, stock) in stockUpdates) {
        _sampleMaps[index]['stock'] = stock;
      }
      _processedDemoStockOrders.add(orderId);
      return;
    }

    if (demoEntries.isNotEmpty) {
      throw StateError(
        'Demo products and Firestore products cannot share an order.',
      );
    }

    final db = _db;
    if (db == null) {
      throw StateError(
        'Firestore is unavailable; inventory could not be updated.',
      );
    }

    final marker = db.collection('processed_stock_orders').doc(orderId);
    final productRefs = quantities.keys
        .map(
          (productId) =>
              MapEntry(productId, db.collection('products').doc(productId)),
        )
        .toList();

    await db.runTransaction((transaction) async {
      if ((await transaction.get(marker)).exists) return;

      final productSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in productRefs) {
        productSnapshots[entry.key] = await transaction.get(entry.value);
      }

      for (final entry in productRefs) {
        final product = productSnapshots[entry.key]!;
        if (!product.exists) {
          throw StateError('A product in this order could not be found.');
        }
        final stock = (product.data()?['stock'] as num? ?? 0).toInt();
        final orderedQuantity = quantities[entry.key]!;
        if (stock < orderedQuantity) {
          throw StateError(
            'Not enough stock for ${product.data()?['name'] ?? entry.key}.',
          );
        }
      }

      for (final entry in productRefs) {
        final stock =
            (productSnapshots[entry.key]!.data()?['stock'] as num? ?? 0)
                .toInt();
        transaction.update(entry.value, {
          'stock': stock - quantities[entry.key]!,
        });
      }
      transaction.set(marker, {
        'orderId': orderId,
        'processedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> seedSampleProducts() {
    return _seedInProgress ??= _seedSampleProducts().whenComplete(() {
      _seedInProgress = null;
    });
  }

  Future<void> _seedSampleProducts() async {
    final db = _db;
    final products = _products;
    if (db == null || products == null) return;

    try {
      final existingSnap = await products.get();
      final batch = db.batch();

      for (var index = 0; index < _sampleMaps.length; index++) {
        final sample = _sampleMaps[index];
        final sampleName = sample['name'].toString();
        final canonicalRef = products.doc('sample_product_$index');
        final matchingDocs = existingSnap.docs
            .where((doc) => doc.data()['name'] == sampleName)
            .toList();
        QueryDocumentSnapshot<Map<String, dynamic>>? canonicalDoc;
        for (final doc in matchingDocs) {
          if (doc.id == canonicalRef.id) {
            canonicalDoc = doc;
            break;
          }
        }
        final stockSource =
            canonicalDoc ?? (matchingDocs.isEmpty ? null : matchingDocs.first);
        final canonicalData = <String, dynamic>{
          ...sample,
          'stock': stockSource?.data()['stock'] ?? sample['stock'],
        };

        // Stable IDs make overlapping startup calls update the same document
        // instead of creating additional copies of each product.
        batch.set(canonicalRef, canonicalData);

        // Remove only duplicate documents for this seeded product. Leave any
        // unrelated/custom Firestore products untouched.
        for (final duplicate in matchingDocs) {
          if (duplicate.id != canonicalRef.id) {
            batch.delete(duplicate.reference);
          }
        }
      }

      await batch.commit();
      developer.log(
        'Seeded and de-duplicated ${_sampleMaps.length} sample products',
      );
    } catch (e, st) {
      developer.log(
        'Seeding failed (demo mode will be used)',
        error: e,
        stackTrace: st,
      );
    }
  }
}
