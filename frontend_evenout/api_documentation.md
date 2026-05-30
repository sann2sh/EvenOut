# EvenOut Backend API Documentation

**Base URL:** `http://evenout-ilq1.onrender.com/api/v1` (for local development)

**Authentication:** Almost all endpoints require a Bearer token in the Authorization header. 
* **Header:** `Authorization: Bearer <your_jwt_access_token>`

---

## 1. Authentication (`/auth`)

### Sign Up
* **URL:** `POST /auth/signup`
* **Auth Required:** No
* **Function:** Registers a new user with an email and password. Automatically creates their profile in the database.
* **Request Body:**
    ```json
    {
      "email": "user@example.com",
      "password": "securepassword123",
      "display_name": "John Doe"
    }
    ```
* **Response:** Returns the created user object and a success message.

### Log In
* **URL:** `POST /auth/login`
* **Auth Required:** No
* **Function:** Authenticates the user and returns JWT tokens.
* **Request Body:**
    ```json
    {
      "email": "user@example.com",
      "password": "securepassword123"
    }
    ```
* **Response:** Returns `access_token`, `refresh_token`, and the user object.

---

## 2. Users (`/users`)

### Get My Profile
* **URL:** `GET /users/me`
* **Function:** Retrieves the currently authenticated user's profile details.
* **Response:** `{ id, email, display_name, avatar_url, split_score, ... }`

### Update My Profile
* **URL:** `PATCH /users/me`
* **Function:** Updates the user's profile details (partial or full updates). Accepts an optional `username`.
* **Username Rules:** 3–50 chars, only letters, numbers, underscores (`sann_2sh` ✅, `sann 2sh` ❌). If already taken, returns `409 Conflict`.
* **Request Body Examples:**
    * *Example 1: Full Update*
        ```json
        {
          "username": "sann2sh",
          "display_name": "Sann2sh",
          "phone_number": "+9779800000000",
          "avatar_url": "[https://example.com/my-avatar.png](https://example.com/my-avatar.png)"
        }
        ```
    * *Example 2: Partial Update (Phone Only)*
        ```json
        {
          "phone_number": "+9779800000000"
        }
        ```
    * *Example 3: Partial Update (Avatar Only)*
        ```json
        {
          "avatar_url": "[https://example.com/new-avatar.png](https://example.com/new-avatar.png)"
        }
        ```
* **Response:** Returns the updated user object.

### Search Users
* **URL:** `GET /users/search?query=sann`
* **Function:** Searches by both `username` AND `display_name` (case-insensitive). Excludes yourself from results. Returns up to 20 matches.
* **Response:**
    ```json
    [
      { 
        "id": "uuid", 
        "username": "sann_2sh", 
        "display_name": "Sann", 
        "avatar_url": "https://..." 
      }
    ]
    ```

### Get User Profile (Public)
* **URL:** `GET /users/:id/profile`
* **Function:** Gets basic public info of another user.

---

## 3. Friendships (`/friendships`)

### Send Friend Request
* **URL:** `POST /friendships/requests`
* **Function:** Sends a friend request to another user.
* **Request Body:**
    ```json
    {
      "addressee_id": "uuid-of-the-user-to-add"
    }
    ```
* **Response:** Returns the created friendship record (status: pending).
    ```json
    {
      "id": "uuid-of-friendship-record",
      "requester_id": "your-uuid",
      "addressee_id": "uuid-of-friend",
      "status": "pending"
    }
    ```

### View Accepted Friends
* **URL:** `GET /friendships`
* **Function:** Gets a list of all accepted friends for the current user.
* **Response:** ```json
    [
      {
        "friendshipId": "uuid-of-friendship",
        "createdAt": "2026-05-30T...",
        "id": "friend-uuid",
        "display_name": "Alice",
        "avatar_url": "https://..."
      }
    ]
    ```

