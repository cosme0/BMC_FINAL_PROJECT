import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/product.dart';

class ProductService {
  static final List<Map<String, dynamic>> _sampleMaps = <Map<String, dynamic>>[
    {
      'name': "Men's Compression Shirt",
      'description':
          'High-performance compression shirt with breathable mesh panels for intense workouts.',
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
      'description':
          'Space-saving adjustable dumbbell for home and gym strength training.',
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
      'description': 'Micronized creatine for strength, power, and performance.',
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
      'description': 'Cast-iron kettlebell for swings, squats, and full-body workouts.',
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
      'description': 'Stainless steel bottle that keeps drinks cold for 24 hours.',
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
      'description': 'High-density foam roller for muscle recovery and massage.',
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
  ];

  static List<Product> _demoProducts() => _sampleMaps
      .asMap()
      .entries
      .map((e) => Product.fromMap(
            Map<String, dynamic>.from(e.value),
            'demo_${e.key}',
          ))
      .toList();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  Stream<List<Product>> streamProducts() async* {
    try {
      await for (final snap in _products.orderBy('name').snapshots()) {
        final items =
            snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList();
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
    try {
      final doc = await _products.doc(id).get();
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

  Future<void> seedSampleProducts() async {
    const newNames = <String>{
      "Men's Compression Shirt",
      'SPORTNOW Adjustable Dumbbell',
      'HPYGN Resistance Bands',
      'Optimum Nutrition Gold Standard Whey',
      'Micronized Creatine Powder',
      'Tunturi Kettlebells',
      'Premium Yoga Mat',
      'Gym Training Gloves',
      'Insulated Sports Water Bottle (1L)',
      'Foam Roller',
    };
    const expectedImages = <String>{
      'lib/img/compression shirt.jpg',
      'lib/img/dumbell.jpg',
      'lib/img/resistance bands set.jpg',
      'lib/img/whey protine.jpg',
      'lib/img/crreatine.jpg',
      'lib/img/kettel bell.jpg',
      'lib/img/yoga mat.jpg',
      'lib/img/training gloves.jpg',
      'lib/img/water bottle.jpg',
      'lib/img/roller mat.jpg',
    };

    try {
      final existingSnap = await _products.get();
      final existingNames = existingSnap.docs
          .map((d) => (d.data()['name'] ?? '').toString())
          .toSet();
      final existingImages = existingSnap.docs
          .map((d) => (d.data()['imageUrl'] ?? '').toString())
          .toSet();
      final isSeeded = newNames.every(existingNames.contains) &&
          existingNames.length == newNames.length &&
          expectedImages.every(existingImages.contains);
      if (isSeeded) return;

      final deleteBatch = _db.batch();
      for (final d in existingSnap.docs) {
        deleteBatch.delete(d.reference);
      }
      await deleteBatch.commit();

      final batch = _db.batch();
      for (final s in _sampleMaps) {
        batch.set(_products.doc(), s);
      }
      await batch.commit();
      developer.log('Seeded ${_sampleMaps.length} sample products');
    } catch (e, st) {
      developer.log('Seeding failed (demo mode will be used)',
          error: e, stackTrace: st);
    }
  }
}
