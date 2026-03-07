class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? address;
  final String? language;
  final String? profilePictureUrl;
  final String? phoneNumber;
 

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.address,
    this.language,
    this.profilePictureUrl,
    this.phoneNumber,

  });

  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'],
      address: data['address'],
      language: data['language'] ?? 'si',
      profilePictureUrl: data['profilePictureUrl'],
      phoneNumber: data['phoneNumber'],

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'address': address,
      'language': language,
      'profilePictureUrl': profilePictureUrl,
      'phoneNumber': phoneNumber,

    };
  }
}