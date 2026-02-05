# Tech Spec: User Notification Preferences API

## 1. Header

| Field | Value |
|-------|-------|
| **Title** | User Notification Preferences API |
| **Status** | Approved |
| **Author** | Auto-generated |
| **Date** | 2025-01-15 |
| **PRD Source** | GitHub Issue #142 |
| **Version** | 1.0 |

---

## 2. Overview

Users currently receive all notification types with no ability to customize. This leads to notification fatigue and reduced engagement. We need an API that lets users configure which notification channels (email, push, in-app) they want for each notification category (mentions, updates, marketing).

The approach adds a new `notification_preferences` table, a CRUD API under `/api/users/:id/notification-preferences`, and a lookup function that the existing notification service calls before sending. We integrate with the existing auth middleware and follow the established service/route/model pattern.

---

## 3. Requirements Summary

### Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | Users can view their notification preferences | Must | Issue #142 |
| FR-2 | Users can update preferences per category/channel | Must | Issue #142 |
| FR-3 | New users get default preferences (all enabled) | Must | Issue #142 |
| FR-4 | Notification service checks preferences before sending | Must | Issue #142 |
| FR-5 | Admins can view any user's preferences | Should | Issue #142, comment 3 |

### Non-Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| NFR-1 | Preference lookup adds <5ms latency to notification path | Must | Issue #142 |
| NFR-2 | Preferences cached with 60s TTL | Should | Performance consideration |

---

## 4. Architecture

### Design Overview

A new preferences module sits between the existing notification service and delivery layer. The notification service calls `shouldNotify(userId, category, channel)` before dispatching. Preferences are stored in PostgreSQL and cached in the existing Redis instance.

### Component Diagram

```
┌──────────────┐     ┌───────────────────┐     ┌──────────────┐
│  API Routes  │────▶│  Preferences      │────▶│  PostgreSQL  │
│  (CRUD)      │     │  Service          │     │  (storage)   │
└──────────────┘     └───────────────────┘     └──────────────┘
                            │      ▲
                            ▼      │
┌──────────────┐     ┌───────────────────┐
│ Notification │────▶│  Redis Cache      │
│ Service      │     │  (60s TTL)        │
└──────────────┘     └───────────────────┘
```

### Architecture Decisions

| Decision | Choice | Alternatives Considered | Rationale |
|----------|--------|------------------------|-----------|
| Storage | PostgreSQL table | JSON in user record | Separate table allows indexing and avoids user table bloat |
| Caching | Redis with 60s TTL | In-memory LRU | Shared across instances, already in stack |
| Default strategy | Explicit rows on user creation | Fallback in code | Queryable, consistent, no null-handling complexity |

---

## 5. Component Specifications

### Component: Preferences Service

**Responsibility**: CRUD operations for notification preferences with caching

**Location**: `src/services/notification-preferences.ts`

**Public API**:

```typescript
function getPreferences(userId: string): Promise<NotificationPreferences>
function updatePreferences(userId: string, updates: PreferenceUpdate[]): Promise<NotificationPreferences>
function shouldNotify(userId: string, category: NotificationCategory, channel: NotificationChannel): Promise<boolean>
function createDefaultPreferences(userId: string): Promise<NotificationPreferences>
```

**Internal Structure**:
- `getFromCache(userId)` — Redis lookup, returns null on miss
- `setCache(userId, prefs)` — Redis set with 60s TTL
- `invalidateCache(userId)` — Redis delete on update

**Dependencies**:
- `src/db/connection` — Database pool
- `src/cache/redis` — Redis client
- `src/types/notifications` — Type definitions

### Component: Preferences Routes

**Responsibility**: HTTP endpoints for preference management

**Location**: `src/routes/notification-preferences.ts`

**Endpoints**:
- `GET /api/users/:userId/notification-preferences` — Get preferences
- `PUT /api/users/:userId/notification-preferences` — Update preferences

**Dependencies**:
- `src/middleware/auth` — Authentication and authorization
- `src/services/notification-preferences` — Business logic

---

## 6. Data Models

### NotificationPreferences

