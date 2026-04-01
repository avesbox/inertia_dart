import 'dart:io';

import 'package:inertia_dart/inertia_dart.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_inertia/serinus_inertia.dart';

const List<Map<String, dynamic>> _teamMembers = [
  {
    'id': 1,
    'name': 'Ada Lovelace',
    'role': 'Platform Engineer',
    'team': 'platform',
    'location': 'London',
    'focus': 'Typed protocol boundaries',
    'availability': 'On review duty',
    'stack': ['Dart', 'Rust', 'Postgres'],
  },
  {
    'id': 2,
    'name': 'Grace Hopper',
    'role': 'Release Captain',
    'team': 'operations',
    'location': 'New York',
    'focus': 'Version drift detection',
    'availability': 'Coordinating cutover',
    'stack': ['CI', 'Observability', 'HTTP'],
  },
  {
    'id': 3,
    'name': 'Margaret Hamilton',
    'role': 'Systems Architect',
    'team': 'platform',
    'location': 'Boston',
    'focus': 'Runtime failover and SSR boundaries',
    'availability': 'Pairing on SSR',
    'stack': ['SSR', 'Distributed systems', 'Design reviews'],
  },
  {
    'id': 4,
    'name': 'Annie Easley',
    'role': 'Quality Lead',
    'team': 'quality',
    'location': 'Cleveland',
    'focus': 'Regression coverage',
    'availability': 'Writing test plans',
    'stack': ['Smoke tests', 'Checks', 'Benchmarks'],
  },
  {
    'id': 5,
    'name': 'Radia Perlman',
    'role': 'Experience Engineer',
    'team': 'experience',
    'location': 'Seattle',
    'focus': 'Hydration and navigation flow',
    'availability': 'Profiling transitions',
    'stack': ['React', 'CSS', 'A11y'],
  },
  {
    'id': 6,
    'name': 'Katherine Johnson',
    'role': 'Data Reliability Engineer',
    'team': 'quality',
    'location': 'Hampton',
    'focus': 'Pagination integrity',
    'availability': 'Investigating edge cases',
    'stack': ['Metrics', 'Math', 'Incident drills'],
  },
];

const Map<String, String> _teamLabels = {
  'all': 'All teams',
  'platform': 'Platform',
  'operations': 'Operations',
  'quality': 'Quality',
  'experience': 'Experience',
};

const List<List<Map<String, dynamic>>> _highlightBatches = [
  [
    {
      'id': 'merge-1',
      'title': 'Protocol health dashboard',
      'note':
          'Loaded in the initial visit so we can verify merge semantics later.',
      'owner': 'Ada',
    },
    {
      'id': 'merge-2',
      'title': 'Version mismatch drill',
      'note': 'Useful when validating hard refresh behavior after deploy.',
      'owner': 'Grace',
    },
  ],
  [
    {
      'id': 'merge-3',
      'title': 'Scroll reset rehearsal',
      'note': 'Confirms reset keys clear accumulated batches cleanly.',
      'owner': 'Katherine',
    },
    {
      'id': 'merge-4',
      'title': 'Deferred hydration check',
      'note': 'Ensures slow sections stay off the critical rendering path.',
      'owner': 'Margaret',
    },
  ],
  [
    {
      'id': 'merge-5',
      'title': 'External redirect fallback',
      'note': 'Good for location-based hops or auth gateways.',
      'owner': 'Radia',
    },
    {
      'id': 'merge-6',
      'title': 'SSR parity sweep',
      'note': 'Compare first paint and client hydration after bundle changes.',
      'owner': 'Annie',
    },
  ],
];