### View Received Friend Requests
* **URL:** `GET /friendships/requests`
* **Function:** Gets all pending incoming friend requests sent to you by other users.
* **Response:**
    ```json
    [
      {
        "id": "uuid-of-friendship",
        "status": "pending",
        "requested_at": "2026-05-30T...",
        "requester": {
          "id": "sender-uuid",
          "display_name": "Bob",
          "avatar_url": "https://..."
        }
      }
    ]
    ```

### View Sent Friend Requests
* **URL:** `GET /friendships/requests/sent`
* **Function:** Gets all pending outgoing friend requests that you have sent.
* **Response:**
    ```json
    [
      {
        "id": "uuid-of-friendship",
        "status": "pending",
        "requested_at": "2026-05-30T...",
        "addressee": {
          "id": "recipient-uuid",
          "display_name": "Charlie",
          "avatar_url": "https://..."
        }
      }
    ]
    ```

### Approve or Decline a Request
* **URL:** `PATCH /friendships/requests/:id`  *(Replace :id with the friendship ID, not user ID)*
* **Function:** Accepts or declines a friend request.
* **Request Body:**
    ```json
    {
      "status": "accepted" // or "declined"
    }
    ```
* **Response:** Returns the updated friendship record.
    ```json
    {
      "id": "uuid-of-friendship",
      "requester_id": "sender-uuid",
      "addressee_id": "your-uuid",
      "status": "accepted"
    }
    ```

### Remove a Friend (Unfriend)
* **URL:** `DELETE /friendships/:id` *(Replace :id with the friendship ID)*
* **Function:** Unfriends a user.
* **Response:**
    ```json
    {
      "message": "Friend removed successfully"
    }
    ```

---

## 4. Groups (`/groups`)

### Create Group
* **URL:** `POST /groups`
* **Function:** Creates a new ledger group and assigns the creator as an admin.
* **Request Body:**
    ```json
    {
      "name": "Goa Trip",
      "description": "Fun times",
      "currency": "NPR" // Optional
    }
    ```
* **Response:** Group object containing `invite_code` and `invite_qr_url`.

### Get My Groups
* **URL:** `GET /groups`
* **Function:** Retrieves all active groups the user is a part of.
* **Response:** Array of group objects.

### Get Group Details
* **URL:** `GET /groups/:id`
* **Function:** Gets details of a specific group.

### Join Group (via Code)
* **URL:** `POST /groups/join`
* **Function:** Joins a group using a generated 8-character code.
* **Request Body:**
    ```json
    {
      "invite_code": "A1B2C3D4"
    }
    ```

### Add Friend to Group Directly
* **URL:** `POST /groups/:id/members`
* **Function:** Adds an accepted friend directly to the group without needing an invite code.
* **Request Body:**
    ```json
    {
      "user_id": "uuid-of-friend"
    }
    ```

### Get Group Members
* **URL:** `GET /groups/:id/members`
* **Function:** Returns all active members of the group.

### Remove Member
* **URL:** `DELETE /groups/:id/members/:userId`
* **Function:** Removes a member. (Requires Admin role or self-removal).

### Archive/Delete Group
* **URL:** `DELETE /groups/:id`
* **Function:** Soft-deletes the group.

---

## 5. Expenses (`/expenses`)

### Create / Save Expense
* **URL:** `POST /expenses`
* **Function:** Records a new expense. For Offline-First, the frontend should generate and pass the `id`. For P2P expenses (no group), omit the `group_id`. Includes optional support for receipt processing tracking via `receipt_url` and `parsed_items`.
* **Request Body Example (Standard / P2P / Offline-First):**
    ```json
    {
      "id": "generated-uuid-by-client", // Optional
      "group_id": "uuid-of-group",      // Optional (omit for P2P)
      "amount": 1000,
      "description": "Dinner",
      "category": "food",               // Optional
      "split_mode": "equal",            // 'equal', 'exact', 'percentage', 'chaos_roulette'
      "splits": [
        { "user_id": "user1-id" },
        { "user_id": "user2-id" }
      ]
    }
    ```
