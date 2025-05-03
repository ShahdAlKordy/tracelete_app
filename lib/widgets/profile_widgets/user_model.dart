class UserProfile {
  final String name;
  final String email;
  final String profileImageUrl;

  const UserProfile({
    required this.name,
    required this.email,
    required this.profileImageUrl,
  });

  // Factory constructor to create a UserProfile from Firestore data
  factory UserProfile.fromFirestore(Map<String, dynamic> data, String email) {
    return UserProfile(
      name: data['name'] ?? 'No Name',
      email: email,
      profileImageUrl: data['profileImage'] ?? '',
    );
  }

  // Empty constructor for loading state
  factory UserProfile.loading() {
    return const UserProfile(
      name: 'Loading...',
      email: 'Loading...',
      profileImageUrl: '',
    );
  }
}