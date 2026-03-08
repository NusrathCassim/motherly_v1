
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motherly_v1/models/user_model.dart';
import 'package:motherly_v1/firestore/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Sign Up with Email & Password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? language,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? firebaseUser = result.user;
      
      if (firebaseUser != null) {
        // Create UserModel
        final userModel = UserModel(
          id: firebaseUser.uid,
          name: name,
          email: email,
          language: language ?? 'english',
          phoneNumber: phoneNumber,
          address: address,
          profilePictureUrl: null,
        );
        
        // Save to Firestore
        await _firestoreService.createUser(userModel);
        
        // Send email verification
        await firebaseUser.sendEmailVerification();
        
        return userModel;
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      print('Sign up error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // Sign In
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? firebaseUser = result.user;
      
      if (firebaseUser != null) {
        // Check if email is verified
        if (!firebaseUser.emailVerified) {
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Please verify your email before signing in',
          );
        }
        
        // Get user data from Firestore
        final userModel = await _firestoreService.getUser(firebaseUser.uid);
        return userModel;
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get Current User from Firestore
  Future<UserModel?> getCurrentUser() async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      return await _firestoreService.getUser(firebaseUser.uid);
    }
    return null;
  }

  // Get Firebase Auth User
  User? getFirebaseUser() {
    return _auth.currentUser;
  }

  // Send Email Verification
  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Check Email Verification Status
  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Update User Profile
  Future<UserModel?> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? address,
    String? profilePictureUrl,
  }) async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      // Get current user data
      UserModel? currentUser = await _firestoreService.getUser(firebaseUser.uid);
      if (currentUser == null) return null;

      // Create updated user model
      final updatedUser = UserModel(
        id: currentUser.id,
        name: name ?? currentUser.name,
        email: currentUser.email,
        language: currentUser.language,
        phoneNumber: phoneNumber ?? currentUser.phoneNumber,
        address: address ?? currentUser.address,
        profilePictureUrl: profilePictureUrl ?? currentUser.profilePictureUrl,
      );

      // Update in Firestore
      await _firestoreService.updateUser(updatedUser);
      
      return updatedUser;
    } catch (e) {
      print('Update profile error: $e');
      rethrow;
    }
  }

  // Auth State Changes Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}