* **Request Body Example (With Receipt Attachment Confirmation):**
    ```json
    {
      "id": "a3bb98d2-441a-4d92-9335-bf4788c2be0f",
      "group_id": "<YOUR_GROUP_ID>",
      "amount": 1450,
      "description": "Dinner at Roadhouse",
      "split_mode": "exact",
      "splits": [
        { "user_id": "<YOUR_USER_ID>", "amount": 750 },
        { "user_id": "<FRIEND_USER_ID>", "amount": 700 }
      ],
      "receipt_url": "[https://your-supabase-bucket.supabase.co/storage/v1/object/public/receipts/roadhouse_dinner.jpg](https://your-supabase-bucket.supabase.co/storage/v1/object/public/receipts/roadhouse_dinner.jpg)",
      "parsed_items": [
        {
          "name": "Margarita Pizza",
          "quantity": 1,
          "unit_price": 750.00,
          "line_total": 750.00
        },
        {
          "name": "Everest Beer",
          "quantity": 2,
          "unit_price": 350.00,
          "line_total": 700.00
        }
      ]
    }
    ```
* **Response:** Returns the saved expense and its splits.

### Get Expenses
* **URL:** `GET /expenses?groupId=xxx`
* **Function:** Gets all expenses for a group. Omit `groupId` query parameter to get all P2P expenses involving the user.
* **Response:** Array of expense objects including their `expense_splits`.

### Update Expense
* **URL:** `PATCH /expenses/:id`
* **Function:** Edits an expense (only allowed by the creator). Uses `version` for offline conflict resolution.
* **Request Body:**
    ```json
    {
      "description": "Updated Dinner",
      "version": 2,
      "is_deleted": false
    }
    ```

---

## 6. Receipt Processing Verification (`/expenses`)

### Parse via Public Image URL
* **URL:** `POST /expenses/parse-receipt`
* **Function:** The backend downloads the receipt image from the provided public URL (e.g., uploaded to Supabase Storage by a mobile client), sends it base64-encoded to Claude, and returns structured JSON items.
* **Request Body:**
    ```json
    {
      "imageUrl": "[https://raw.githubusercontent.com/tesseract-ocr/tesseract/main/testing/eurotext.png](https://raw.githubusercontent.com/tesseract-ocr/tesseract/main/testing/eurotext.png)"
    }
    ```
* **Expected Result:** A structured JSON object containing parsed line items from the image.

---

## 7. Settlements (`/settlements`)

### Record Settlement
* **URL:** `POST /settlements`
* **Function:** Records a payment from one user to another. Omit `group_id` for P2P settlements.
* **Request Body:**
    ```json
    {
      "id": "generated-uuid-by-client", // Optional
      "group_id": "uuid-of-group",      // Optional (omit for P2P)
      "payer_id": "user-paying-id",
      "payee_id": "user-receiving-id",
      "amount": 500,
      "status": "confirmed",            // 'pending', 'confirmed', 'rejected'
      "esewa_transaction_id": "00P4F2"  // Optional
    }
    ```

### Get Settlements
* **URL:** `GET /settlements?groupId=xxx`
* **Function:** Gets all settlements for a group, or P2P settlements if `groupId` is omitted.
* **Response:** Array of settlements.

---

## 8. Balances & Optimization (`/balances`)

### Get Raw Group Balances
* **URL:** `GET /balances/groups/:id`
* **Function:** Gets the raw total balance of each user in a group (e.g. +500, -250, -250).
* **Response:**
    ```json
    [
      {
        "userId": "uuid",
        "displayName": "John",
        "netBalance": 500
      }
    ]
    ```

### Get Optimized Settlements (Greedy Algorithm)
* **URL:** `GET /balances/groups/:id/optimized`
* **Function:** Runs the greedy algorithm to determine exactly who should pay whom to settle all debts with the minimum number of transactions.
* **Response:**
    ```json
    [
      {
        "payerId": "uuid-1",
        "payerName": "Alice",
        "payeeId": "uuid-2",
        "payeeName": "Bob",
        "amount": 250
      }
    ]
    ```