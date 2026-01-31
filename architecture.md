# Smart Pagination - Architecture Documentation

## 1. Architecture Diagram

```mermaid
graph TB
    subgraph Presentation["Presentation Layer"]
        SP["SmartPagination&lt;T&gt;"]
        PAV["PaginateApiView&lt;T&gt;"]
        SSD["SmartSearchDropdown&lt;T,K&gt;"]
        SSMD["SmartSearchMultiDropdown&lt;T,K&gt;"]
        SSO["SmartSearchOverlay&lt;T,K&gt;"]
        SSB["SmartSearchBox&lt;T,K&gt;"]

        SP -->|"builds"| PAV

        SSD -->|"contains"| SSO
        SSMD -->|"contains"| SSO
        SSO -->|"contains"| SSB
    end

    subgraph StateManagement["State Management Layer (BLoC)"]
        SPC["SmartPaginationCubit&lt;T&gt;"]
        SPS_I["SmartPaginationInitial"]
        SPS_L["SmartPaginationLoaded"]
        SPS_E["SmartPaginationError"]

        SSC["SmartSearchController&lt;T,K&gt;"]
        SSMC["SmartSearchMultiController&lt;T,K&gt;"]

        SPC -->|"emits"| SPS_I
        SPC -->|"emits"| SPS_L
        SPC -->|"emits"| SPS_E
    end

    subgraph Controller["Controller Layer"]
        CTRL["SmartPaginationController&lt;T&gt;"]
        LOC["ListObserverController"]
        GOC["GridObserverController"]

        CTRL -->|"delegates scroll to"| SPC
        PAV -->|"creates & attaches"| LOC
        PAV -->|"creates & attaches"| GOC
        LOC -->|"attached to"| SPC
        GOC -->|"attached to"| SPC
    end

    subgraph Data["Data Layer"]
        PP["PaginationProvider&lt;T&gt;"]
        FPP["FuturePaginationProvider"]
        SPP["StreamPaginationProvider"]
        MPP["MergedStreamPaginationProvider"]
        PR["PaginationRequest"]
        PM["PaginationMeta"]
        RC["RetryConfig"]
        RH["RetryHandler"]

        PP --- FPP
        PP --- SPP
        PP --- MPP
    end

    subgraph Listeners["Change Listeners"]
        RL["RefreshedChangeListener"]
        FL["FilterChangeListener&lt;T&gt;"]
        OL["OrderChangeListener&lt;T&gt;"]
        SOC["SortOrderCollection&lt;T&gt;"]
    end

    subgraph ViewTypes["View Builder Types"]
        LV["ListView"]
        GV["GridView"]
        PV["PageView"]
        SGV["StaggeredGridView"]
        RLV["ReorderableListView"]
        CV["Custom View"]
    end

    SP -->|"BlocBuilder"| SPC
    PAV -->|"switch type"| ViewTypes
    SPC -->|"calls"| PP
    SPC -->|"uses"| RC
    RC -->|"creates"| RH
    PP -->|"sends"| PR
    PP -->|"returns data + "| PM
    SSC -->|"controls"| SPC
    SSMC -->|"controls"| SPC
    SSD -->|"uses"| SSC
    SSMD -->|"uses"| SSMC
    CTRL -->|"wraps"| SPC
    RL -->|"triggers refresh"| SPC
    FL -->|"triggers filter"| SPC
    OL -->|"triggers sort"| SPC
    SOC -->|"manages sorts"| SPC

    style Presentation fill:#E3F2FD,stroke:#1565C0,color:#000
    style StateManagement fill:#F3E5F5,stroke:#7B1FA2,color:#000
    style Controller fill:#E8F5E9,stroke:#2E7D32,color:#000
    style Data fill:#FFF3E0,stroke:#E65100,color:#000
    style Listeners fill:#FCE4EC,stroke:#C62828,color:#000
    style ViewTypes fill:#F1F8E9,stroke:#558B2F,color:#000
```

---

## 2. Sequence Diagrams

### 2.1 Initial Fetch & Load More

