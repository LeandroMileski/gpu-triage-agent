const lanes = [
  {
    title: 'System node',
    subtitle: 'Where the problems live',
    body: 'Six broken test pods sit next to the agent. It can only read that lab — not restart anything, not touch production.',
    detail: 't3.medium · CoreDNS · Argo CD · Karpenter',
  },
  {
    title: 'Spot GPU node',
    subtitle: 'Where the model wakes up',
    body: 'A self-hosted open-weight model answers through an OpenAI-compatible API. The GPU node starts at zero and only appears when Git says so.',
    detail: 'Karpenter · g6 / g5 Spot · Qwen2.5-7B on vLLM',
  },
  {
    title: 'Monitoring node',
    subtitle: 'Where the bill stays visible',
    body: 'Prometheus and Grafana track GPU dollars, tokens, and restarts on a separate tainted node so broken pods cannot crowd out the dashboards.',
    detail: 't3.medium · Prometheus · Grafana',
  },
] as const

const guardrails = [
  {
    title: 'Read-only by design',
    body: 'The agent can inspect pods, logs, and events in one namespace. It cannot change the cluster.',
  },
  {
    title: 'Secrets never leave the redactor',
    body: 'API keys, tokens, and credentials are stripped before any log line reaches the model.',
  },
  {
    title: 'One Git flip turns it off',
    body: 'Remove the RoleBinding in Git and Argo CD takes the agent’s access away.',
  },
] as const

const costRows = [
  {
    label: 'Self-hosted Spot GPU',
    value: 'gpu_usd',
    body: 'Wall-clock time of the diagnosis × the Spot GPU hourly rate. You pay for the node only while it is up.',
  },
  {
    label: 'If this were a cloud API',
    value: 'api_usd',
    body: 'Same prompt and token count, priced at a commercial API rate. Same interface — different bill.',
  },
] as const

