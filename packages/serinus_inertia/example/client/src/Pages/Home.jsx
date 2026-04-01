import { Head, Link } from '@inertiajs/react'

export default function Home({
  title,
  message,
  overviewStats,
  routeCards,
  protocols,
  launchChecklist,
  appName,
}) {
  return (
    <>
      <Head title={title} />
      <div className="shell home-shell">
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

        <section className="hero hero-home">
          <div className="hero-grid">
            <div className="hero-copy">
              <span className="eyebrow">Serinus adapter demo</span>
              <h1>{title}</h1>
              <p className="lede">{message}</p>
              <div className="actions">
                <Link className="button-link" href="/lab">
                  Open the feature lab
                </Link>
                <Link className="button-link secondary" href="/users">
                  Explore the users route
                </Link>
              </div>
            </div>

            <aside className="hero-panel">
              <span className="eyebrow subtle">Quick validation path</span>
              <ol className="ordered-checklist">
                {launchChecklist.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ol>
            </aside>
          </div>
        </section>

        <section className="stats-grid">
          {overviewStats.map((item) => (
            <article className="stat-card" key={item.label}>
              <span className="stat-label">{item.label}</span>
              <strong>{item.value}</strong>
              <p>{item.detail}</p>
            </article>
          ))}
        </section>

        <section className="section-block">
          <div className="section-header">
            <div>
              <span className="eyebrow">Routes worth testing</span>
              <h2>Each page stresses a different part of the adapter</h2>
            </div>
          </div>

          <div className="route-grid">
            {routeCards.map((route) => (
              <article className="route-card" key={route.id}>
                <span className="eyebrow subtle">{route.eyebrow}</span>
                <h3>{route.title}</h3>
                <p>{route.summary}</p>
                <ul className="check-list compact">
                  {route.checks.map((check) => (
                    <li key={check}>{check}</li>
                  ))}
                </ul>
                <Link className="button-link tertiary" href={route.href}>
                  Open route
                </Link>
              </article>
            ))}
          </div>
        </section>

        <section className="section-block">
          <div className="section-header">
            <div>
              <span className="eyebrow">Protocol surface</span>
              <h2>What this demo is designed to shake out</h2>
            </div>
          </div>

          <div className="protocol-grid">
            {protocols.map((protocol) => (
              <article className="protocol-card" key={protocol.title}>
                <h3>{protocol.title}</h3>
                <p>{protocol.detail}</p>
              </article>
            ))}
          </div>
        </section>
      </div>
    </>
  )
}
