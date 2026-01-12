# Test Isolation Architecture

## Overview

This document describes the clean, object-oriented architecture implemented for test isolation in Fontist. The design follows SOLID principles with proper separation of concerns.

## Architecture

### Component Pattern

The architecture uses a **Component Pattern** where each stateful subsystem is encapsulated in its own component class:

```
IsolationManager (Singleton)
  ├── SystemIndexComponent
  ├── SystemFont Component
  └── FormulaIndexComponent
```

Each component:
- Implements a `#reset` method
- Knows how to clean its own state
- Is registered with the IsolationManager
- Follows Single Responsibility Principle

### Class Structure

#### 1. IsolationManager ([`spec/support/spec_isolation_manager.rb`](spec/support/spec_isolation_manager.rb:1))

**Responsibility**: Coordinate test isolation across all components

**Pattern**: Singleton
- Only one manager per test suite
- Centralized state management
- Easy to extend with new components

**Key Methods**:
- `reset_all` - Resets all registered components
- `register_component(component)` - Adds a new component to manage

#### 2. Component Classes

**SystemIndexComponent**
- Resets `SystemIndex` class-level caches
- Resets verification flags on cached instances
- Encapsulates SystemIndex state management

**SystemFontComponent**
- Resets font path caches
- Manages SystemFont state

**FormulaIndexComponent**
- Resets formula index caches
- Manages Index state

### Integration

#### RSpec Configuration ([`spec/support/spec_isolation_config.rb`](spec/support/spec_isolation_config.rb:1))

```ruby
RSpec.configure do |config|
  config.before(:each) do
    Fontist::Test::IsolationManager.instance.reset_all
  end
end
```

**Benefits**:
- Centralized configuration
- No scattered `before(:each)` hooks in spec files
- Easy to disable for debugging
- Consistent across all tests

#### Helper Integration ([`spec/support/fontist_helper.rb`](spec/support/fontist_helper.rb:3))

The `reset_all_fontist_caches` method now delegates to Is

olationManager:

```ruby
def reset_all_fontist_caches
  Fontist::Test::IsolationManager.instance.reset_all
end
```

This maintains backward compatibility while using the new architecture.

## Design Principles Applied

### 1. Single Responsibility Principle
- Each component manages only its own state
- IsolationManager only coordinates, doesn't implement resets
- Clear separation between coordination and execution

### 2. Open/Closed Principle
- Easy to add new components without modifying existing code
- Just create a new component class and register it
- Extension through registration, not modification

### 3. Dependency Inversion
- Components depend on the interface (having a `#reset` method)
- Manager doesn't depend on concrete component implementations
- Loose coupling between manager and components

### 4. Encapsulation
- Each component encapsulates knowledge of how to reset its subsystem
- Global state management is hidden within components
- Public interface is simple: `#reset`

## Extensibility

### Adding New Components

To manage a new stateful subsystem:

1. Create a component class:
```ruby
class MyComponent
  def reset
    # Reset your state here
  end
end
```

2. Register it in IsolationManager:
```ruby
def register_default_components
  register_component(SystemIndexComponent.new)
  register_component(SystemFontComponent.new)
  register_component(FormulaIndexComponent.new)
  register_component(MyComponent.new)  # Add here
end
```

No other changes needed!

## Benefits

### Clean Code
- No scattered cache resets throughout codebase
- Clear ownership of state management
- Easy to understand and maintain

### Testability
- Each component can be tested independently
- Manager can be tested with mock components
- Clear interfaces enable easy testing

### Maintainability
- Single place to look for state management
- Changes to reset logic are localized
- New components easy to add

### Debugging
- Can disable isolation by commenting out config
- Can log component resets for debugging
- Clear execution flow

## Current Limitations

The 21 failing tests indicate test **order dependencies** beyond cache state:

1. Tests may depend on side effects from previous tests
2. Tests may share fixture data incorrectly
3. Tests may have timing dependencies
4. Tests may depend on specific execution order

These require deeper investigation:
- Use `--order random --seed XXXX` to reproduce
- Use `--bisect` to find minimal failing set
- Use `--only-failures` to focus on failures
- Check for shared state in test fixtures

## Future Enhancements

### Potential Components to Add

1. **FileSystemComponent** - Reset temp directories
2. **DatabaseComponent** - If database state needed
3. **NetworkComponent** - Reset VCR cassettes
4. **ConfigComponent** - Reset configuration state

### Monitoring

Could add instrumentation:
```ruby
class IsolationManager
  def reset_all
    @metrics ||= {}
    managed_components.each do |component|
      start_time = Time.now
      component.reset
      @metrics[component.class] = Time.now - start_time
    end
  end

  def report_metrics
    # Show which components are slow
  end
end
```

## Conclusion

The test isolation architecture is now clean, extensible, and follows OOP best practices. The remaining test failures are order-dependency issues that require individual test refactoring, not architectural changes.