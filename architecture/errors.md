# Errors

Read this when code can fail: a repository or service throws, a controller
captures the error, or a view shows it. Index:
[architecture.md](../architecture.md).

- A failure is an exception. Repositories and services throw. NEVER return
  `false`, `null`, or an empty value to hide a failure.
- A controller captures errors with `AsyncValue.guard` and exposes
  `AsyncError`, or returns `false` to the view.
- A view shows an ARB message that names the failed action ("Could not save
  entry."). NEVER show `error.toString()` or a raw SDK message.
- Tell error types apart only when the user can act on the difference (wrong
  password, no network). Then the repository throws a subclass of
  `sealed class <Feature>Exception` from `domain/<feature>_exceptions.dart`,
  and the view maps it to ARB text with a `switch`.
- NEVER catch an exception without rethrowing, logging, or showing it.

## Enforced By

No test or lint checks these rules. They are checked only in review.
