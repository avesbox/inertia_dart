import { Head, Link, router, useRemember } from '@inertiajs/react'

export default function Users({
  title,
  description,
  users,
  teams,
  activeTeam,
  headlineStats,
  serverRequest,
  insights,
  appName,
}) {
  const [search, setSearch] = useRemember('', 'users:search')
  const [selectedUserId, setSelectedUserId] = useRemember(
    users[0]?.id ?? null,
    'users:selected-user',
  )

  const visibleUsers = users.filter((user) => {
    if (!search.trim()) {
      return true
    }

    const haystack = `${user.name} ${user.role} ${user.location} ${user.focus}`
    return haystack.toLowerCase().includes(search.trim().toLowerCase())
  })

  const selectedUser =
    visibleUsers.find((user) => user.id === selectedUserId) ??
    users.find((user) => user.id === selectedUserId) ??
    visibleUsers[0] ??
    users[0] ??
    null

  const loadInsights = () => {
    router.reload({
      only: ['insights'],
      preserveScroll: true,
      preserveState: true,
    })
  }

  return (
    <>
      <Head title={title} />
      <div className="shell page-shell">
        <nav className="nav">
          <div className="brand">{appName}</div>
          <div className="nav-links">
            <Link className="button-link secondary" href="/">
              Home
            </Link>
            <Link className="button-link secondary" href="/users">
              Users
            </Link>
            <Link className="button-link secondary" href="/lab">
              Lab
            </Link>
          </div>
        </nav>

        <header className="page-header">
          <div>
            <span className="eyebrow">Remembered state + lazy reloads</span>
            <h1>{title}</h1>
            <p>{description}</p>
          </div>
          <Link className="button-link" href="/lab">
            Jump to the feature lab
          </Link>
        </header>

        <section className="stats-grid">
          {headlineStats.map((item) => (
            <article className="stat-card" key={item.label}>
              <span className="stat-label">{item.label}</span>
              <strong>{item.value}</strong>
              <p>{item.detail}</p>
            </article>
          ))}
        </section>

        <section className="panel-card">
          <div className="section-header">
            <div>
              <span className="eyebrow">Server filters</span>
              <h2>Switch the query-param team view</h2>
            </div>
            <div className="status-pill">
              Generated {serverRequest.generatedAt}
            </div>
          </div>

          <div className="filter-row">
            {teams.map((team) => (
              <Link
                className={`pill-link ${team.active ? 'active' : ''}`}
                href={team.href}
                key={team.id}
                preserveState
              >
                <span>{team.label}</span>
                <strong>{team.count}</strong>
              </Link>
            ))}
          </div>

          <div className="user-toolbar">
            <label className="search-field">
              <span className="field-label">Client-side search</span>
              <input
                onChange={(event) => setSearch(event.target.value)}
                placeholder="Filter by name, role, location, or focus"
                type="search"
                value={search}
              />
            </label>

            <button
              className="button-link secondary"
              onClick={loadInsights}
              type="button"
            >
              {insights ? 'Refresh lazy diagnostics' : 'Load lazy diagnostics'}
            </button>
          </div>
        </section>

        <section className="user-layout">
          <div className="user-list">
            {visibleUsers.map((user) => (
              <button
                className={`user-card selectable ${
                  selectedUser?.id === user.id ? 'active' : ''
                }`}
                key={user.id}
                onClick={() => setSelectedUserId(user.id)}
                type="button"
              >
                <span className="eyebrow subtle">
                  {formatTeamLabel(user.team)}
                </span>
                <h2>{user.name}</h2>
                <p className="user-role">{user.role}</p>
                <p className="user-meta">{user.location}</p>
                <p className="user-copy">{user.focus}</p>
              </button>
            ))}

            {visibleUsers.length === 0 ? (
              <article className="empty-card">
                <h2>No matches</h2>
                <p>
                  The remembered search is still active. Clear it and the roster
                  will repopulate immediately without another server trip.
                </p>
              </article>
            ) : null}
          </div>

          <aside className="stack-column">
            <article className="panel-card">
              <div className="section-header">
                <div>
                  <span className="eyebrow">Selected profile</span>
                  <h2>
                    {selectedUser?.name ?? 'No one selected'}{' '}
                    <span className="subtle-inline">
                      {formatTeamLabel(activeTeam)}
                    </span>
                  </h2>
                </div>
              </div>

              {selectedUser ? (
                <div className="detail-stack">
                  <p className="panel-copy">{selectedUser.focus}</p>
                  <dl className="meta-grid compact">
                    <div>
                      <dt>Role</dt>
                      <dd>{selectedUser.role}</dd>
                    </div>
                    <div>
                      <dt>Location</dt>
                      <dd>{selectedUser.location}</dd>
                    </div>
                    <div>
                      <dt>Availability</dt>
                      <dd>{selectedUser.availability}</dd>
                    </div>
                    <div>
                      <dt>Server team</dt>
                      <dd>{formatTeamLabel(selectedUser.team)}</dd>
                    </div>
                  </dl>

                  <div className="tag-row">
                    {selectedUser.stack.map((item) => (
                      <span className="tag" key={item}>
                        {item}
                      </span>
                    ))}
                  </div>
                </div>
              ) : (
                <p className="empty-state">
                  Pick a person from the roster to inspect their server-supplied
                  details.
                </p>
              )}
            </article>

            <article className="panel-card">
              <div className="section-header">
                <div>
                  <span className="eyebrow">Lazy prop</span>
                  <h2>Diagnostics</h2>
                </div>
              </div>

              {insights ? (
                <div className="detail-stack">
                  <dl className="meta-grid compact">
                    <div>
                      <dt>Fetched at</dt>
                      <dd>{insights.fetchedAt}</dd>
                    </div>
                    <div>
                      <dt>Active team</dt>
                      <dd>{insights.activeTeamLabel}</dd>
                    </div>
                    <div>
                      <dt>Coverage</dt>
                      <dd>{insights.coverage}</dd>
                    </div>
                  </dl>

                  <div className="tag-row">
                    {insights.teamsTouched.map((team) => (
                      <span className="tag" key={team}>
                        {team}
                      </span>
                    ))}
                  </div>

                  <ul className="check-list compact">
                    {insights.checks.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                </div>
              ) : (
                <p className="empty-state">
                  Diagnostics stay out of the initial response. Load them with a
                  targeted partial reload and verify the roster selection stays
                  intact.
                </p>
              )}
            </article>
          </aside>
        </section>
      </div>
    </>
  )
}

function formatTeamLabel(team) {
  if (team === 'platform') return 'Platform'
  if (team === 'operations') return 'Operations'
  if (team === 'quality') return 'Quality'
  if (team === 'experience') return 'Experience'
  return 'All teams'
}