const List<List<Map<String, dynamic>>> _activityPages = [
  [
    {
      'id': 'activity-1',
      'lane': 'Build',
      'actor': 'Grace Hopper',
      'action':
          'Published a new version hash and kicked off a deploy rehearsal.',
      'minute': '09:02',
      'severity': 'stable',
    },
    {
      'id': 'activity-2',
      'lane': 'Client',
      'actor': 'Radia Perlman',
      'action':
          'Confirmed the home page hydrated without replacing SSR markup.',
      'minute': '09:07',
      'severity': 'stable',
    },
    {
      'id': 'activity-3',
      'lane': 'Data',
      'actor': 'Katherine Johnson',
      'action': 'Loaded scroll page 1 to establish the baseline cursor state.',
      'minute': '09:11',
      'severity': 'watch',
    },
  ],
  [
    {
      'id': 'activity-4',
      'lane': 'Protocol',
      'actor': 'Ada Lovelace',
      'action': 'Triggered a partial reload for diagnostics only.',
      'minute': '09:16',
      'severity': 'stable',
    },
    {
      'id': 'activity-5',
      'lane': 'SSR',
      'actor': 'Margaret Hamilton',
      'action': 'Restarted the renderer and verified the health endpoint.',
      'minute': '09:20',
      'severity': 'watch',
    },
    {
      'id': 'activity-6',
      'lane': 'Quality',
      'actor': 'Annie Easley',
      'action': 'Exercised reset keys after a merged highlight batch.',
      'minute': '09:24',
      'severity': 'stable',
    },
  ],
  [
    {
      'id': 'activity-7',
      'lane': 'History',
      'actor': 'Grace Hopper',
      'action':
          'Validated encrypt-history mode during a manual navigation pass.',
      'minute': '09:28',
      'severity': 'stable',
    },
    {
      'id': 'activity-8',
      'lane': 'Observability',
      'actor': 'Katherine Johnson',
      'action': 'Pulled a fresh telemetry snapshot through a lazy prop reload.',
      'minute': '09:33',
      'severity': 'watch',
    },
    {
      'id': 'activity-9',
      'lane': 'UX',
      'actor': 'Radia Perlman',
      'action': 'Checked remembered draft state after switching between pages.',
      'minute': '09:39',
      'severity': 'stable',
    },
  ],
  [
    {
      'id': 'activity-10',
      'lane': 'Release',
      'actor': 'Grace Hopper',
      'action': 'Completed the redirect drill for the post-action workflow.',
      'minute': '09:44',
      'severity': 'stable',
    },
    {
      'id': 'activity-11',
      'lane': 'Performance',
      'actor': 'Margaret Hamilton',
      'action':
          'Measured deferred section timing after the first contentful paint.',
      'minute': '09:48',
      'severity': 'stable',
    },
    {
      'id': 'activity-12',
      'lane': 'QA',
      'actor': 'Annie Easley',
      'action': 'Signed off on the end-to-end feature lab route.',
      'minute': '09:53',
      'severity': 'stable',
    },
  ],
];

class AppController extends Controller {
  AppController() : super('/') {
    on(Route.get('/'), _home);
    on(Route.get('/users'), _users);
    on(Route.get('/lab'), _lab);
    on(Route.post('/lab/high-five'), _labHighFive);
  }

  Future<Object?> _home(RequestContext context) async {
    return context.inertia(
      component: 'Home',
      props: {
        'title': 'Serinus + Inertia feature lab',
        'message':
            'A fuller demo app for stressing first visits, partial reloads, deferred sections, infinite scroll, remembered state, redirects, and optional SSR.',
        'overviewStats': const [
          {
            'label': 'Routes',
            'value': '4',
            'detail': 'Home, users, lab, and a post action redirect.',
          },
          {
            'label': 'Protocol drills',
            'value': '8',
            'detail':
                'Versioning, merge, lazy, deferred, scroll, flash, polling, and history flags.',
          },
          {
            'label': 'Client patterns',
            'value': '6',
            'detail':
                'Links, remembered state, reloads, infinite scroll, visible loads, and SSR hydration.',
          },
        ],
        'routeCards': const [
          {
            'id': 'users',
            'title': 'Users route',
            'href': '/users',
            'eyebrow': 'Remembered local state',
            'summary':
                'Use this page to verify server filtering, lazy props, and remembered client state when moving through history.',
            'checks': [
              'Team filter query parameters',
              'Remembered local search and selection on back/forward navigation',
              'Lazy diagnostics partial reload',
            ],
          },
          {
            'id': 'lab',
            'title': 'Feature lab',
            'href': '/lab',
            'eyebrow': 'Protocol-heavy route',
            'summary':
                'This page concentrates the runtime-specific features that are harder to shake out with a static example.',
            'checks': [
              'Deferred and optional prop loading',
              'Merge props and infinite scroll',
              'Polling, flash data, redirects, and history flags',
            ],
          },
        ],
        'protocols': const [
          {
            'title': 'Partial reloads',
            'detail':
                'Reload one prop at a time and confirm the client preserves local state while server data changes.',
          },
          {
            'title': 'Deferred payloads',
            'detail':
                'Keep heavyweight sections out of the first response and watch them resolve after paint.',
          },
          {
            'title': 'Scroll props',
            'detail':
                'Test merge-aware pagination with explicit page metadata for InfiniteScroll.',
          },
          {
            'title': 'History controls',
            'detail':
                'Toggle encrypt and clear history flags to validate browser behavior during QA.',
          },
        ],
        'launchChecklist': const [
          'Run the client in dev mode and confirm Vite assets are injected.',
          'Switch on SSR and compare the first paint against the client-only run.',
          'Use the feature lab to verify merge resets and deferred section loading.',
          'Reload just the diagnostics props to check the lazy path stays isolated.',
        ],
      },
    );
  }

