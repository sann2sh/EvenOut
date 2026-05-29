
# Product Requirements Document (PRD): EvenOut
1. Project Context & Objectives
Project Name: EvenOut
Target Audience: eSewa users in Nepal (9M+ user base).
Core Problem: Group expense management is heavily fragmented across WhatsApp and Excel, causing high friction and delayed settlements.
Solution: A smart app that handles group expenses, scanning, splitting, tracking, and settling debts, gamified to encourage fast repayment.

2. Architecture & Technology Stack
The project utilizes a strict monorepo architecture to ensure synchronized models, types, and rapid deployment.
```plaintext
/evenout-monorepo
├── /backend-evenout # Main monolithic API (Node.js/NestJS) deployed on Render
        supabase-migrations   # Database schemas, RLS policies, and SQL Views
├── /frontend_evenout   # Primary user application (Flutter + Riverpod)


Deployment: render auto deploy on git push
Database: supabase
   
```


Core Tech Matrix:
Mobile Frontend: Flutter (Dart) with Riverpod, flutter_supabase, camera, qr_flutter, speech_to_text, and local storage (Isar/Hive) for offline queuing.
Backend API: Node.js + NestJS via REST endpoints.
Database & BaaS: Supabase (PostgreSQL, Row-Level Security, Auth, Storage).
Real-time Sync: Supabase Realtime WebSockets.
External APIs: antthropic api (OCR),Gemini API (Fast NLP), Firebase Cloud Messaging (FCM).


3. Core Features & Implementation Logic


