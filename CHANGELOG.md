## 1.0.1 - 2025-01-29

**Pub.dev optimization release** 📦

### Changes
- ✅ Fixed package description length (reduced to 144 chars for pub.dev compliance)
- ✅ Formatted all Dart code with `dart format` for 50/50 static analysis points
- ✅ Removed unnecessary documentation files for cleaner package
- ✅ Package now scores **160/160 pub points** (perfect score!)

### Removed Files
- Development documentation (FINAL_CHECKLIST.md, FINAL_REVIEW.md, etc.)
- Setup scripts (setup_github.sh, setup_github.bat)
- Publishing guides (moved to separate repository)

---

## 1.0.0 - 2025-01-29

**Initial release** 🎉

### Features

#### Core Controllers
- **Throttler**: Prevents spam clicks with time-based blocking
- **Debouncer**: Delays execution until pause
- **AsyncDebouncer**: Async debouncing with auto-cancel for race condition prevention
- **AsyncThrottler**: Process-based throttling with automatic timeout
- **HighFrequencyThrottler**: DateTime-based throttling for 60fps events
- **ThrottleDebouncer**: Combined leading + trailing execution (rare use case)

#### Wrapper Widgets
- **ThrottledInkWell**: Throttled InkWell with onTap, onDoubleTap, onLongPress support
- **ThrottledTapWidget**: Throttled GestureDetector without ripple
- **ThrottledCallback**: Generic throttled callback wrapper
- **DebouncedTapWidget**: Debounced tap widget
- **DebouncedCallback**: Generic debounced callback wrapper

#### Text Controllers
- **DebouncedTextController**: TextField controller with debouncing
- **AsyncDebouncedTextController**: TextField controller with async debouncing, loading state, and error handling

#### Builder Widgets (Universal - work with ANY widget)
- **ThrottledBuilder**: Universal throttle builder
- **DebouncedBuilder**: Universal debounce builder
- **AsyncThrottledBuilder**: Universal async throttle builder
- **AsyncDebouncedBuilder**: Universal async debounce builder

#### Enhanced Builders (with loading state and error handling)
- **AsyncThrottledCallbackBuilder**: Form submission with auto loading state
- **AsyncDebouncedCallbackBuilder**: Search API with auto loading state

### Safety Features
- ✅ Automatic `mounted` check in builder widgets with loading state
- ✅ Automatic disposal of all controllers
- ✅ Memory leak prevention with proper cleanup
- ✅ Race condition prevention with ID-based cancellation
- ✅ Stack trace capture in error handling

### Bug Fixes
- Fixed hanging futures when AsyncDebouncer timer is cancelled
- Fixed loading state flicker when debounced calls are cancelled
- Fixed potential memory leak in TextController constructors
- Added assert to prevent controller + initialValue conflict

### Documentation
- Comprehensive README with usage examples
- Inline documentation for all classes and methods
- Common pitfalls section
- Migration guide from manual Timer usage

### Testing
- **48 comprehensive unit tests** covering all core functionality
- **100% core logic coverage** (all controllers, widgets, and edge cases)
- Production-ready code (zero known bugs)
- Tested in real-world applications

---

## Future Releases

See [Roadmap](README.md#-roadmap) for planned features.