```mermaid
sequenceDiagram
    participant U as User
    participant W as SmartPagination Widget
    participant C as SmartPaginationCubit
    participant RH as RetryHandler
    participant P as PaginationProvider
    participant API as External API

    Note over W,C: Initial Fetch Flow
    W->>C: fetchPaginatedList()
    C->>C: state == Initial → refreshPaginatedList()
    C->>C: _resetToInitial() + _buildRequest(reset=true)
    C->>C: emit(SmartPaginationInitial)
    C-->>W: BlocBuilder rebuilds → Loading UI

    C->>RH: execute(fetch, retryConfig)
    RH->>P: provider(request)
    P->>API: HTTP GET /items?page=1&pageSize=20

    alt Success
        API-->>P: List<T> items
        P-->>RH: items
        RH-->>C: items
        C->>C: _pages.add(items)
        C->>C: compute PaginationMeta
        C->>C: emit(SmartPaginationLoaded)
        C-->>W: BlocBuilder rebuilds → PaginateApiView
        W-->>U: Display items list
    else Failure (with retry)
        API-->>P: Error
        P-->>RH: throw Exception
        RH->>RH: attempt < maxAttempts?
        RH->>RH: delay = min(1s * 2^attempt, 10s)
        RH->>P: retry provider(request)
        P->>API: HTTP GET /items?page=1 (retry)
        API-->>P: Error (again)
        RH-->>C: throw PaginationRetryExhaustedException
        C->>C: emit(SmartPaginationError)
        C-->>W: BlocBuilder rebuilds → Error UI
        W-->>U: Display error + retry button
    end

    Note over W,C: Load More Flow (scroll near end)
    U->>W: Scrolls near end (invisibleItemsThreshold)
    W->>C: fetchPaginatedList()
    C->>C: hasReachedEnd? → No
    C->>C: emit(Loaded.copyWith(isLoadingMore: true))
    C-->>W: Show bottom loading indicator
    C->>C: _buildRequest(reset=false, page++)

    C->>RH: execute(fetch, retryConfig)
    RH->>P: provider(request page=2)
    P->>API: HTTP GET /items?page=2

    alt Success
        API-->>P: List<T> newItems
        P-->>RH: newItems
        RH-->>C: newItems
        C->>C: _pages.add(newItems)
        C->>C: _trimCachedPages(maxPagesInMemory)
        C->>C: allItems = _pages.expand(...)
        C->>C: apply sort order
        C->>C: emit(Loaded.copyWith(isLoadingMore: false))
        C-->>W: BlocBuilder rebuilds with new items
    else Load More Failure
        API-->>P: Error
        RH-->>C: throw Exception
        C->>C: emit(Loaded.copyWith(loadMoreError: error))
        C-->>W: Show bottom error with retry
    end
```

### 2.2 Search Flow

```mermaid
sequenceDiagram
    participant U as User
    participant SB as SmartSearchBox
    participant SC as SmartSearchController
    participant C as SmartPaginationCubit
    participant P as PaginationProvider
    participant OV as SmartSearchOverlay

    U->>SB: Tap search box
    SB->>SC: showOverlay()
    SC->>SC: _isOverlayVisible = true
    SC->>SC: notifyListeners()
    SC-->>OV: Overlay appears (empty or with initial data)

    Note over SC: If fetchOnInit=true, initial data already loaded

    U->>SB: Type "flutter"
    SB->>SC: _onTextChanged("flutter")
    SC->>SC: Cancel previous debounce timer
    SC->>SC: Start debounce timer (e.g. 500ms)

    Note over SC: Debounce delay passes...

    SC->>SC: _performSearch("flutter")
    SC->>C: refreshPaginatedList(requestOverride)
    C->>C: _resetToInitial()
    C->>C: emit(SmartPaginationInitial)
    C-->>OV: Show loading state

    C->>P: provider(request with searchQuery="flutter")
    P-->>C: List<T> searchResults
    C->>C: emit(SmartPaginationLoaded(items: results))
    C-->>OV: Display search results

    U->>OV: Press Arrow Down
    OV->>SC: handleKeyEvent(ArrowDown)
    SC->>SC: moveToNextItem()
    SC->>SC: _focusedIndex++
    SC-->>OV: Highlight focused item

    U->>OV: Press Enter
    OV->>SC: handleKeyEvent(Enter)
    SC->>SC: selectFocusedItem()
    SC->>SC: selectItem(items[focusedIndex])
    SC->>SC: _selectedItem = item
    SC->>SC: _selectedKey = keyExtractor(item)
    SC->>SC: hideOverlay()
    SC->>SC: onSelected?.call(item, key)
    SC-->>OV: Overlay closes
    SC-->>SB: Display selected item
```

### 2.3 Scroll Navigation Flow

