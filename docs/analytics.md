# Analytics Tracking System

## Overview

純前端行為追蹤系統，透過 Supabase REST API 記錄用戶行為，所有資料寫入 Supabase PostgreSQL。

- **Supabase Project**: `lhxwbvqihjmtaalwhqfr`
- **API URL**: `https://lhxwbvqihjmtaalwhqfr.supabase.co`
- **安全性**: 所有 table 啟用 RLS，anon role 只能 INSERT，無法讀取或刪除

---

## Tables

### `email_signups`

Email 收集表。

| 欄位 | 型別 | 說明 |
|------|------|------|
| id | uuid | PK, auto |
| email | text | UNIQUE, NOT NULL |
| created_at | timestamptz | 建立時間 |

### `sessions`

每次頁面造訪建一筆。

| 欄位 | 型別 | 說明 |
|------|------|------|
| id | uuid | PK, 前端產生 |
| anonymous_id | text | localStorage 跨 session 識別 |
| referrer | text | `document.referrer` |
| utm_source | text | `?utm_source=` |
| utm_medium | text | `?utm_medium=` |
| utm_campaign | text | `?utm_campaign=` |
| utm_content | text | `?utm_content=` |
| custom_ref | text | `?from=` 或 `?ref=` |
| device_type | text | mobile / tablet / desktop |
| screen_width | int | 螢幕寬 |
| screen_height | int | 螢幕高 |
| language | text | 瀏覽器語言 |
| user_agent | text | UA 字串 |
| created_at | timestamptz | 造訪時間 |

### `section_views`

Section 停留紀錄，每次用戶滾動到一個 section 並離開時記一筆。

| 欄位 | 型別 | 說明 |
|------|------|------|
| id | uuid | PK, auto |
| session_id | uuid | FK → sessions.id |
| anonymous_id | text | |
| section_id | text | `home`, `event`, `about`, `app-features`, `app-compare`, `domains`, `bottom-cta` |
| enter_at | timestamptz | 進入時間 |
| dwell_ms | int | 停留毫秒數 |
| created_at | timestamptz | |

### `events`

通用互動事件。

| 欄位 | 型別 | 說明 |
|------|------|------|
| id | uuid | PK, auto |
| session_id | uuid | FK → sessions.id |
| anonymous_id | text | |
| event_name | text | 事件名稱 |
| metadata | jsonb | 額外資料 |
| created_at | timestamptz | |

#### 追蹤的事件

| event_name | 觸發時機 | metadata |
|------------|---------|----------|
| `cta_click` | 點 CTA 按鈕 | `{"button": "hero_cta" \| "event_preview_cta" \| "bottom_cta"}` |
| `email_modal_open` | 彈窗開啟 | `{}` |
| `email_modal_close` | 彈窗關閉 | `{}` |
| `email_submit` | Email 送出成功 | `{}` |

---

## 導流連結用法

在網址後加 query parameter 即可追蹤來源：

```
# 自訂來源標記（擇一）
https://yoursite.com?from=ig_bio
https://yoursite.com?ref=line_group

# 標準 UTM（可組合）
https://yoursite.com?utm_source=facebook&utm_medium=ad&utm_campaign=spring_launch

# 混合使用
https://yoursite.com?from=ig_story&utm_source=instagram&utm_campaign=launch
```

---

## 前端架構

所有 tracking code 在 `src/index.html` 底部的獨立 `<script>` IIFE 中。

1. **Anonymous ID** — `crypto.randomUUID()` 產生，存 `localStorage('fanbook_anonymous_id')`，跨 session 識別同一用戶
2. **Session** — 頁面載入時建立，id 由前端產生（因 RLS 無法用 `return=representation`）
3. **Section tracking** — `IntersectionObserver` (threshold 0.3) 監聽 7 個 section，停留 >500ms 才記錄
4. **Buffer 機制** — section_views 先暫存，每 10 秒或頁面關閉時批次送出
5. **Page leave** — `visibilitychange` + `pagehide` 事件觸發 `fetch(..., {keepalive: true})` 確保資料不丟失

---

## RLS 政策

所有 table 只有一條 policy：

```sql
CREATE POLICY "anon_insert" ON public.<table>
  FOR INSERT TO anon WITH CHECK (true);
```

前端只能寫入，無法讀取、更新或刪除任何資料。
