/speckit.clarify

Clarify the new stability feature for preventing infinite duplicate page fetching during rapid repeated scrolling in `smart_pagination`.

Important language rule:
All clarification questions must be bilingual: English first, then Arabic. Use the same numbering and preserve the same technical meaning in both languages.

Required format:

### Question N

**English:** ...
**Arabic:** ...

Focus only on questions that affect implementation decisions.

Clarify these topics:

1. Whether pagination is page-number based, cursor-based, or both.
2. How the package should identify duplicate load-more requests.
3. Whether the same page can be retried after failure.
4. Whether fast scroll events should be throttled, debounced, or guarded by state only.
5. Whether `isFetching`, `isLoadingMore`, and `hasReachedEnd` are sufficient guards.
6. How empty pages should be handled.
7. How short pages should be handled.
8. How cursor metadata should define end-of-list.
9. How stream-based providers should stop loading more page streams.
10. How refresh/reload/search/filter resets should clear the guard state.
11. Whether duplicate item handling should be part of this feature or handled separately.
12. What tests are required to reproduce the bug.

Do not ask generic questions.
Ask only questions that help decide the design and implementation.