```mermaid
sequenceDiagram
    participant U as User
    participant Ctrl as SmartPaginationController
    participant C as SmartPaginationCubit
    participant OC as ListObserverController
    participant SV as ScrollView (ListView)

    Note over Ctrl,SV: Observer Attachment (on widget init)
    SV->>OC: new ListObserverController(scrollController)
    SV->>C: attachListObserverController(observerController)
    C->>C: _listObserverController = controller

    Note over U,SV: User triggers scroll
    U->>Ctrl: animateToIndex(25, alignment: 0.5)
    Ctrl->>C: animateToIndex(25, alignment: 0.5)
    C->>C: Validate: 0 <= 25 < items.length
    C->>C: Check: _listObserverController != null

    alt Observer attached
        C->>OC: animateTo(index: 25, alignment: 0.5, duration: 300ms)
        OC->>OC: Calculate target scroll offset
        OC->>OC: Apply alignment (0.5 = center in viewport)
        OC->>SV: scrollController.animateTo(offset, duration, curve)
        SV-->>U: Smooth scroll animation to item #25
        OC-->>C: Animation complete
        C-->>Ctrl: return true
    else No observer
        C->>C: log warning
        C-->>Ctrl: return false
    end

    Note over U,SV: Find & scroll by predicate
    U->>Ctrl: animateFirstWhere((item) => item.id == "abc")
    Ctrl->>C: animateFirstWhere(test)
    C->>C: index = currentItems.indexWhere(test)

    alt Item found (index = 12)
        C->>C: animateToIndex(12, ...)
        C->>OC: animateTo(index: 12, ...)
        OC->>SV: Animate scroll
        C-->>Ctrl: return true
    else Item not found
        C->>C: log: "no matching item found"
        C-->>Ctrl: return false
    end

    Note over Ctrl,SV: Observer Cleanup (on widget dispose)
    SV->>C: detachAllObserverControllers()
    C->>C: _listObserverController = null
    C->>C: _gridObserverController = null
```

---

## 3. State Diagram

### 3.1 Pagination State Machine

```mermaid
stateDiagram-v2
    [*] --> Initial: Cubit created

    state Initial {
        [*] --> WaitingForFetch
        WaitingForFetch: No data fetched yet
        WaitingForFetch: hasReachedEnd = false
    }

    state Loaded {
        [*] --> Idle
        Idle: items available
        Idle: isLoadingMore = false
        Idle: loadMoreError = null

        Idle --> LoadingMore: fetchPaginatedList()
        LoadingMore: isLoadingMore = true
        LoadingMore: Fetching next page...

        LoadingMore --> Idle: Fetch success\n(append items)
        LoadingMore --> LoadMoreError: Fetch failed

        LoadMoreError: isLoadingMore = false
        LoadMoreError: loadMoreError = Exception
        LoadMoreError --> LoadingMore: retry / fetchPaginatedList()\n[strategy=automatic]
        LoadMoreError --> Idle: clearError()

        Idle --> ReachedEnd: hasReachedEnd = true
        LoadingMore --> ReachedEnd: items.length < pageSize

        ReachedEnd: All data loaded
        ReachedEnd: No more pages

        Idle --> Idle: insertEmit() / removeEmit()\nupdateEmit() / filterPaginatedList()\nsetActiveOrder()
    }

    state Error {
        [*] --> FetchFailed
        FetchFailed: Initial load failed
        FetchFailed: error = Exception
    }

    Initial --> Loaded: fetchPaginatedList()\n→ success
    Initial --> Error: fetchPaginatedList()\n→ failure

    Error --> Initial: retryAfterError()\n[strategy=manual]
    Error --> Initial: refreshPaginatedList()
    Error --> Initial: fetchPaginatedList()\n[strategy=automatic]

    Loaded --> Initial: refreshPaginatedList()
    Loaded --> Initial: checkAndResetIfExpired()\n[dataAge expired]

    note right of Initial: Widget shows\nfirstPageLoadingBuilder
    note right of Error: Widget shows\nfirstPageErrorBuilder
    note right of Loaded: Widget shows\nPaginateApiView
```

### 3.2 Search Controller State Machine

```mermaid
stateDiagram-v2
    state OverlayState {
        [*] --> Hidden

        Hidden: Overlay not visible
        Hidden: Search box unfocused

        Hidden --> Visible: showOverlay() / onFocus\n/ ArrowDown key

        Visible: Overlay showing results
        Visible: Keyboard navigation active

        Visible --> Hidden: hideOverlay() / Escape key\n/ selectItem() / barrier tap
    }

    state SearchState {
        [*] --> Idle_Search

        Idle_Search: No active search
        Idle_Search: Text may be empty

        Idle_Search --> Debouncing: User types text

        Debouncing: Timer running
        Debouncing: Waiting for pause...

        Debouncing --> Debouncing: User types more\n(reset timer)
        Debouncing --> Searching: Timer fires\n→ _performSearch()

        Idle_Search --> Searching: skipDebounceOnEmpty\n&& text cleared

        Searching: cubit.refreshPaginatedList()
        Searching: _isSearching = true

        Searching --> Idle_Search: Results received\n_isSearching = false
    }

    state SelectionState {
        [*] --> NoSelection

        NoSelection: _selectedItem = null
        NoSelection: _selectedKey = null

        NoSelection --> PendingKey: setSelectedKey(key)\n[data not loaded yet]

        PendingKey: _pendingKey = key
        PendingKey: Listening to cubit stream...

        PendingKey --> Selected: Data loads\n→ key resolved to item

        NoSelection --> Selected: selectItem(item)\n/ selectByKey(key)

        Selected: _selectedItem = item
        Selected: _selectedKey = key

        Selected --> NoSelection: clearSelection()
        Selected --> Selected: selectItem(other)\n(replace selection)
    }

    state FocusState {
        [*] --> NoFocus

        NoFocus: _focusedIndex = -1

        NoFocus --> Focused: ArrowDown / ArrowUp\n/ moveToFirstItem()

        Focused: _focusedIndex >= 0
        Focused: Item highlighted in overlay

        Focused --> Focused: ArrowDown → next\nArrowUp → previous\nHome → first\nEnd → last

        Focused --> NoFocus: Overlay closes\n/ clearSearch()
    }
```

