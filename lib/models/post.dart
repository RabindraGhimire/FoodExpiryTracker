import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String name;
  final String expiry;
  final String condition;
  final double latitude;
  final double longitude;
  final List<String> likes;
  final List<String> comments;
  final Timestamp timestamp;
  final bool claimed;
  final String userId;
  final String category;
  final String username;
  final String userPhoto;
  final String imageUrl; // ✅ NEW

  Post({
    required this.id,
    required this.name,
    required this.expiry,
    required this.condition,
    required this.latitude,
    required this.longitude,
    required this.likes,
    required this.comments,
    required this.timestamp,
    required this.claimed,
    required this.userId,
    required this.category,
    required this.username,
    required this.userPhoto,
    required this.imageUrl, // ✅ NEW
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<String> parseLikes(dynamic likesData) {
      if (likesData is List) {
        return List<String>.from(likesData);
      }
      return [];
    }

    List<String> parseComments(dynamic commentsData) {
      if (commentsData is List) {
        return List<String>.from(commentsData);
      }
      return [];
    }

    String usernameFromData(Map<String, dynamic> data) {
      final userNameFromField = data['username']?.toString();
      if (userNameFromField != null &&
          userNameFromField.isNotEmpty &&
          userNameFromField != 'Anonymous') {
        return userNameFromField;
      }

      final firstName = data['firstName']?.toString() ?? '';
      final lastName = data['lastName']?.toString() ?? '';
      final fullName = '$firstName $lastName'.trim();
      if (fullName.isNotEmpty) return fullName;

      return 'Anonymous';
    }

    return Post(
      id: doc.id,
      name: data['name']?.toString() ?? 'No Name',
      expiry: data['expiry']?.toString() ?? 'No Expiry',
      condition: data['condition']?.toString() ?? 'No Condition',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      likes: parseLikes(data['likes']),
      comments: parseComments(data['comments']),
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      claimed: data['claimed'] as bool? ?? false,
      userId: data['userId']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Other',
      username: usernameFromData(data),
      userPhoto: data['userPhoto']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '', // ✅ NEW
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'expiry': expiry,
      'condition': condition,
      'latitude': latitude,
      'longitude': longitude,
      'likes': likes,
      'comments': comments,
      'timestamp': timestamp,
      'claimed': claimed,
      'userId': userId,
      'category': category,
      'username': username,
      'userPhoto': userPhoto,
      'imageUrl': imageUrl, // ✅ NEW
    };
  }
}