  Future<Object?> _users(RequestContext context) async {
    final activeTeam = _normalizeTeam(context.queryAs<String>('team'));
    final users = _filterUsers(activeTeam);

    return context.inertia(
      component: 'Users',
      props: {
        'title': 'Team directory',
        'description':
            'This route mixes server filtering with remembered history state so we can test how partial reloads behave while the user is mid-flow.',
        'activeTeam': activeTeam,
        'teams': _buildTeamFilters(activeTeam),
        'users': users,
        'headlineStats': [
          {
            'label': 'Visible people',
            'value': users.length.toString(),
            'detail': 'Server-side filtered by the active team query.',
          },
          {
            'label': 'Total teams',
            'value': (_teamLabels.length - 1).toString(),
            'detail':
                'A quick way to validate query-param routing across links.',
          },
          {
            'label': 'Lazy drill',
            'value': 'Ready',
            'detail':
                'Diagnostics stay out of the initial payload until requested.',
          },
        ],
        'serverRequest': {
          'team': activeTeam,
          'generatedAt': DateTime.now().toUtc().toIso8601String(),
        },
        'insights': LazyProp<Map<String, dynamic>>(
          () => _buildUserDiagnostics(activeTeam),
        ),
      },
    );
  }

  Future<Object?> _lab(RequestContext context) async {
    final highlightBatch = _clampBatch(
      context.queryAs<int>('highlights_batch') ?? 1,
    );
    final activityPage = _clampActivityPage(
      context.queryAs<int>('activity_page') ?? 1,
    );
    final notice = context.queryAs<String>('flash');
    final historyMode = context.queryAs<String>('history');

    return context.inertia(
      component: 'Lab',
      encryptHistory: historyMode == 'encrypt',
      clearHistory: historyMode == 'clear',
      flash: notice == null ? null : {'notice': notice},
      props: {
        'title': 'Feature lab',
        'description':
            'A single route for beating on the Inertia adapter with the behaviors that matter during integration testing.',
        'historyMode': historyMode ?? 'default',
        'notice': notice,
        'liveStats': _buildLiveStats(),
        'releaseTimeline': DeferredProp<List<Map<String, dynamic>>>(
          _buildReleaseTimeline,
          group: 'release',
        ),
        'deepDive': OptionalProp<Map<String, dynamic>>(_buildDeepDive),
        'diagnostics': LazyProp<Map<String, dynamic>>(
          () => _buildLabDiagnostics(
            historyMode: historyMode,
            notice: notice,
            highlightBatch: highlightBatch,
            activityPage: activityPage,
          ),
        ),
        'highlights': MergeProp<Map<String, dynamic>>(
          () => _buildHighlightsPayload(highlightBatch),
        ).append('items', 'id'),
        'activity': ScrollProp<Map<String, dynamic>>(
          () => _buildActivityPayload(activityPage),
          metadata: (value) => ScrollMetadata(
            pageName: 'activity_page',
            previousPage: value['previousPage'] as int?,
            nextPage: value['nextPage'] as int?,
            currentPage: value['currentPage'] as int?,
          ),
        ),
      },
    );
  }

  Future<Object?> _labHighFive(RequestContext context) async {
    final message = Uri.encodeQueryComponent(
      'Server action complete. Redirect path looks healthy.',
    );
    return Redirect('/lab?flash=$message', statusCode: HttpStatus.seeOther);
  }
}

String _normalizeTeam(String? rawTeam) {
  if (rawTeam == null || !_teamLabels.containsKey(rawTeam)) {
    return 'all';
  }
  return rawTeam;
}

List<Map<String, dynamic>> _filterUsers(String activeTeam) {
  if (activeTeam == 'all') {
    return _teamMembers;
  }

  return _teamMembers
      .where((user) => user['team'] == activeTeam)
      .toList(growable: false);
}

List<Map<String, dynamic>> _buildTeamFilters(String activeTeam) {
  return _teamLabels.entries
      .map((entry) {
        final key = entry.key;
        final count = key == 'all'
            ? _teamMembers.length
            : _teamMembers.where((user) => user['team'] == key).length;
        return {
          'id': key,
          'label': entry.value,
          'count': count,
          'href': key == 'all' ? '/users' : '/users?team=$key',
          'active': key == activeTeam,
        };
      })
      .toList(growable: false);
}

Map<String, dynamic> _buildUserDiagnostics(String activeTeam) {
  final selectedUsers = _filterUsers(activeTeam);
  final teamsTouched = selectedUsers
      .map((user) => _teamLabels[user['team']] ?? user['team'])
      .toSet()
      .toList(growable: false);

  return {
    'fetchedAt': DateTime.now().toUtc().toIso8601String(),
    'activeTeamLabel': _teamLabels[activeTeam] ?? activeTeam,
    'coverage': selectedUsers.length,
    'teamsTouched': teamsTouched,
    'checks': [
      'Lazy prop arrived without disturbing the current search state.',
      'Server query filtering still matches the visible roster.',
      'This request can be repeated safely with router.reload({ only: [\'insights\'] }).',
    ],
  };
}

