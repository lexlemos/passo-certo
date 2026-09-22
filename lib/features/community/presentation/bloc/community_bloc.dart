import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/community_post.dart';

// --- EVENTS ---
abstract class CommunityEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPostsEvent extends CommunityEvent {}

class FilterByCategoryEvent extends CommunityEvent {
  final PostCategory category;
  FilterByCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class ToggleLikeEvent extends CommunityEvent {
  final String postId;
  ToggleLikeEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}

class AddPostEvent extends CommunityEvent {
  final String content;
  final String location;
  final PostCategory category;

  AddPostEvent({
    required this.content,
    required this.location,
    required this.category,
  });

  @override
  List<Object?> get props => [content, location, category];
}

// --- STATE ---
class CommunityState extends Equatable {
  final List<CommunityPost> allPosts;
  final List<CommunityPost> filteredPosts;
  final PostCategory selectedCategory;
  final bool isLoading;
  final bool postAddedSuccess;

  const CommunityState({
    required this.allPosts,
    required this.filteredPosts,
    required this.selectedCategory,
    this.isLoading = false,
    this.postAddedSuccess = false,
  });

  CommunityState copyWith({
    List<CommunityPost>? allPosts,
    List<CommunityPost>? filteredPosts,
    PostCategory? selectedCategory,
    bool? isLoading,
    bool? postAddedSuccess,
  }) {
    return CommunityState(
      allPosts: allPosts ?? this.allPosts,
      filteredPosts: filteredPosts ?? this.filteredPosts,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      postAddedSuccess: postAddedSuccess ?? this.postAddedSuccess,
    );
  }

  @override
  List<Object?> get props => [
    allPosts,
    filteredPosts,
    selectedCategory,
    isLoading,
    postAddedSuccess,
  ];
}

// --- BLOC ---
class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  static final List<CommunityPost> _mockPosts = [
    CommunityPost(
      id: '1',
      authorName: 'Ana C.',
      authorInitials: 'AC',
      location: 'Av. Paulista, 1000',
      content:
          'Calçada em obras próximo à estação Trianon-Masp. Desvio improvisado está sem piso tátil. Sugiro atravessar para o outro lado da rua antes de chegar no trecho.',
      category: PostCategory.danger,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      likes: 12,
      comments: 3,
    ),
    CommunityPost(
      id: '2',
      authorName: 'Marcos P.',
      authorInitials: 'MP',
      location: 'Parque Ibirapuera',
      content:
          'O novo trajeto pavimentado perto do portão 4 está excelente. O piso tátil direcional foi completamente restaurado e o semáforo sonoro da travessia externa está funcionando perfeitamente hoje.',
      category: PostCategory.tip,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 45,
      comments: 8,
    ),
    CommunityPost(
      id: '3',
      authorName: 'Sandra R.',
      authorInitials: 'SR',
      location: 'Metrô Consolação',
      content:
          'Elevador da estação Consolação voltou a funcionar! Ficou quase 2 semanas fora. Ótima notícia para todos que dependem dele.',
      category: PostCategory.praise,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      likes: 87,
      comments: 14,
    ),
    CommunityPost(
      id: '4',
      authorName: 'Felipe T.',
      authorInitials: 'FT',
      location: 'R. Augusta com Bela Cintra',
      content:
          'Buraco profundo na esquina sem sinalização. Já vi duas pessoas quase caindo. Alguém sabe o canal para reportar para a Prefeitura?',
      category: PostCategory.danger,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      likes: 23,
      comments: 11,
    ),
    CommunityPost(
      id: '5',
      authorName: 'Beatriz L.',
      authorInitials: 'BL',
      location: 'Terminal Bandeira',
      content:
          'Dica de acessibilidade: o Terminal Bandeira tem uma fila prioritária exclusiva no guichê 3 que geralmente está vazia. Bem mais rápido do que a entrada principal.',
      category: PostCategory.tip,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      likes: 31,
      comments: 6,
    ),
  ];

  CommunityBloc()
    : super(
        CommunityState(
          allPosts: _mockPosts,
          filteredPosts: _mockPosts,
          selectedCategory: PostCategory.all,
        ),
      ) {
    on<LoadPostsEvent>(_onLoad);
    on<FilterByCategoryEvent>(_onFilter);
    on<ToggleLikeEvent>(_onToggleLike);
    on<AddPostEvent>(_onAddPost);
  }

  void _onLoad(LoadPostsEvent event, Emitter<CommunityState> emit) {
    emit(state.copyWith(isLoading: false));
  }

  void _onFilter(FilterByCategoryEvent event, Emitter<CommunityState> emit) {
    final filtered = event.category == PostCategory.all
        ? state.allPosts
        : state.allPosts.where((p) => p.category == event.category).toList();

    emit(
      state.copyWith(selectedCategory: event.category, filteredPosts: filtered),
    );
  }

  void _onToggleLike(ToggleLikeEvent event, Emitter<CommunityState> emit) {
    final updated = state.allPosts.map((post) {
      if (post.id == event.postId) {
        final liked = !post.likedByMe;
        return post.copyWith(
          likedByMe: liked,
          likes: liked ? post.likes + 1 : post.likes - 1,
        );
      }
      return post;
    }).toList();

    final filtered = state.selectedCategory == PostCategory.all
        ? updated
        : updated.where((p) => p.category == state.selectedCategory).toList();

    emit(state.copyWith(allPosts: updated, filteredPosts: filtered));
  }

  void _onAddPost(AddPostEvent event, Emitter<CommunityState> emit) async {
    emit(state.copyWith(isLoading: true, postAddedSuccess: false));
    await Future.delayed(const Duration(milliseconds: 400));

    final newPost = CommunityPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: 'Você',
      authorInitials: 'VC',
      location: event.location,
      content: event.content,
      category: event.category,
      createdAt: DateTime.now(),
      likes: 0,
      comments: 0,
    );

    final updated = [newPost, ...state.allPosts];
    final filtered = state.selectedCategory == PostCategory.all
        ? updated
        : updated.where((p) => p.category == state.selectedCategory).toList();

    emit(
      state.copyWith(
        allPosts: updated,
        filteredPosts: filtered,
        isLoading: false,
        postAddedSuccess: true,
      ),
    );
  }
}
