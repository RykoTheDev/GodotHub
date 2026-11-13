import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../api/opener.dart';
import '../design/design.dart';
import '../logic/locale.dart';
import '../motion/presence.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/shell/smooth_scroll.dart';

@immutable
class ContributorPr {
  const ContributorPr({
    required this.number,
    required this.title,
    required this.state,
    required this.htmlUrl,
    required this.createdAt,
    this.mergedAt,
  });

  factory ContributorPr.fromJson(Map<String, Object?> item) {
    final pull = item['pull_request'];
    final merged = pull is Map ? pull['merged_at'] as String? : null;
    return ContributorPr(
      number: (item['number'] as num?)?.toInt() ?? 0,
      title: item['title'] as String? ?? '',
      state: merged != null ? 'merged' : (item['state'] as String? ?? 'closed'),
      htmlUrl: item['html_url'] as String? ?? '',
      createdAt: item['created_at'] as String? ?? '',
      mergedAt: merged,
    );
  }

  final int number;
  final String title;
  final String state;
  final String htmlUrl;
  final String createdAt;
  final String? mergedAt;
}

typedef ContributorPrsFetcher = Future<List<ContributorPr>> Function(String login);

Future<List<ContributorPr>> fetchContributorPrs(String login) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse(
        'https://api.github.com/search/issues?q=repo:RykoTheDev/GodotHub+is:pr+author:${Uri.encodeQueryComponent(login)}&per_page=50&sort=created&order=desc',
      ),
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) throw HttpException('HTTP ${response.statusCode}');
    final data = jsonDecode(body);
    final items = data is Map ? data['items'] : null;
    return [
      if (items is List)
        for (final item in items.whereType<Map<String, Object?>>()) ContributorPr.fromJson(item),
    ];
  } finally {
    client.close(force: true);
  }
}

Future<void> showContributorPrsModal(BuildContext context, {required String login, required String avatarUrl}) => showGhModal<void>(
  context,
  (modal) => ContributorPrsModal(login: login, avatarUrl: avatarUrl, onClose: () => Navigator.of(modal).pop()),
);

class ContributorPrsModal extends StatefulWidget {
  const ContributorPrsModal({super.key, required this.login, required this.avatarUrl, required this.onClose, this.fetch});

  final String login;
  final String avatarUrl;
  final VoidCallback onClose;
  final ContributorPrsFetcher? fetch;

  @override
  State<ContributorPrsModal> createState() => _ContributorPrsModalState();
}

class _ContributorPrsModalState extends State<ContributorPrsModal> {
  List<ContributorPr> _prs = const [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    (widget.fetch ?? fetchContributorPrs)(widget.login).then(
      (prs) {
        if (mounted) {
          setState(() {
            _prs = prs;
            _loading = false;
          });
        }
      },
      onError: (Object _) {
        if (mounted) {
          setState(() {
            _error = true;
            _loading = false;
          });
        }
      },
    );
  }

  void _open(String url) => OpenerApi.openUrl(url).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));

  Widget _badge(GhTheme theme, ContributorPr pr) {
    final (label, color) = pr.mergedAt != null
        ? (ghTr('contributor_pr_merged'), theme.accent)
        : pr.state == 'open'
        ? (ghTr('contributor_pr_open'), theme.mint)
        : (ghTr('contributor_pr_closed'), theme.danger);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(theme.rem(0.25))),
      child: Text(
        label,
        style: theme.text(size: GhTextSize.x4s, weight: GhWeight.semibold, color: color),
      ),
    );
  }

  String _date(String iso) {
    final date = DateTime.tryParse(iso);
    return date == null
        ? iso
        : formatLocaleDate(date, const GhDateFormatOptions(year: GhDatePart.numeric, month: GhDatePart.short, day: GhDatePart.numeric));
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final muted = theme.text(size: GhTextSize.sm, color: theme.muted);
    final Widget body;
    if (_loading) {
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: theme.space(12)),
        child: Center(child: GhSpinnerIcon(size: 5, color: theme.ink)),
      );
    } else if (_error) {
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: theme.space(12)),
        child: Column(
          spacing: theme.space(2),
          children: [
            Text(ghTr('contributor_pr_load_failed'), style: muted),
            Text(
              ghTr('contributor_pr_network_hint'),
              style: theme.text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    } else if (_prs.isEmpty) {
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: theme.space(12)),
        child: Center(child: Text(ghTr('contributor_pr_empty'), style: muted)),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _prs.length; i++)
            GhPressable(
              key: ValueKey(_prs[i].number),
              onPressed: () => _open(_prs[i].htmlUrl),
              builder: (context, states) => GhAnimatedBox(
                color: states.active ? theme.raised.withValues(alpha: 0.6) : theme.raised.withValues(alpha: 0),
                border: i == _prs.length - 1 ? null : Border(bottom: BorderSide(color: theme.line.withValues(alpha: 0.5))),
                padding: EdgeInsets.symmetric(horizontal: theme.space(5), vertical: theme.space(3)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: theme.space(3),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: theme.space(0.5)),
                      child: Text(
                        '#${_prs[i].number}',
                        style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted.withValues(alpha: 0.5)),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _prs[i].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: theme.space(0.5)),
                            child: Text(
                              _date(_prs[i].createdAt),
                              style: theme.text(size: GhTextSize.x3s, color: theme.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _badge(theme, _prs[i]),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    final count = _loading
        ? ghTr('contributor_pr_loading')
        : ghTr(_prs.length == 1 ? 'contributor_pr_count_one' : 'contributor_pr_count_other', args: {'count': _prs.length});
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onClose,
          child: const ColoredBox(color: Color(0xB3000000)),
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.all(theme.space(4)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: theme.rem(32), maxHeight: MediaQuery.sizeOf(context).height * 0.8),
              child: Semantics(
                scopesRoute: true,
                explicitChildNodes: true,
                namesRoute: true,
                label: widget.login,
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(theme.radiusModal),
                      boxShadow: GhShadows.xl2(),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: theme.space(5), vertical: theme.space(4)),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: theme.line)),
                          ),
                          child: Row(
                            spacing: theme.space(3),
                            children: [
                              ClipOval(
                                child: Image.network(
                                  widget.avatarUrl,
                                  frameBuilder: ghFadeInFrameBuilder,
                                  width: theme.space(9),
                                  height: theme.space(9),
                                  fit: BoxFit.cover,
                                  semanticLabel: widget.login,
                                  errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GhPressable(
                                      onPressed: () => _open('https://github.com/${widget.login}'),
                                      builder: (context, states) => Text(
                                        widget.login,
                                        style: theme.text(
                                          size: GhTextSize.sm,
                                          weight: GhWeight.semibold,
                                          color: states.active ? theme.accent : theme.ink,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      count,
                                      style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                                    ),
                                  ],
                                ),
                              ),
                              GhPressable(
                                onPressed: widget.onClose,
                                semanticLabel: ghTr('close'),
                                borderRadius: BorderRadius.circular(theme.radiusMd),
                                builder: (context, states) => GhAnimatedBox(
                                  padding: EdgeInsets.all(theme.space(1.5)),
                                  color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
                                  borderRadius: BorderRadius.circular(theme.radiusMd),
                                  child: GhIcon(GhIcons.x, size: theme.space(4), color: states.active ? theme.ink : theme.muted),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(child: GhScrollView(child: body)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