Map<String, dynamic> _buildLiveStats() {
  final now = DateTime.now().toUtc();
  final minute = now.minute.toString().padLeft(2, '0');
  final second = now.second.toString().padLeft(2, '0');

  return {
    'polledAt': '${now.hour}:$minute:$second UTC',
    'requestsPerMinute': 42 + (now.second % 9),
    'renderer': now.second.isEven ? 'warm' : 'catching up',
    'queueDepth': 2 + (now.second % 4),
    'status': now.second.isEven ? 'steady' : 'watching',
  };
}

List<Map<String, dynamic>> _buildReleaseTimeline() {
  return const [
    {
      'title': 'Bootstrap alignment',
      'summary':
          'Confirm the HTML shell, asset tags, and SSR head/body all line up across development and production.',
      'checks': [
        'Client entry and SSR entry point to the same page tree.',
        'The bootstrap container stays stable during hydration.',
      ],
    },
    {
      'title': 'Protocol verification',
      'summary':
          'Shake out merge props, deferred groups, flash payloads, and versioned reloads with repeatable steps.',
      'checks': [
        'Deferred sections stay absent from the first JSON page payload.',
        'Reset keys clear accumulated merge state when requested.',
      ],
    },
    {
      'title': 'Operational handoff',
      'summary':
          'Run the package in both managed-SSR and externally managed SSR modes before release.',
      'checks': [
        'Node or Bun startup behavior is deterministic.',
        'The lab route remains usable even when SSR is disabled.',
      ],
    },
  ];
}

Map<String, dynamic> _buildDeepDive() {
  return const {
    'headline':
        'Optional props work best when the UI can stay useful without them.',
    'sections': [
      {
        'title': 'Payload discipline',
        'detail':
            'Keep heavy investigative data out of the first response until a tester actually scrolls to it.',
      },
      {
        'title': 'Intentional hydration',
        'detail':
            'Optional props let us prove a page can boot fast, then expand into richer diagnostics later.',
      },
      {
        'title': 'Repeatable QA',
        'detail':
            'Because the load is explicit, it is easy to capture network traces for regression checks.',
      },
    ],
    'matrix': [
      {
        'name': 'First visit',
        'expectation': 'No deepDive prop in the initial page props.',
      },
      {
        'name': 'Scroll into view',
        'expectation':
            'The client requests only deepDive and merges it in place.',
      },
      {
        'name': 'Navigate away and back',
        'expectation':
            'The route remains useful before the optional section returns.',
      },
    ],
  };
}

int _clampBatch(int batch) {
  if (batch < 1) {
    return 1;
  }
  if (batch > _highlightBatches.length) {
    return _highlightBatches.length;
  }
  return batch;
}

Map<String, dynamic> _buildHighlightsPayload(int batch) {
  final currentBatch = _clampBatch(batch);
  return {
    'items': _highlightBatches[currentBatch - 1],
    'loadedBatch': currentBatch,
    'totalBatches': _highlightBatches.length,
    'remainingBatches': _highlightBatches.length - currentBatch,
  };
}

int _clampActivityPage(int page) {
  if (page < 1) {
    return 1;
  }
  if (page > _activityPages.length) {
    return _activityPages.length;
  }
  return page;
}

Map<String, dynamic> _buildActivityPayload(int page) {
  final currentPage = _clampActivityPage(page);
  return {
    'data': _activityPages[currentPage - 1],
    'currentPage': currentPage,
    'previousPage': currentPage > 1 ? currentPage - 1 : null,
    'nextPage': currentPage < _activityPages.length ? currentPage + 1 : null,
    'totalPages': _activityPages.length,
  };
}

Map<String, dynamic> _buildLabDiagnostics({
  required String? historyMode,
  required String? notice,
  required int highlightBatch,
  required int activityPage,
}) {
  return {
    'requestedAt': DateTime.now().toUtc().toIso8601String(),
    'historyMode': historyMode ?? 'default',
    'noticePresent': notice != null,
    'highlightBatch': highlightBatch,
    'activityPage': activityPage,
    'qaChecklist': [
      'Poll live stats without resetting scroll position.',
      'Load the deferred release timeline after the page paints.',
      'Scroll until the optional deep dive section requests itself.',
      'Append another merge batch, then reset it and verify the client state clears.',
      'Use the post action button and confirm the redirect lands with flash data.',
    ],
  };
}
