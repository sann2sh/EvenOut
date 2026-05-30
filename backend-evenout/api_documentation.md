# EvenOut Backend API Documentation

Base URL for all endpoints: `http://localhost:3000/api/v1` (for local development)

**Authentication:** 
Almost all endpoints require a Bearer token in the Authorization header. 
Header: `Authorization: Bearer <your_jwt_access_token>`

---

## 1. Authentication (`/auth`)

### Sign Up
- **URL:** `POST /auth/signup`
- **Auth Required:** No
- **Function:** Registers a new user with an email and password. Automatically creates their profile in the database.
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "password": "securepassword123",
    "display_name": "John Doe"
  }
  ```
- **Response:** Returns the created user object and a success message.

### Log In
- **URL:** `POST /auth/login`
- **Auth Required:** No
- **Function:** Authenticates the user and returns JWT tokens.
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "password": "securepassword123"
  }
  ```
- **Response:** Returns `access_token`, `refresh_token`, and the user object.

---

## 2. Users (`/users`)

### Get My Profile
- **URL:** `GET /users/me`
- **Function:** Retrieves the currently authenticated user's profile details.
- **Response:** `{ id, email, display_name, avatar_url, split_score, ... }`

### Update My Profile
- **URL:** `PATCH /users/me`
- **Function:** Updates the user's profile details (like display name or avatar).
- **Request Body:**
  ```json
  {
    "display_name": "New Name",
    "avatar_url": "https://...",
    "fcm_token": "device_token"
  }
  ```
- **Response:** Returns the updated user object.

### Get User Profile (Public)
- **URL:** `GET /users/:id/profile`
- **Function:** Gets basic public info of another user.

---

## 3. Friendships (`/friendships`)

### Send Friend Request
- **URL:** `POST /friendships/requests`
- **Function:** Sends a friend request to another user.
- **Request Body:**
  ```json
  {
    "addressee_id": "uuid-of-friend"
  }
  ```
- **Response:** Returns the created friendship record (status: pending).

### Get Friends
- **URL:** `GET /friendships`
- **Function:** Gets a list of all accepted friends for the current user.
- **Response:** Array of user objects.

### Get Pending Requests
- **URL:** `GET /friendships/requests`
- **Function:** Gets all pending incoming friend requests.
- **Response:** Array of friendship request objects.

### Respond to Request
- **URL:** `PATCH /friendships/requests/:id`
- **Function:** Accepts or declines a friend request. (`:id` is the friendship record ID)
- **Request Body:**
  ```json
  {
    "status": "accepted" // or "declined"
  }
  ```

### Remove Friend
- **URL:** `DELETE /friendships/:id`
- **Function:** Unfriends a user.

---

## 4. Groups (`/groups`)

### Create Group
- **URL:** `POST /groups`
- **Function:** Creates a new ledger group and assigns the creator as an admin.
- **Request Body:**
  ```json
  {
    "name": "Goa Trip",
    "description": "Fun times",
    "currency": "NPR" // Optional
  }
  ```
- **Response:** Group object containing `invite_code` and `invite_qr_url`.

### Get My Groups
- **URL:** `GET /groups`
- **Function:** Retrieves all active groups the user is a part of.
- **Response:** Array of group objects.

### Get Group Details
- **URL:** `GET /groups/:id`
- **Function:** Gets details of a specific group.

### Join Group (via Code)
- **URL:** `POST /groups/join`
- **Function:** Joins a group using a generated 8-character code.
- **Request Body:**
  ```json
  {
    "invite_code": "A1B2C3D4"
  }
  ```

### Add Friend to Group Directly
- **URL:** `POST /groups/:id/members`
- **Function:** Adds an accepted friend directly to the group without needing an invite code.
- **Request Body:**
  ```json
  {
    "user_id": "uuid-of-friend"
  }
  ```

### Get Group Members
- **URL:** `GET /groups/:id/members`
- **Function:** Returns all active members of the group.

### Remove Member
- **URL:** `DELETE /groups/:id/members/:userId`
- **Function:** Removes a member. (Requires Admin role or self-removal).

### Archive/Delete Group
- **URL:** `DELETE /groups/:id`
- **Function:** Soft-deletes the group.

---

## 5. Expenses (`/expenses`)

### Create Expense
- **URL:** `POST /expenses`
- **Function:** Records a new expense. For Offline-First, the frontend should generate and pass the `id`. For P2P expenses (no group), omit the `group_id`.
- **Request Body:**
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
- **Response:** Returns the saved expense and its splits.

### Get Expenses
- **URL:** `GET /expenses?groupId=xxx`
- **Function:** Gets all expenses for a group. Omit `groupId` query parameter to get all P2P expenses involving the user.
- **Response:** Array of expense objects including their `expense_splits`.

### Update Expense
- **URL:** `PATCH /expenses/:id`
- **Function:** Edits an expense (only allowed by the creator). Uses `version` for offline conflict resolution.
- **Request Body:**
  ```json
  {
    "description": "Updated Dinner",
    "version": 2,
    "is_deleted": false
  }
  ```

---

## 6. Settlements (`/settlements`)

### Record Settlement
- **URL:** `POST /settlements`
- **Function:** Records a payment from one user to another. Omit `group_id` for P2P settlements.
- **Request Body:**
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
- **URL:** `GET /settlements?groupId=xxx`
- **Function:** Gets all settlements for a group, or P2P settlements if `groupId` is omitted.
- **Response:** Array of settlements.

---

## 7. Balances & Optimization (`/balances`)

### Get Raw Group Balances
- **URL:** `GET /balances/groups/:id`
- **Function:** Gets the raw total balance of each user in a group (e.g. +500, -250, -250).
- **Response:**
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
- **URL:** `GET /balances/groups/:id/optimized`
- **Function:** Runs the greedy algorithm to determine exactly who should pay whom to settle all debts with the minimum number of transactions.
- **Response:**
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


Endpoint: PATCH https://evenout-ilq1.onrender.com/api/v1/users/me Headers: Authorization: Bearer <your_access_token>

Example 1: Updating EVERYTHING
```
json
{
  "display_name": "Sann2sh",
  "phone_number": "+9779800000000",
  "avatar_url": "https://example.com/my-avatar.png"
}
Example 2: Updating ONLY the Phone Number (Partial Update)
```json
{
  "phone_number": "+9779800000000"
}

```
Notice how you completely leave out display_name and avatar_url? The backend is smart enough to ignore them and leave your existing name and avatar untouched in the database.

Example 3: Updating ONLY the Avatar
```json
{
  "avatar_url": "https://example.com/new-avatar.png"
}
```