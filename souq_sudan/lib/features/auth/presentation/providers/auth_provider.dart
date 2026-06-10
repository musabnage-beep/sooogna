import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// Firebase providers
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Auth state changes stream
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Data source
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

// Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

// Current user stream
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final firebaseUser = authState.value;
  if (firebaseUser == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchUser(firebaseUser.uid);
});

// Auth state notifier
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<String?> sendOtp(String phoneNumber) async {
    state = const AsyncValue.loading();
    final result = await _repository.sendOtp(phoneNumber);
    return result.when(
      success: (verificationId) {
        state = const AsyncValue.data(null);
        return verificationId;
      },
      failure: (message, _) {
        state = AsyncValue.error(message, StackTrace.current);
        return null;
      },
    );
  }

  Future<bool> verifyOtp(String verificationId, String otp) async {
    state = const AsyncValue.loading();
    final result = await _repository.verifyOtp(verificationId, otp);
    return result.when(
      success: (value) {
        state = const AsyncValue.data(null);
        return value;
      },
      failure: (message, _) {
        state = AsyncValue.error(message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> userExists(String uid) async {
    final result = await _repository.userExists(uid);
    return result.dataOrNull ?? false;
  }

  Future<AppUser?> createUser(String uid, String name, String phone, {String? city, String? gender}) async {
    state = const AsyncValue.loading();
    final result = await _repository.createUser(uid, name, phone, city: city, gender: gender);
    return result.when(
      success: (user) {
        state = const AsyncValue.data(null);
        return user;
      },
      failure: (message, _) {
        state = AsyncValue.error(message, StackTrace.current);
        return null;
      },
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    // Clear this device's push token while still authenticated, so the user
    // stops receiving notifications after signing out.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await _repository.updateFcmToken(uid, '');
      } catch (_) {}
    }
    // Invalidate the device token at the FCM level too. Even if the Firestore
    // write above failed (e.g. offline), the previously stored token becomes
    // unusable, so notifications can't leak to the next user of this device.
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    final result = await _repository.logout();
    result.when(
      success: (_) => state = const AsyncValue.data(null),
      failure: (message, _) => state = AsyncValue.error(message, StackTrace.current),
    );
  }

  Future<void> saveFcmToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _repository.updateFcmToken(userId, token);
      }
    } catch (_) {}
  }

  void clearError() {
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
