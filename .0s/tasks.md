/speckit.tasks

Generate an actionable task list for implementing scroll anchor preservation after appending new paginated items in `smart_pagination`.

The task list must be test-first and incremental.

Required phases:

1. Audit current scroll trigger and append behavior.
2. Add failing widget test reproducing repeated load-more after append.
3. Add test for anchor capture before load-more.
4. Add test for anchor preservation after append.
5. Add test for suppressing load-more until next user scroll.
6. Add internal anchor state model.
7. Implement anchor capture before load-more.
8. Implement post-append anchor restoration.
9. Implement trigger re-entry suppression.
10. Integrate with request guard and end-of-list guard.
11. Add support/fallback for supported view types.
12. Add reverse-list tests if reverse mode is supported.
13. Add variable-height item tests if possible.
14. Update README and CHANGELOG.
15. Run analysis and tests.

Each task must include:

- Task ID.
- Title.
- Files likely affected.
- Description.
- Acceptance criteria.
- Dependencies.
- Whether it can run in parallel.

Do not implement code yet.
Generate tasks only.