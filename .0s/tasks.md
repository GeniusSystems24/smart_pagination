/speckit.tasks

Generate an actionable task list for implementing the `smart_pagination` stability feature that prevents infinite duplicate page fetching during rapid repeated scrolling.

The task list must be test-first and incremental.

Required phases:

1. Audit current load-more trigger path.
2. Add failing tests that reproduce rapid-scroll duplicate fetches.
3. Add tests for duplicate request keys.
4. Add tests for end-of-list stop behavior.
5. Add tests for stale responses.
6. Implement cubit-level in-flight load-more guard.
7. Implement request key tracking.
8. Implement stale generation guard if missing.
9. Fix end-of-list transitions.
10. Fix stream provider duplicate page stream registration.
11. Add widget-level scroll trigger protection only if needed.
12. Update README and CHANGELOG.
13. Run analysis and tests.

Each task must include:

- Task ID.
- Title.
- Files likely affected.
- Description.
- Acceptance criteria.
- Dependencies.
- Whether it can be done in parallel.

Do not implement code yet.
Generate tasks only.
