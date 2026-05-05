/speckit.clarify

Clarify the new scroll stability feature for preserving the user's scroll anchor after appending new paginated items in `smart_pagination`.

Important language rule:
All clarification questions must be bilingual: English first, then Arabic. Use the same numbering and preserve the same technical meaning in both languages.

Required format:

### Question N
**English:** ...
**Arabic:** ...

Focus only on questions that affect implementation decisions.

Clarify these topics:

1. Which visible item should be used as the scroll anchor.
2. Whether the anchor should be key-based, index-based, or offset-based.
3. Whether users must provide `itemKeyBuilder` for accurate preservation.
4. Whether the feature should be enabled by default.
5. How to handle variable-height list items.
6. How to handle GridView and StaggeredGridView.
7. How to handle reverse lists.
8. How to handle externally supplied `ScrollController`.
9. Whether anchor preservation should happen for append only or also insert/remove/update.
10. How to prevent load-more trigger re-entry after append.
11. Whether a post-frame correction is allowed.
12. Whether temporary trigger suppression is needed after append.
13. How to test the behavior with widget tests.

Do not ask generic questions.
Ask only questions that help decide the design and implementation.
