import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/campus_bounds.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthViewModel() {
    _initAuthState();
  }

  void _initAuthState() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserProfile(user.uid, user.email);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile(String uid, String? fallbackEmail) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!, uid);
        if (_currentUser!.university.isNotEmpty) {
          CampusBounds.resolveRegion(_currentUser!.university);
        }
      } else {
        // Create user record if document doesn't exist yet
        final newUser = UserModel(
          uid: uid,
          name: fallbackEmail?.split('@').first ?? 'Student',
          email: fallbackEmail ?? '',
          university: 'Stanford University',
        );
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(uid)
            .set(newUser.toMap());
        _currentUser = newUser;
        CampusBounds.resolveRegion('Stanford University');
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      // Graceful fallback for offline / mock testing
      _currentUser = UserModel(
        uid: uid,
        name: fallbackEmail?.split('@').first ?? 'Student',
        email: fallbackEmail ?? '',
        university: 'Stanford University',
      );
    }
    notifyListeners();
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String university,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) {
        _setError('Registration failed: User could not be created.');
        _setLoading(false);
        return false;
      }

      final cleanUniversity = CampusBounds.canonicalUniversityName(university);
      final userModel = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        university: cleanUniversity,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .set(userModel.toMap());

      _currentUser = userModel;
      _setLoading(false);
      notifyListeners();
      CampusBounds.resolveRegion(userModel.university);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Unexpected error during registration: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null) {
        await _loadUserProfile(user.uid, user.email);
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Unexpected error during login: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Future<bool> updateUniversity(String newUniversity) async {
    if (_currentUser == null) return false;

    try {
      final clean = CampusBounds.canonicalUniversityName(newUniversity);
      final updated = _currentUser!.copyWith(university: clean);
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.uid)
          .update({'university': clean});
      _currentUser = updated;
      notifyListeners();
      CampusBounds.resolveRegion(clean);
      return true;
    } catch (e) {
      _setError('Failed to update university: $e');
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No student account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this university email.';
      case 'invalid-email':
        return 'The provided email address is invalid.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'internal-error':
        return 'Firebase internal error. Please ensure "Email/Password" is enabled under Authentication > Sign-in method in your Firebase Console.';
      case 'network-request-failed':
        return 'Network request failed. Please check your internet connection.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
