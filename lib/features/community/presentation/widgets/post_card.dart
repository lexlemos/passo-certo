import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/community_post.dart';
import '../bloc/community_bloc.dart';

class PostCard extends StatelessWidget {
  final CommunityPost post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + nome + tempo + badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                _buildAvatar(post),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.authorName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBlue,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _timeAgo(post.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _CategoryBadge(category: post.category),
                          const SizedBox(width: 6),
                          if (post.location.isNotEmpty)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 11,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      post.location,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[500],
                                            fontSize: 11,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo do post
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.spaceBlue,
                height: 1.45,
              ),
            ),
          ),

          // Rodapé: likes, comentários, share
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            child: Row(
              children: [
                // Like
                _ActionButton(
                  icon: post.likedByMe
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  label: '${post.likes}',
                  color: post.likedByMe
                      ? AppColors.tealPrimary
                      : Colors.grey[500]!,
                  onTap: () => context.read<CommunityBloc>().add(
                    ToggleLikeEvent(post.id),
                  ),
                  semanticLabel: post.likedByMe
                      ? 'Retirar curtida. ${post.likes} curtidas.'
                      : 'Curtir publicação. ${post.likes} curtidas.',
                ),
                const SizedBox(width: 4),
                // Comentários
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: '${post.comments}',
                  color: Colors.grey[500]!,
                  onTap: () {},
                  semanticLabel: '${post.comments} comentários.',
                ),
                const Spacer(),
                // Compartilhar
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: '',
                  color: Colors.grey[500]!,
                  onTap: () {},
                  semanticLabel: 'Compartilhar publicação',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(CommunityPost post) {
    final color = _avatarColor(post.category);
    return CircleAvatar(
      radius: 22,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        post.authorInitials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Color _avatarColor(PostCategory category) {
    switch (category) {
      case PostCategory.danger:
        return AppColors.emergencyRed;
      case PostCategory.tip:
        return AppColors.mintGreen;
      case PostCategory.praise:
        return AppColors.tealPrimary;
      case PostCategory.accessibility:
        return AppColors.alertBlue;
      default:
        return AppColors.spaceBlue;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours} h';
    return 'Há ${diff.inDays} d';
  }
}

class _CategoryBadge extends StatelessWidget {
  final PostCategory category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final cfg = _badgeConfig(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cfg.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: 10, color: cfg.color),
          const SizedBox(width: 3),
          Text(
            cfg.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: cfg.color,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _badgeConfig(PostCategory category) {
    switch (category) {
      case PostCategory.danger:
        return const _BadgeConfig(
          icon: Icons.warning_amber_rounded,
          label: 'Perigo',
          color: AppColors.emergencyRed,
        );
      case PostCategory.tip:
        return const _BadgeConfig(
          icon: Icons.lightbulb_outline,
          label: 'Dica Segura',
          color: AppColors.mintGreen,
        );
      case PostCategory.praise:
        return const _BadgeConfig(
          icon: Icons.star_outline,
          label: 'Elogio',
          color: AppColors.tealPrimary,
        );
      case PostCategory.accessibility:
        return const _BadgeConfig(
          icon: Icons.accessible,
          label: 'Acessibilidade',
          color: AppColors.alertBlue,
        );
      default:
        return const _BadgeConfig(
          icon: Icons.info_outline,
          label: 'Geral',
          color: AppColors.spaceBlue,
        );
    }
  }
}

class _BadgeConfig {
  final IconData icon;
  final String label;
  final Color color;
  const _BadgeConfig({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String semanticLabel;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
