/speckit.implement

Implement the approved tasks for the `PaginationProvider` maintenance feature.

Follow the generated task order strictly.

## Implementation Rules

- Do not rewrite unrelated package areas.
- Preserve public API compatibility unless the approved plan says otherwise.
- Add or update tests before or alongside implementation.
- Keep the cubit as the owner of pagination state.
- Keep providers as data-source adapters.
- Implement accumulated stream pagination safely.
- Cancel streams on refresh, reload, filter/search reset, page eviction, and dispose.
- Prevent stale old-scope emissions.
- Do not silently deduplicate items.
- Preserve custom `PaginationRequest` subclasses.
- Update README and CHANGELOG.

## Validation Required

After implementation, run or prepare commands for:

- `flutter analyze`
- `dart analyze`
- `flutter test` or `dart test`

Report:

- Files changed.
- Tests added.
- Behavior changed.
- Backward compatibility status.
- Any known limitations.