### 3.3 Error Retry Strategy State Machine

```mermaid
stateDiagram-v2
    [*] --> Normal: Cubit initialized

    Normal: No errors
    Normal: _lastFetchWasError = false

    Normal --> FetchAttempt: fetchPaginatedList()

    FetchAttempt: Calling provider...
    FetchAttempt: RetryHandler active

    state FetchAttempt {
        [*] --> Attempt
        Attempt --> RetryDelay: Exception thrown\n&& attempts < max
        RetryDelay: Exponential backoff\nmin(1s * 2^n, 10s)
        RetryDelay --> Attempt: Retry
        Attempt --> [*]: Success or exhausted
    }

    FetchAttempt --> Normal: Success\n→ emit Loaded

    FetchAttempt --> ErrorState: All retries exhausted\n→ emit Error or Loaded(loadMoreError)

    state ErrorState {
        [*] --> CheckStrategy

        CheckStrategy --> AutoRetry: strategy = automatic
        CheckStrategy --> ManualRetry: strategy = manual
        CheckStrategy --> NoRetry: strategy = none

        AutoRetry: Next fetchPaginatedList()\nwill auto-clear error\nand retry

        ManualRetry: Blocked until\nretryAfterError() called

        NoRetry: Blocked until\nrefreshPaginatedList() called
    }

    ErrorState --> Normal: retryAfterError()\n/ refreshPaginatedList()
    ErrorState --> FetchAttempt: fetchPaginatedList()\n[strategy=automatic]
```

### 3.4 PaginateApiView Builder Type Decision

```mermaid
stateDiagram-v2
    [*] --> CheckType: PaginateApiView.build()

    state CheckType {
        [*] --> EvalType

        EvalType --> ListView: type == listView
        EvalType --> GridView: type == gridView
        EvalType --> PageView: type == pageView
        EvalType --> StaggeredGridView: type == staggeredGridView
        EvalType --> ReorderableListView: type == reorderableListView
        EvalType --> CustomView: type == custom
    }

    state ListView {
        [*] --> LV_Observer
        LV_Observer: Wrap with ListViewObserver
        LV_Observer --> LV_Build
        LV_Build: CustomScrollView + SliverList
        LV_Build: Header / Items+Separators / Footer
    }

    state GridView {
        [*] --> GV_Observer
        GV_Observer: Wrap with GridViewObserver
        GV_Observer --> GV_Build
        GV_Build: CustomScrollView + SliverGrid
        GV_Build: Uses gridDelegate
    }

    state PageView {
        [*] --> PV_Build
        PV_Build: PageView.custom()
        PV_Build: No observer support
    }

    state StaggeredGridView {
        [*] --> SGV_Build
        SGV_Build: SingleChildScrollView
        SGV_Build: + StaggeredGrid
        SGV_Build: Manual scroll detection
    }

    state ReorderableListView {
        [*] --> RLV_Observer
        RLV_Observer: Wrap with ListViewObserver
        RLV_Observer --> RLV_Build
        RLV_Build: ReorderableListView.builder()
        RLV_Build: KeyedSubtree + drag proxy
    }

    state CustomView {
        [*] --> CV_Build
        CV_Build: customViewBuilder()
        CV_Build: Full user control
    }

    state BottomWidget {
        [*] --> BW_Check
        BW_Check --> BW_End: hasReachedEnd\n→ loadMoreNoMoreItemsBuilder
        BW_Check --> BW_Loading: isLoadingMore\n→ loadMoreLoadingBuilder
        BW_Check --> BW_Error: loadMoreError != null\n→ loadMoreErrorBuilder
        BW_Check --> BW_Default: else → bottomLoader
    }

    ListView --> BottomWidget
    GridView --> BottomWidget
    PageView --> BottomWidget
    StaggeredGridView --> BottomWidget
    ReorderableListView --> BottomWidget
```
