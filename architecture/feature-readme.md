# Feature README

Read this when you add a feature, or a change moves ownership or the public UI
of one. Index: [architecture.md](../architecture.md).

Each feature has `lib/features/<feature>/README.md` with **Purpose** (one or
two sentences), **Owns**, **Does Not Own**, **Public UI** (widgets and flows
that later features may use; omit the section if there are none), and
optional **Rules** (domain rules that the code does not make obvious).

Do not list providers, files, tests, or dependencies. Product behavior belongs
in `features.md`. Update the README in the same change when ownership or the
public UI changes.

## Enforced By

No test or lint checks these rules. They are checked only in review.
