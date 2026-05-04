/speckit.clarify

Clarify the requirements for maintaining the `PaginationProvider` system in `smart_pagination`.

Important language rule:
All clarification questions must be bilingual: English first, then Arabic. Use the same numbering and preserve the same technical meaning in both languages.

Required format:

### Question N
**English:** ...
**Arabic:** ...

Focus only on questions that affect implementation decisions.

Clarify these topics:

1. Stream accumulation behavior.
2. Pagination scope boundaries.
3. Stream key strategy.
4. Stream aggregation strategy.
5. Duplicate handling strategy.
6. Stream error behavior.
7. Stream completion behavior.
8. Memory limits and max active streams.
9. Page eviction behavior.
10. Refresh and reload reset behavior.
11. Filter and search query reset behavior.
12. Cubit disposal behavior.
13. Backward compatibility.
14. Documentation requirements.
15. Test coverage requirements.

Specific clarification context:

`StreamPaginationProvider` must support accumulated page streams. Loading a new stream within the same pagination scope must add it to previous active streams, not replace them. Old streams are cancelled only when the scope resets, such as refresh, reload, filter/search change, provider change, page eviction, or cubit dispose.

Do not ask generic questions.
Ask only questions that help decide the design and implementation.