// lib/core/services/monetization_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Wraps RevenueCat Purchases SDK and implements local caching database
/// for secure, offline-first subscription status checks.
class MonetizationService {
  static const String _boxName = 'monetization_box';
  static const String _keyPremium = 'is_premium_active';
  
  static Box? _box;

  /// Initializes the local box cache and registers RevenueCat configuration.
  static Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
    
    // RevenueCat initialization (uses dummy keys for sandbox development)
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        await Purchases.setLogLevel(LogLevel.debug);
        
        // Mock configure for sandbox, replacing with actual keys if/when available in production.
        // We use a dummy key to prevent crashes on startup.
        await Purchases.configure(
          PurchasesConfiguration("goog_dummy_key_for_shipathon_prep")
        );
        
        // Attempt to sync subscription status from RevenueCat server
        final customerInfo = await Purchases.getCustomerInfo();
        final isActive = customerInfo.entitlements.active.isNotEmpty;
        await _cachePremiumStatus(isActive);
      } catch (e) {
        debugPrint("RevenueCat failed to initialize: $e. Falling back to secure local cache.");
      }
    }
  }

  /// Checks if premium is currently active (checks local offline Hive cache first).
  static bool isPremiumActive() {
    if (_box == null) return false;
    return _box!.get(_keyPremium, defaultValue: false) as bool;
  }

  /// Sets the premium status in local Hive box cache.
  static Future<void> _cachePremiumStatus(bool isActive) async {
    if (_box != null) {
      await _box!.put(_keyPremium, isActive);
    }
  }

  /// Trigger simulation purchase of premium plan for local showcase.
  /// Standard billing works online, offline sets local premium.
  static Future<bool> purchasePremiumMock() async {
    // If we have native device platform, try to buy via RevenueCat
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        // Retrieve offerings
        final offerings = await Purchases.getOfferings();
        if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
          final purchaseResult = await Purchases.purchasePackage(
            offerings.current!.availablePackages.first
          );
          final isActive = purchaseResult.customerInfo.entitlements.active.isNotEmpty;
          await _cachePremiumStatus(isActive);
          return isActive;
        }
      } catch (e) {
        debugPrint("RevenueCat purchase failed: $e. Using local offline checkout simulator.");
      }
    }

    // fallback simulation for offline testing
    await _cachePremiumStatus(true);
    return true;
  }

  /// Restores purchase entitlements.
  static Future<bool> restorePurchases() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final customerInfo = await Purchases.restorePurchases();
        final isActive = customerInfo.entitlements.active.isNotEmpty;
        await _cachePremiumStatus(isActive);
        return isActive;
      } catch (e) {
        debugPrint("RevenueCat restore failed: $e.");
      }
    }
    return isPremiumActive();
  }

  /// Purges local monetization state (danger zone reset utility).
  static Future<void> clearCache() async {
    if (_box != null) {
      await _box!.clear();
    }
  }
}