export default function App() {
  return (
    <div className="min-h-screen overflow-x-hidden bg-[#f4f7fb] text-ink">
      <header className="relative isolate min-h-[100svh] overflow-hidden text-white">
        <img
          src="/architecture.png"
          alt=""
          aria-hidden
          className="absolute inset-0 h-full w-full scale-105 object-cover object-center animate-drift"
        />
        <div
          aria-hidden
          className="absolute inset-0 bg-[linear-gradient(90deg,rgba(11,18,32,0.92)_0%,rgba(11,18,32,0.78)_42%,rgba(11,18,32,0.35)_70%,rgba(11,18,32,0.2)_100%),linear-gradient(180deg,rgba(11,18,32,0.55)_0%,rgba(11,18,32,0.15)_40%,rgba(11,18,32,0.75)_100%)]"
        />

        <nav className="relative z-10 mx-auto flex w-full max-w-6xl items-center justify-between px-6 py-6 md:px-8">
          <p className="font-display text-lg font-semibold tracking-tight md:text-xl">
            Kubernetes Triage Agent
          </p>
          <a
            href="#how-it-works"
            className="rounded-full border border-white/25 bg-white/10 px-4 py-2 text-sm font-semibold backdrop-blur transition hover:bg-white/20"
          >
            How it works
          </a>
        </nav>

        <div className="relative z-10 mx-auto flex min-h-[calc(100svh-5.5rem)] w-full max-w-6xl items-end px-6 pb-16 pt-10 md:items-center md:px-8 md:pb-24">
          <div className="max-w-xl">
            <p className="animate-rise font-display text-4xl font-semibold leading-[1.05] tracking-tight sm:text-5xl md:text-[3.5rem]">
              Kubernetes Triage Agent
            </p>
            <div className="animate-draw mt-4 h-1 w-24 rounded-full bg-signal-bright" />
            <h1 className="animate-rise-delay-1 mt-6 text-2xl font-semibold leading-snug tracking-tight text-slate-100 sm:text-3xl">
              Diagnose broken cloud workloads without the 2&nbsp;a.m. log hunt.
            </h1>
            <p className="animate-rise-delay-2 mt-5 max-w-md text-base leading-relaxed text-slate-300 sm:text-lg">
              A self-hosted model on a Spot GPU inspects deliberately broken pods,
              stays read-only, and prints what that call cost — next to what a
              commercial API would have charged.
            </p>
            <div className="animate-rise-delay-2 mt-8 flex flex-wrap gap-3">
              <a
                href="#architecture"
                className="rounded-full bg-signal-bright px-5 py-3 text-sm font-semibold text-ink transition hover:bg-teal-300"
              >
                See the architecture
              </a>
              <a
                href="#cost"
                className="rounded-full border border-white/30 bg-white/10 px-5 py-3 text-sm font-semibold text-white backdrop-blur transition hover:bg-white/20"
              >
                Compare the cost story
              </a>
            </div>
          </div>
        </div>
      </header>

      <main>
        <section id="how-it-works" className="mx-auto max-w-6xl px-6 py-20 md:px-8 md:py-28">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-signal">
            Three lanes
          </p>
          <h2 className="mt-3 max-w-2xl font-display text-3xl font-semibold tracking-tight text-ink md:text-4xl">
            One story, left to right: problem, brain, bill.
          </h2>
          <p className="mt-4 max-w-2xl text-lg leading-relaxed text-steel">
            You do not need to know Kubernetes to follow it. Failures appear on
            the left. The agent asks a model in the middle. Cost and health stay
            visible on the right.
          </p>

          <div className="mt-12 grid gap-10 md:grid-cols-3">
            {lanes.map((lane, index) => (
              <article key={lane.title} className="border-t border-slate-300 pt-6">
                <p className="font-mono text-xs font-semibold tracking-wide text-signal">
                  0{index + 1}
                </p>
                <h3 className="mt-3 font-display text-2xl font-semibold text-ink">
                  {lane.title}
                </h3>
                <p className="mt-1 text-sm font-semibold text-ink-soft">
                  {lane.subtitle}
                </p>
                <p className="mt-4 text-base leading-relaxed text-steel">
                  {lane.body}
                </p>
                <p className="mt-5 font-mono text-xs leading-relaxed text-slate-500">
                  {lane.detail}
                </p>
              </article>
            ))}
          </div>
        </section>

        <section className="border-y border-slate-200 bg-white">
          <div className="mx-auto grid max-w-6xl gap-12 px-6 py-20 md:grid-cols-2 md:px-8 md:py-28">
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.18em] text-signal">
                Trust first
              </p>
              <h2 className="mt-3 font-display text-3xl font-semibold tracking-tight text-ink md:text-4xl">
                Version one cannot touch the cluster.
              </h2>
              <p className="mt-4 text-lg leading-relaxed text-steel">
                Before an AI agent earns write access, it has to prove it can
                diagnose safely. This build is deliberately narrow so LinkedIn
                peers — and skeptical engineers — can see the guardrails.
              </p>
            </div>
            <ul className="space-y-8">
              {guardrails.map((item) => (
                <li key={item.title} className="border-l-2 border-signal pl-5">
                  <h3 className="text-lg font-semibold text-ink">{item.title}</h3>
                  <p className="mt-2 leading-relaxed text-steel">{item.body}</p>
                </li>
              ))}
            </ul>
          </div>
        </section>

        <section id="cost" className="mx-auto max-w-6xl px-6 py-20 md:px-8 md:py-28">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-signal">
            Cost, side by side
          </p>
          <h2 className="mt-3 max-w-2xl font-display text-3xl font-semibold tracking-tight text-ink md:text-4xl">
            Same OpenAI-shaped API. Two receipts.
          </h2>
          <p className="mt-4 max-w-2xl text-lg leading-relaxed text-steel">
            The model speaks the familiar chat-completions interface, so token
            counts match what a commercial API would report. Every diagnosis
            prints both numbers — what the Spot GPU actually cost, and what that
            same call would have cost if you paid an external API.
          </p>

          <div className="mt-12 grid gap-6 md:grid-cols-2">
            {costRows.map((row) => (
              <article
                key={row.value}
                className="rounded-3xl bg-ink px-7 py-8 text-white shadow-[0_24px_60px_-36px_rgba(15,23,42,0.7)]"
              >
                <p className="text-sm font-semibold uppercase tracking-[0.16em] text-teal-300">
                  {row.label}
                </p>
                <p className="mt-4 font-mono text-3xl font-semibold text-white">
                  {row.value}
                </p>
                <p className="mt-4 text-base leading-relaxed text-slate-300">
                  {row.body}
                </p>
              </article>
            ))}
          </div>
          <p className="mt-8 max-w-3xl text-sm leading-relaxed text-steel">
            The GPU floor stays near zero until a Git commit flips{' '}
            <code className="rounded bg-slate-200/80 px-1.5 py-0.5 font-mono text-[0.85em] text-ink">
              replicas: 1
            </code>
            . Karpenter brings the Spot node up, the diagnosis runs, then you
            scale it back to zero when the take is done.
          </p>
        </section>

        <section
          id="architecture"
          className="border-t border-slate-200 bg-[linear-gradient(180deg,#eef3f9_0%,#f4f7fb_100%)]"
        >
          <div className="mx-auto max-w-6xl px-6 py-20 md:px-8 md:py-28">
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-signal">
              Architecture
            </p>
            <h2 className="mt-3 max-w-2xl font-display text-3xl font-semibold tracking-tight text-ink md:text-4xl">
              Git builds the cluster. Argo CD keeps it honest.
            </h2>
            <p className="mt-4 max-w-2xl text-lg leading-relaxed text-steel">
              Terraform creates the EKS layout. Argo CD syncs the apps back onto
              the cluster. No laptop in the critical path — everything that
              matters for the demo lives on AWS.
            </p>
            <img
              src="/architecture.png"
              alt="Full architecture of the Kubernetes Triage Agent on AWS EKS"
              className="mt-10 w-full rounded-2xl border border-slate-200 bg-white shadow-[0_30px_80px_-48px_rgba(15,23,42,0.55)]"
            />
          </div>
        </section>

        <section className="mx-auto max-w-6xl px-6 py-20 md:px-8 md:py-28">
          <div className="max-w-3xl">
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-signal">
              Building in public
            </p>
            <h2 className="mt-3 font-display text-3xl font-semibold tracking-tight text-ink md:text-4xl">
              Diagnose first. Earn write access later.
            </h2>
            <p className="mt-4 text-lg leading-relaxed text-steel">
              Next stages can open tickets and hand work to specialized agents —
              each with only the permissions its risk level needs. Version one
              stays a triage assistant so the story stays clear: safe diagnosis,
              visible cost, GPU that scales to zero.
            </p>
            <p className="mt-8 text-base font-medium text-ink">
              If you run Kubernetes, watch cloud bills, or build practical AI
              agents — what guardrail would you require before letting an agent
              touch your cluster?
            </p>
          </div>
        </section>
      </main>

      <footer className="border-t border-slate-200 bg-white">
        <div className="mx-auto flex max-w-6xl flex-col gap-3 px-6 py-8 text-sm text-steel md:flex-row md:items-center md:justify-between md:px-8">
          <p className="font-display text-base font-semibold text-ink">
            Kubernetes Triage Agent
          </p>
          <p>Lean EKS demo · Spot GPU · read-only triage · cost on every call</p>
        </div>
      </footer>
    </div>
  )
}
