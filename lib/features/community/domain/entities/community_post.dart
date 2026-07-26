import 'package:equatable/equatable.dart';

enum PostCategory { all, accessibility, danger, tip, praise }

extension PostCategoryExtension on PostCategory {
  String get label {
    switch (this) {
      case PostCategory.all:
        return 'Tudo';
      case PostCategory.accessibility:
        return 'Acessibilidade';
      case PostCategory.danger:
        return 'Perigos';
      case PostCategory.tip:
        return 'Dicas';
      case PostCategory.praise:
        return 'Elogios';
    }
  }
}

class CommunityPost extends Equatable {
  final String id;
  final String authorName;
  final String authorInitials;
  final String location;
  final String content;
  final PostCategory category;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final bool likedByMe;

  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.location,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.likes,
    required this.comments,
    this.likedByMe = false,
  });

  CommunityPost copyWith({
    String? id,
    String? authorName,
    String? authorInitials,
    String? location,
    String? content,
    PostCategory? category,
    DateTime? createdAt,
    int? likes,
    int? comments,
    bool? likedByMe,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorInitials: authorInitials ?? this.authorInitials,
      location: location ?? this.location,
      content: content ?? this.content,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  @override
  List<Object?> get props => [
    id,
    authorName,
    location,
    content,
    category,
    createdAt,
    likes,
    comments,
    likedByMe,
  ];
}
