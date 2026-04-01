import {
  Deferred,
  Head,
  InfiniteScroll,
  Link,
  WhenVisible,
  router,
  usePage,
  usePoll,
  useRemember,
} from '@inertiajs/react'

export default function Lab({
  title,
  description,
  liveStats,
  historyMode,
  releaseTimeline,
  deepDive,
  diagnostics,
  highlights,
  activity,
  appName,
}) {
  const page = usePage()
  const [draftNote, setDraftNote] = useRemember(
    'Ship SSR smoke tests before tagging the next release candidate.',
    'lab:draft-note',
  )

  usePoll(4000, {
    only: ['liveStats'],
    preserveScroll: true,
    preserveState: true,
  })

  const flashNotice = page.flash?.notice ?? null
  const activeScrollMeta = page.scrollProps?.activity ?? null
  const nextBatch = Math.min(
    (highlights?.loadedBatch ?? 1) + 1,
    highlights?.totalBatches ?? 1,
  )
  const mergePaths = page.mergeProps ?? []
  const deferredGroups = Object.entries(page.deferredProps ?? {})

  const loadMoreHighlights = () => {
    router.visit(
      buildLabHref(page.url, {
        highlights_batch: String(nextBatch),
      }),
      {
        only: ['highlights'],
        preserveScroll: true,
        preserveState: true,
        replace: true,
      },
    )
  }

  const resetHighlights = () => {
    router.visit(
      buildLabHref(page.url, {
        highlights_batch: '1',
      }),
      {
        only: ['highlights'],
        preserveScroll: true,
        preserveState: true,
        replace: true,
        reset: ['highlights'],
      },
    )
  }

  const reloadDiagnostics = () => {
    router.reload({
      only: ['diagnostics'],
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

        <section className="hero lab-hero">
          <div className="hero-grid">
            <div className="hero-copy">
              <span className="eyebrow">Feature lab</span>
              <h1>{title}</h1>
              <p className="lede">{description}</p>
              <div className="actions">
                <Link
                  className="button-link secondary"
                  href={buildLabHref(page.url, { history: 'encrypt' })}
                  preserveState
                  replace
                >
                  Encrypt history
                </Link>
                <Link
                  className="button-link secondary"
                  href={buildLabHref(page.url, { history: 'clear' })}
                  preserveState
                  replace
                >
                  Clear history
                </Link>
                <Link
                  className="button-link secondary"
                  href={buildLabHref(page.url, {
                    flash: 'Version hash bumped for QA rehearsal.',
                  })}
                  preserveState
                  replace
                >
                  Send flash notice
                </Link>
              </div>
            </div>

            <aside className="hero-panel">
              <span className="eyebrow subtle">Current page contract</span>
              <dl className="meta-grid">
                <div>
                  <dt>URL</dt>
                  <dd>{page.url}</dd>
                </div>
                <div>
                  <dt>Version</dt>
                  <dd>{page.version ?? 'unset'}</dd>
                </div>
                <div>
                  <dt>History</dt>
                  <dd>
                    {page.encryptHistory
                      ? 'encrypted'
                      : page.clearHistory
                        ? 'clear-on-visit'
                        : historyMode}
                  </dd>
                </div>
                <div>
                  <dt>Deferred groups</dt>
                  <dd>{deferredGroups.length}</dd>
                </div>
              </dl>
            </aside>
          </div>
        </section>

        {flashNotice ? (
          <section className="flash-banner">
            <span className="eyebrow subtle">Flash payload</span>
            <strong>{flashNotice}</strong>
          </section>
        ) : null}

        <section className="metric-band">
          <article className="metric-card">
            <span>Polled at</span>
            <strong>{liveStats.polledAt}</strong>
            <p>Refreshed with `usePoll()` every four seconds.</p>
          </article>
          <article className="metric-card">
            <span>Requests / minute</span>
            <strong>{liveStats.requestsPerMinute}</strong>
            <p>Live server data arriving through a targeted partial reload.</p>
          </article>
          <article className="metric-card">
            <span>Renderer state</span>
            <strong>{liveStats.renderer}</strong>
            <p>Useful when comparing managed SSR against an external runtime.</p>
          </article>
          <article className="metric-card">
            <span>Queue depth</span>
            <strong>{liveStats.queueDepth}</strong>
            <p>Status is currently {liveStats.status}.</p>
          </article>
        </section>

        <section className="lab-grid">
          <div className="stack-column">
            <article className="panel-card">
              <div className="section-header">
                <div>
                  <span className="eyebrow">Deferred prop</span>
                  <h2>Release timeline</h2>
                </div>
              </div>

              <Deferred data="releaseTimeline" fallback={<SkeletonLines lines={3} />}>
                {({ reloading }) => (
                  <div className="timeline-list">
                    {releaseTimeline.map((step) => (
                      <article className="timeline-card" key={step.title}>
                        <div className="timeline-topline">
                          <h3>{step.title}</h3>
                          <span>{reloading ? 'Refreshing' : 'Resolved'}</span>
                        </div>
                        <p>{step.summary}</p>
                        <ul className="check-list compact">
                          {step.checks.map((check) => (
                            <li key={check}>{check}</li>
                          ))}
                        </ul>
                      </article>
                    ))}
                  </div>
                )}
              </Deferred>
            </article>

            <article className="panel-card">
              <div className="section-header">
                <div>
                  <span className="eyebrow">Merge prop</span>
                  <h2>Incremental highlights</h2>
                </div>
                <div className="button-row">
                  <button
                    className="button-link secondary"
                    disabled={highlights.remainingBatches === 0}
                    onClick={loadMoreHighlights}
                    type="button"
                  >
                    {highlights.remainingBatches > 0
                      ? 'Load next batch'
                      : 'All batches loaded'}
                  </button>
                  <button
                    className="button-link tertiary"
                    onClick={resetHighlights}
                    type="button"
                  >
                    Reset merge state
                  </button>
                </div>
              </div>

              <div className="status-strip">
                <span>Loaded batch {highlights.loadedBatch}</span>
                <span>{highlights.remainingBatches} batches remaining</span>
                <span>{mergePaths.join(', ') || 'No merge paths advertised'}</span>
              </div>

              <div className="highlight-grid">
                {highlights.items.map((item) => (
                  <article className="highlight-card" key={item.id}>
                    <span className="eyebrow subtle">{item.owner}</span>
                    <h3>{item.title}</h3>
                    <p>{item.note}</p>
                  </article>
                ))}
              </div>
            </article>

            <article className="panel-card">
              <div className="section-header">
                <div>
                  <span className="eyebrow">Scroll prop</span>
                  <h2>Infinite activity feed</h2>
                </div>
              </div>

              <InfiniteScroll
                as="section"
                buffer={260}
                className="activity-shell"
                data="activity"
                loading={({ loadingNext }) =>
                  loadingNext ? (
                    <div className="activity-loading">Loading the next activity window…</div>
                  ) : null
                }
                next={({ fetch, hasMore, loadingNext }) =>
                  hasMore ? (
                    <button
                      className="button-link tertiary activity-button"
                      disabled={loadingNext}
                      onClick={fetch}
                      type="button"
                    >
                      {loadingNext ? 'Loading…' : 'Force next page'}
                    </button>
                  ) : (
                    <div className="activity-loading done">Activity feed complete.</div>
                  )
                }
              >
                {({ loadingNext }) => (
                  <>
                    <div className="status-strip">
                      <span>
                        Page {activity.currentPage} of {activity.totalPages}
                      </span>
                      <span>
                        Query key: {activeScrollMeta?.pageName ?? 'activity_page'}
                      </span>
                      <span>
                        Reset flag: {activeScrollMeta?.reset ? 'yes' : 'no'}
                      </span>
                    </div>

                    <div className="activity-list">
                      {activity.data.map((entry) => (
                        <article className="activity-card" key={entry.id}>
                          <div className="activity-meta">
                            <span>{entry.lane}</span>
                            <span>{entry.minute}</span>
                          </div>
                          <h3>{entry.actor}</h3>
                          <p>{entry.action}</p>
                          <strong>{entry.severity}</strong>
                        </article>
                      ))}
                    </div>

                    {loadingNext ? (
                      <div className="activity-loading">Buffering the next page…</div>
                    ) : null}
                  </>
                )}
              </InfiniteScroll>
            </article>
          </div>

          <aside className="stack-column">
            <article className="panel-card">
              <div className="section-header">
                <div>
                  <span className="eyebrow">Optional prop</span>
                  <h2>Deep dive on scroll</h2>
                </div>
              </div>

              <WhenVisible
                as="div"
                buffer={180}
                data="deepDive"
                fallback={<SkeletonLines lines={4} />}
              >
                {deepDive ? (
                  <div className="deep-dive">
                    <p className="panel-copy">{deepDive.headline}</p>
                    {deepDive.sections.map((section) => (
                      <article className="subpanel-card" key={section.title}>
                        <h3>{section.title}</h3>
                        <p>{section.detail}</p>
                      </article>
                    ))}
                    <ul className="check-list compact">
                      {deepDive.matrix.map((item) => (
                        <li key={item.name}>
                          <strong>{item.name}:</strong> {item.expectation}
                        </li>
                      ))}
                    </ul>
                  </div>
                ) : null}
              </WhenVisible>
            </article>

            <article className="panel-card">
              <div className="section-header">
                <div>
                  <span className="eyebrow">Lazy prop</span>
                  <h2>Diagnostics on demand</h2>
                </div>
                <button
                  className="button-link secondary"
                  onClick={reloadDiagnostics}
                  type="button"
                >
                  {diagnostics ? 'Refresh diagnostics' : 'Load diagnostics'}
                </button>
              </div>

              {diagnostics ? (
                <div className="diagnostic-block">
                  <div className="meta-grid compact">
                    <div>
                      <dt>Requested</dt>
                      <dd>{diagnostics.requestedAt}</dd>
                    </div>
                    <div>
                      <dt>History mode</dt>
                      <dd>{diagnostics.historyMode}</dd>
                    </div>
                    <div>
                      <dt>Highlight batch</dt>
                      <dd>{diagnostics.highlightBatch}</dd>
                    </div>
                    <div>
                      <dt>Activity page</dt>
                      <dd>{diagnostics.activityPage}</dd>
                    </div>
                  </div>
                  <ul className="check-list compact">
                    {diagnostics.qaChecklist.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                </div>
              ) : (
                <p className="empty-state">
                  Diagnostics are intentionally absent from the first response.
                  Trigger a targeted reload to fetch them.
                </p>
              )}
            </article>

            <article className="panel-card">
              <div className="section-header">
                <div>
                  <span className="eyebrow">Remembered local state</span>
                  <h2>Draft a QA note</h2>
                </div>
              </div>

              <label className="field-label" htmlFor="draft-note">
                Notes are restored on history navigation thanks to
                `useRemember()`.
              </label>
              <textarea
                id="draft-note"
                className="note-input"
                onChange={(event) => setDraftNote(event.target.value)}
                rows="6"
                value={draftNote}
              />
              <div className="button-row">
                <Link className="button-link secondary" href="/users" preserveState>
                  Leave for the users page
                </Link>
                <Link
                  as="button"
                  className="button-link"
                  href="/lab/high-five"
                  method="post"
                  preserveScroll
                  type="button"
                >
                  Trigger post + redirect
                </Link>
              </div>
            </article>

            <article className="panel-card">
              <div className="section-header">
                <div>
                  <span className="eyebrow">Page metadata</span>
                  <h2>Live protocol inspector</h2>
                </div>
              </div>

              <pre className="inspector-code">
                {JSON.stringify(
                  {
                    url: page.url,
                    version: page.version,
                    encryptHistory: page.encryptHistory ?? false,
                    clearHistory: page.clearHistory ?? false,
                    mergeProps: page.mergeProps ?? [],
                    scrollProps: page.scrollProps ?? {},
                    deferredProps: page.deferredProps ?? {},
                    flash: page.flash ?? {},
                  },
                  null,
                  2,
                )}
              </pre>
            </article>
          </aside>
        </section>
      </div>
    </>
  )
}

function SkeletonLines({ lines }) {
  return (
    <div className="skeleton-stack" aria-hidden="true">
      {Array.from({ length: lines }, (_, index) => (
        <span className="skeleton-line" key={index} />
      ))}
    </div>
  )
}

function buildLabHref(currentUrl, updates) {
  const nextUrl = new URL(currentUrl, 'http://localhost')

  Object.entries(updates).forEach(([key, value]) => {
    if (value == null || value === '') {
      nextUrl.searchParams.delete(key)
      return
    }

    nextUrl.searchParams.set(key, value)
  })

  return `${nextUrl.pathname}${nextUrl.search}`
}
