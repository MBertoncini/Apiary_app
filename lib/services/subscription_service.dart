// lib/services/subscription_service.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/user.dart';

/// Entitlement identifier configured in RevenueCat dashboard.
const String _entitlementId = 'Apiary Pro';

/// RevenueCat Google Play API key.
const String _googleApiKey = 'test_sruxOgpFHUNKppRASBVoFuILwzX';

/// Wraps the RevenueCat SDK for subscription management.
///
/// Lifecycle:
///   1. Call [init] once at app start (before login).
///   2. Call [login] after the user authenticates (links RC customer to your user).
///   3. Call [logout] when the user signs out.
///
/// The service exposes [isProActive] / [currentTier] that map RevenueCat
/// entitlements to the app's [AiTier] enum.
class SubscriptionService with ChangeNotifier {
  bool _initialized = false;
  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  bool _isPurchasing = false;
  String? _error;

  // ── Public getters ────────────────────────────────────────────────────────

  bool get initialized => _initialized;
  CustomerInfo? get customerInfo => _customerInfo;
  Offerings? get offerings => _offerings;
  bool get isPurchasing => _isPurchasing;
  String? get error => _error;

  /// Whether the user has an active "Apiary Pro" entitlement.
  bool get isProActive {
    return _customerInfo?.entitlements.all[_entitlementId]?.isActive ?? false;
  }

  /// Map RC entitlement → app tier.
  AiTier get currentTier {
    if (!_initialized || _customerInfo == null) return AiTier.free;
    if (isProActive) {
      // Distinguish yearly (professionale) vs monthly (apicoltore) by product.
      final ent = _customerInfo!.entitlements.all[_entitlementId]!;
      final productId = ent.productIdentifier;
      if (productId.contains('yearly')) return AiTier.professionale;
      return AiTier.apicoltore;
    }
    return AiTier.free;
  }

  /// The current offering's available packages (monthly, yearly, etc.).
  List<Package> get availablePackages {
    return _offerings?.current?.availablePackages ?? [];
  }

  /// Monthly package shortcut.
  Package? get monthlyPackage => _offerings?.current?.monthly;

  /// Annual package shortcut.
  Package? get annualPackage => _offerings?.current?.annual;

  // ── Initialization ────────────────────────────────────────────────────────

  /// Call once at app startup. Safe to call multiple times — only inits once.
  ///
  /// Currently a no-op: RevenueCat SDK is installed but purchases are not yet
  /// available (requires partita IVA + Google Play billing setup).
  /// When ready, remove the early return and uncomment the configuration block.
  Future<void> init() async {
    if (_initialized) return;

    // ── RC disabled until in-app purchases are ready ──
    debugPrint('SubscriptionService: init skipped (purchases not yet available)');
    return;

    // ignore: dead_code
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      final PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_googleApiKey);
      } else {
        // iOS placeholder — add Apple key when ready.
        debugPrint('SubscriptionService: iOS not configured yet');
        return;
      }

      await Purchases.configure(configuration);

      // Listen to customer info changes (renewal, expiry, etc.)
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      _initialized = true;
      debugPrint('SubscriptionService: initialized');

      // Fetch current state.
      await Future.wait([
        _refreshCustomerInfo(),
        fetchOfferings(),
      ]);
    } catch (e) {
      debugPrint('SubscriptionService init error: $e');
      _error = e.toString();
    }
  }

  // ── User identity ─────────────────────────────────────────────────────────

  /// Link the RevenueCat anonymous customer to your backend user id.
  /// Call after successful login.
  Future<void> login(String appUserId) async {
    if (!_initialized) return;
    try {
      final result = await Purchases.logIn(appUserId);
      _customerInfo = result.customerInfo;
      notifyListeners();
      debugPrint('SubscriptionService: logged in as $appUserId');
    } catch (e) {
      debugPrint('SubscriptionService login error: $e');
    }
  }

  /// Detach user identity. Call on app logout.
  Future<void> logout() async {
    if (!_initialized) return;
    try {
      _customerInfo = await Purchases.logOut();
      notifyListeners();
      debugPrint('SubscriptionService: logged out');
    } catch (e) {
      debugPrint('SubscriptionService logout error: $e');
    }
  }

  // ── Offerings ─────────────────────────────────────────────────────────────

  /// Fetch available products/offerings from RevenueCat.
  Future<void> fetchOfferings() async {
    if (!_initialized) return;
    try {
      _offerings = await Purchases.getOfferings();
      notifyListeners();
      debugPrint(
          'SubscriptionService: offerings loaded — '
          '${_offerings?.current?.availablePackages.length ?? 0} packages');
    } catch (e) {
      debugPrint('SubscriptionService fetchOfferings error: $e');
    }
  }

  // ── Purchases ─────────────────────────────────────────────────────────────

  /// Purchase a specific package. Returns true on success.
  Future<bool> purchasePackage(Package package) async {
    if (!_initialized) return false;

    _isPurchasing = true;
    _error = null;
    notifyListeners();

    try {
      final purchaseParams = PurchaseParams.package(package);
      final result = await Purchases.purchase(purchaseParams);
      _customerInfo = result.customerInfo;
      _isPurchasing = false;
      notifyListeners();

      final active = _customerInfo
              ?.entitlements.all[_entitlementId]?.isActive ??
          false;
      debugPrint('SubscriptionService: purchase complete — pro=$active');
      return active;
    } on PlatformException catch (e) {
      _isPurchasing = false;
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        // User cancelled — not an error.
        debugPrint('SubscriptionService: purchase cancelled by user');
        notifyListeners();
        return false;
      }
      _error = e.message;
      notifyListeners();
      debugPrint('SubscriptionService: purchase error $errorCode — ${e.message}');
      return false;
    }
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  /// Restore previous purchases (e.g. after reinstall).
  Future<bool> restorePurchases() async {
    if (!_initialized) return false;
    try {
      _customerInfo = await Purchases.restorePurchases();
      notifyListeners();
      debugPrint('SubscriptionService: purchases restored');
      return isProActive;
    } on PlatformException catch (e) {
      _error = e.message;
      notifyListeners();
      debugPrint('SubscriptionService: restore error — ${e.message}');
      return false;
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _refreshCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      notifyListeners();
    } catch (e) {
      debugPrint('SubscriptionService _refreshCustomerInfo error: $e');
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _customerInfo = info;
    notifyListeners();
    debugPrint('SubscriptionService: customerInfo updated — pro=$isProActive');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
