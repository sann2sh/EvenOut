# Dynamic Nudge Templates Implementation Plan

Currently, the notification templates are **hardcoded** inside the backend code (`nudges.service.ts` and `scheduler.service.ts`). Each time a nudge is triggered, the system randomly picks an item from an array like this:
```typescript
const QUIRKY_TEMPLATES = [
  "Did you forget your wallet in 2012? Pay {name} Rs. {amount}!",
  // ...
];
```

To allow you to upload templates dynamically without changing code, we need to move these templates to the database.

## Proposed Changes

### 1. Database Update (Supabase)
We will create a new table called `nudge_templates` to store the templates. 
#### [NEW] `supabase/migrations/20260530100000_nudge_templates.sql`
- Add `nudge_templates` table with columns: `id`, `template_text`, `type` (manual vs. auto).

### 2. Template Management API
We will add a new endpoint to allow you to upload/manage templates.
#### [NEW] `src/nudges/dto/add-template.dto.ts`
- DTO to validate uploaded templates.
#### [MODIFY] `src/nudges/nudges.controller.ts`
- Add `POST /nudges/templates` to insert new templates into the database.
- Add `GET /nudges/templates` to list existing templates.

### 3. Nudge Generation Logic
We will modify the services to pull templates from the database instead of the hardcoded arrays.
#### [MODIFY] `src/nudges/nudges.service.ts`
- Query the `nudge_templates` table where `type = 'manual'`.
- Fall back to a default hardcoded template if the table is empty.
#### [MODIFY] `src/scheduler/scheduler.service.ts`
- Query the `nudge_templates` table where `type = 'auto'`.
- Fall back to a default hardcoded template if the table is empty.

## User Review Required

> [!IMPORTANT]  
> Are these templates meant to be **global** for the entire app (managed by admins), or can any user add their own templates? I will implement them as global app-wide templates by default. Let me know if you want them to be user-specific!

## Verification Plan
1. Apply the database migration.
2. Use Postman to `POST` a new quirky template to `/nudges/templates`.
3. Trigger a manual nudge via `POST /nudges/send` and verify that the newly uploaded template is randomly selected.