Feature 1: The Ledger Engine (Log, Track, Settle)
Function: The foundational layer tracking peer obligations.
Logic: Utilizes a flat PostgreSQL schema (users, groups, group_members, expenses, expense_splits, settlements). Supabase Realtime broadcasts updates instantly to all group members.
Action: The "Settle Up" button triggers an eSewa Deep Link (esewa://...) pre-filled with the payee's ID and exact amount.



Feature 2: Offline-First Action Queue
Function: Allows users to log expenses and splits even without cellular coverage.
Logic: The Flutter client generates the UUID locally and saves the payload to an on-device NoSQL queue. When connectivity_plus detects a network restoration, a background worker pushes the payload to the NestJS API via an Upsert command, preventing duplicate entries.



Feature 3: Context-Aware Notifications (The "Duolingo" Engine)
Function: Quirky push notifications nudging users to pay debts.
Logic: The NestJS backend rotates through an array of hardcoded, localized strings (e.g., "Gagan is too polite to ask, but the database isn't. Pay back that Rs. 450 for Momo."). FCM pushes are triggered by cron jobs based on the age of the debt.


Feature 4: QR Group Creation & Joining
Function: Frictionless physical onboarding for table groups.
Logic: Flutter generates a QR code containing a deep link (evenout://join-group?id=<UUID>). Scanning it triggers an API call that appends the user to the group_members table instantly.



Feature 5: Intelligent OCR Bill Scanning
Function: Auto-populates structured split allocations by scanning physical receipts.
Logic Pipeline:
Flutter captures image $\rightarrow$ Uploads to Supabase Storage.
NestJS intercepts the public URL $\rightarrow$ Calls Google Cloud Vision API.
NestJS parses the raw text block into structured JSON line items.
Flutter renders an interactive UI for users to assign specific dishes to members.



Feature 6: Hands-Free Voice Payment Scheduling
Function: Frictionless expense entry via natural language.
Logic: The device captures speech via speech_to_text (e.g., "I paid 100 for Ashutosh"). The raw string is sent to a fast LLM API via NestJS with a strict JSON-enforced prompt to extract the payer, payee, and amount, instantly populating the UI.



Feature 7: SplitScore Gamification
Function: An informal credit score visible on profiles to incentivize fast repayment.
Logic: Calculated dynamically via a Postgres View using the formula: Score = 500 + (Timely_Settlements * 10) - (Overdue_Days * 15). Displayed with ranking tiers (e.g., 720 - Financial Saint).



Feature 8: "Chaos Roulette" Split Mode
Function: A gamified, high-stakes bill splitting utility using a digital spin wheel.
Logic: The backend receives an array of user IDs ordered by their spin-wheel elimination sequence and applies a cascading 50% reduction strategy:
$$\text{Share}(i) = \begin{cases} \text{Total Amount} & \text{if } N = 2 \text{ and } i = 0 \\ 0 & \text{if } N = 2 \text{ and } i = 1 \\ \text{Remaining Balance} \times 0.5 & \text{if } i < N - 2 \\ \text{Remaining Balance} \times 0.5 & \text{if } i = N - 2 \text{ or } i = N - 1 \end{cases}$$



Feature 9: Greedy Debt Simplification Engine
Function: Minimizes the total number of transactions required to settle a group by mathematically bypassing intermediate debtors (e.g., if A owes B, and B owes C $\rightarrow$ A pays C directly).
Logic: Executed entirely on the presentation layer. NestJS fetches raw balances and runs a Greedy Algorithm to match the highest debtors with the highest creditors without altering the historical database logs.



4. Database & Algorithmic Foundations
The peer_balances PostgreSQL View
To avoid data drift, net balances are never stored statically. They are calculated on the fly using a SQL View:
```sql
CREATE OR REPLACE VIEW peer_balances AS
WITH total_owed AS (
    SELECT 
        es.user_id AS debtor_id,
        e.paid_by AS creditor_id,
        SUM(es.amount_owed) AS amount
    FROM expense_splits es
    JOIN expenses e ON es.expense_id = e.id
    WHERE es.is_settled = false
    GROUP BY es.user_id, e.paid_by
),
total_paid AS (
    SELECT 
        payer_id AS debtor_id,
        payee_id AS creditor_id,
        SUM(amount) AS amount
    FROM settlements
    WHERE status = 'confirmed'
    GROUP BY payer_id, payee_id
)
SELECT 
    COALESCE(o.debtor_id, p.debtor_id) AS user_id,
    COALESCE(o.creditor_id, p.creditor_id) AS counterpart_id,
    COALESCE(o.amount, 0) - COALESCE(p.amount, 0) AS net_debt
FROM total_owed o
FULL OUTER JOIN total_paid p 
ON o.debtor_id = p.debtor_id AND o.creditor_id = p.creditor_id;
```


The Debt Simplification Controller (NestJS)
When the client calls GET /groups/:id/optimized-settlements, the server processes the view data using this TypeScript algorithm:
```typescript
interface UserBalance { userId: string; netBalance: number; }
interface OptimizedDebt { payerId: string; payeeId: string; amount: number; }

function calculateOptimizedDebts(balances: UserBalance[]): OptimizedDebt[] {
  const debtors = balances.filter(b => b.netBalance < 0).sort((a, b) => a.netBalance - b.netBalance);
  const creditors = balances.filter(b => b.netBalance > 0).sort((a, b) => b.netBalance - a.netBalance);
  const optimizedSettlements: OptimizedDebt[] = [];
  
  let i = 0; let j = 0;
  
  while (i < debtors.length && j < creditors.length) {
    const debtor = debtors[i];
    const creditor = creditors[j];
    
    const amountToSettle = Math.min(Math.abs(debtor.netBalance), creditor.netBalance);
    
    optimizedSettlements.push({
      payerId: debtor.userId,
      payeeId: creditor.userId,
      amount: amountToSettle,
    });
    
    debtor.netBalance += amountToSettle;
    creditor.netBalance -= amountToSettle;
    
    if (Math.abs(debtor.netBalance) < 0.01) i++;
    if (creditor.netBalance < 0.01) j++;
  }
  return optimizedSettlements;
}
```


5. Development Priorities (Hackathon Scope)



Phase 1: db setup, auth, feature 1,2,4

Phase 2: feature 3

Phase 3: Feature 5

Phase 4: Feature 6

Other features:
Skeleton pages
Google login
Steps/Phases




Development Phases (Hackathon Execution Plan)

Phase 1: Foundation, Auth, and Core Engine (Features 1, 2, 4)
Goal: Get users logged in, grouped up, and able to log an expense (even offline).
Database & Auth Setup (Supabase):
Create the Supabase project.
Run your SQL migrations to set up the flat schema (users, groups, group_members, expenses, expense_splits, settlements).
Implement Row-Level Security (RLS) policies.
Set up Google Login via Supabase Auth.
Create the peer_balances SQL View from the PRD.
Backend (NestJS on Render):
Scaffold the monorepo.
Create the REST endpoints for group creation, fetching balances, and the /groups/:id/optimized-settlements route using the provided Greedy Algorithm.



Frontend (Flutter):
Build skeleton pages using AI/Figma plugins.
Implement Google Login.
Feature 4 (QR Groups): Generate QR codes with deep links (evenout://join-group?id=<UUID>) and handle the incoming deep link to trigger the join API call.
Feature 1 & 2 (Ledger & Offline Queue): Build the expense entry form. Tackling the offline-first action queue using local storage (Isar/Hive) is crucial here; generate UUIDs locally, save the payload, and use connectivity_plus to trigger a background worker that pushes to the NestJS API when online.

Phase 2: The Nudge Engine (Feature 3)
Goal: Implement the "Duolingo" style notifications.
Backend: Set up the cron jobs in NestJS to check the age of debts. Create the array of localized, quirky strings.
FCM Integration: Wire up Firebase Cloud Messaging in the NestJS backend to push these strings to specific user tokens.
Frontend: Request notification permissions in Flutter and handle incoming FCM payloads.

Phase 3: Intelligent Inputs (Feature 5)
Goal: Auto-populate expenses from physical receipts.
Frontend: Implement the camera UI. When a photo is taken, upload the image directly to a Supabase Storage bucket.
Backend: Intercept the public URL of the uploaded image and send it to the Google Cloud Vision API (or Anthropic API as noted in your stack). Parse the raw text into structured JSON and return it to the client.
Frontend: Render the interactive UI allowing users to assign the parsed line items to specific group members.

Phase 4: Hands-Free Polish (Feature 6)
Goal: Voice-to-text expense logging.
Frontend: Implement the speech_to_text package to capture natural language commands.
Backend/AI: Send the raw string to the Gemini API via NestJS with a strict JSON-enforced prompt to extract the payer, payee, and amount.
Frontend: Populate the UI with the returned JSON for user confirmation.
Since hackathons are a race against the clock, getting the foundational data layer operating flawlessly is your biggest hurdle. Which specific part of Phase 1—like writing the SQL for the peer_balances view or configuring the Supabase Google Auth—should we tackle first?


The Replacement: PostgreSQL View for Balances
Since we deleted the debts and balances tables, you will need a dynamic way to check who owes whom without doing complex math every time you hit an endpoint.
Run this script in Supabase to create a View. It automatically calculates exactly how much User A owes User B by subtracting their confirmed settlements from their total expenses owed.
```sql
CREATE OR REPLACE VIEW peer_balances AS
WITH total_owed AS (
    -- Calculate everything a user owes to the person who paid the bill
    SELECT 
        es.user_id AS debtor_id,
        e.paid_by AS creditor_id,
        SUM(es.amount_owed) AS amount
    FROM expense_splits es
    JOIN expenses e ON es.expense_id = e.id
    WHERE es.is_settled = false
    GROUP BY es.user_id, e.paid_by
),
total_paid AS (
    -- Calculate everything the debtor has already paid back via confirmed settlements
    SELECT 
        payer_id AS debtor_id,
        payee_id AS creditor_id,
        SUM(amount) AS amount
    FROM settlements
    WHERE status = 'confirmed'
    GROUP BY payer_id, payee_id
)
SELECT 
    COALESCE(o.debtor_id, p.debtor_id) AS user_id,
    COALESCE(o.creditor_id, p.creditor_id) AS counterpart_id,
    COALESCE(o.amount, 0) - COALESCE(p.amount, 0) AS net_debt
FROM total_owed o
FULL OUTER JOIN total_paid p 
ON o.debtor_id = p.debtor_id AND o.creditor_id = p.creditor_id;
```




SELECT * FROM peer_balances WHERE user_id = 'some-uuid' 



3. How to Implement the "Simplify Debts" Engine in NestJS
To build this, you need to add a single new endpoint to your NestJS backend: GET /groups/:id/optimized-settlements.
Under the hood, you will use a Greedy Algorithm. Here is the exact logic you need to write in your NestJS service:



Step 1: Get Net Balances Query the peer_balances SQL View we created earlier, filtered by the group_id. Calculate the absolute net balance for every single person in that group.


Step 2: Separate into Debtors and Creditors Split the group into two lists:
Debtors: People whose net balance is negative (they owe money).
Creditors: People whose net balance is positive (they are owed money).


Step 3: The Greedy Match (The Algorithm) Sort both lists from largest to smallest. Take the person who owes the most, and have them pay the person who is owed the most.
Here is the TypeScript logic you can drop directly into your NestJS service:

```typescript
interface UserBalance {
  userId: string;
  netBalance: number;
}

interface OptimizedDebt {
  payerId: string;
  payeeId: string;
  amount: number;
}

function calculateOptimizedDebts(balances: UserBalance[]): OptimizedDebt[] {
  const debtors = balances.filter(b => b.netBalance < 0).sort((a, b) => a.netBalance - b.netBalance);
  const creditors = balances.filter(b => b.netBalance > 0).sort((a, b) => b.netBalance - a.netBalance);
  
  const optimizedSettlements: OptimizedDebt[] = [];
  
  let i = 0; // Debtors index
  let j = 0; // Creditors index
  
  while (i < debtors.length && j < creditors.length) {
    const debtor = debtors[i];
    const creditor = creditors[j];
    
    // The amount to settle is the minimum of what the debtor owes and what the creditor is owed
    const amountToSettle = Math.min(Math.abs(debtor.netBalance), creditor.netBalance);
    
    optimizedSettlements.push({
      payerId: debtor.userId,
      payeeId: creditor.userId,
      amount: amountToSettle,
    });
    
    // Adjust balances
    debtor.netBalance += amountToSettle;
    creditor.netBalance -= amountToSettle;
    
    // Move to the next person if their balance is cleared
    if (Math.abs(debtor.netBalance) < 0.01) i++;
    if (creditor.netBalance < 0.01) j++;
  }
  
  return optimizedSettlements;
}
```

## 4. How it flows in the App
The user opens the "Pokhari Trip" group in Flutter.
Flutter calls GET /groups/<id>/optimized-settlements.

NestJS pulls the raw balances, runs the TypeScript algorithm above, and returns a clean array: [{ payerId: "A", payeeId: "C", amount: 100 }].

Flutter displays a button: "Ashutosh, pay Santosh Rs. 100".
When Ashutosh taps it, it triggers the eSewa Deep Link. When confirmed, it writes a standard record to the settlements table.

This gives you the exact Splitwise functionality without corrupting your audit logs or redesigning your database! To help you visualize exactly how this graph transformation works under the hood, I've generated an interactive simulator below.

.



How to Secure Your peer_balances View
To patch this security vulnerability before deploying your backend or hooking it up to your mobile app, use one of these two industry-standard approaches:

Option A: Use a Security Invoker View (Recommended for Postgres 15+)
If your Supabase instance is running Postgres 15 or newer, you can explicitly force the view to respect the querying user's active RLS policies by appending with (security_invoker = true) when creating it:

SQL
CREATE VIEW peer_balances 
WITH (security_invoker = true) AS 
SELECT 
    ...
FROM expenses e
JOIN group_members gm ON ...;
Now, when your Flutter client requests data from this view, Postgres passes down the user's JWT context, forcing the query to respect the RLS gates on the underlying expenses and group_members tables.

Option B: Wrap it in a Secure Stored Procedure (RPC)
If you prefer not to manage view configurations, convert the view's underlying query into a Supabase Remote Procedure Call (RPC) function that takes a group_id as an argument and enforces membership manually inside the function body:

SQL
CREATE OR REPLACE FUNCTION get_peer_balances(target_group_id UUID)
RETURNS TABLE (user_id UUID, net_balance NUMERIC) 
LANGUAGE plpgsql
SECURITY INVOKER -- Forces compliance with active user permissions
AS $$
BEGIN
    -- Verify the requesting user is actually a member of the group
    IF EXISTS (
        SELECT 1 FROM group_members 
        WHERE group_id = target_group_id AND user_id = auth.uid()
    ) THEN
        RETURN QUERY
        SELECT ... -- Your optimization logic filtered by target_group_id
    ELSE
        RAISE EXCEPTION 'Access Denied: You are not a member of this group.';
    END IF;
END;
$$;
This prevents any accidental structural data leaks across your hackathon project, keeping your ledger secure and multi-tenant friendly!