```typescript
type NotificationCategory = "mentions" | "updates" | "marketing";
type NotificationChannel = "email" | "push" | "in_app";

type PreferenceEntry = {
  category: NotificationCategory;
  channel: NotificationChannel;
  enabled: boolean;
};

type NotificationPreferences = {
  userId: string;
  preferences: PreferenceEntry[];
  updatedAt: Date;
};

type PreferenceUpdate = {
  category: NotificationCategory;
  channel: NotificationChannel;
  enabled: boolean;
};
```

### Database Table

```sql
CREATE TABLE notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category VARCHAR(20) NOT NULL,
  channel VARCHAR(20) NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, category, channel)
);

CREATE INDEX idx_notification_prefs_user ON notification_preferences(user_id);
```

---

## 7. File Ownership Map

| File Path | Action | Task ID | Wave |
|-----------|--------|---------|------|
| `src/types/notifications.ts` | Create | T-1 | 1 |
| `src/db/migrations/003_notification_preferences.sql` | Create | T-2 | 1 |
| `src/services/notification-preferences.ts` | Create | T-3 | 2 |
| `src/routes/notification-preferences.ts` | Create | T-4 | 2 |
| `src/services/notification-service.ts` | Modify | T-5 | 3 |
| `src/routes/index.ts` | Modify | T-5 | 3 |
| `tests/services/notification-preferences.test.ts` | Create | T-6 | 3 |
| `tests/routes/notification-preferences.test.ts` | Create | T-6 | 3 |

---

## 8. API/Interface Contracts

### GET /api/users/:userId/notification-preferences

**Response 200**:
```json
{
  "userId": "uuid",
  "preferences": [
    { "category": "mentions", "channel": "email", "enabled": true },
    { "category": "mentions", "channel": "push", "enabled": true },
    { "category": "updates", "channel": "email", "enabled": false }
  ],
  "updatedAt": "2025-01-15T10:30:00Z"
}
```

### PUT /api/users/:userId/notification-preferences

**Request**:
```json
{
  "updates": [
    { "category": "marketing", "channel": "email", "enabled": false }
  ]
}
```

**Response 200**: Same as GET response with updated values

**Response 400**:
```json
{
  "error": "validation_error",
  "details": [{ "field": "updates[0].category", "message": "Invalid category" }]
}
```

---

## 9. Error Handling Strategy

| Category | HTTP Status | Response Format | Logging | Recovery |
|----------|-------------|-----------------|---------|----------|
| Invalid category/channel | 400 | `{ error, details[] }` | Warn | Return to client |
| User not found | 404 | `{ error: "user_not_found" }` | Debug | Return to client |
| Auth failure | 401/403 | `{ error: "unauthorized" }` | Info | Return to client |
| DB failure | 500 | `{ error: "internal_error" }` | Error + stack | Retry once, then fail |
| Cache failure | N/A (transparent) | N/A | Warn | Skip cache, hit DB |

---

## 10. Acceptance Criteria

| # | Criterion | Requirement | Verification |
|---|-----------|-------------|-------------|
| AC-1 | GET returns all 9 preference entries (3 categories x 3 channels) for existing user | FR-1 | Integration test |
| AC-2 | PUT updates specified entries and returns full preference set | FR-2 | Integration test |
| AC-3 | New user creation triggers default preferences (all enabled) | FR-3 | Unit test |
| AC-4 | `shouldNotify` returns false when preference is disabled | FR-4 | Unit test |
| AC-5 | `shouldNotify` returns true when preference is enabled | FR-4 | Unit test |
| AC-6 | Preference lookup completes in <5ms with warm cache | NFR-1 | Performance test |
| AC-7 | Cache invalidates on preference update | NFR-2 | Unit test |

---

## 11. Out of Scope

- Bulk notification preference management for admins
- Notification preference import/export
- Per-notification-instance overrides (e.g., mute a specific thread)
- UI components for preference management (frontend team handles separately)

---

## 12. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Cache stampede on popular user | Low | High latency spike | Use cache-aside with lock on miss |
| Migration on large users table | Med | Downtime during migration | Run migration during low-traffic window, add concurrently |
| Default preferences not created for existing users | High | 404 on first access | Add backfill migration + fallback to defaults in service |
