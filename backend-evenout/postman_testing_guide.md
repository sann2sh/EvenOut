# EvenOut Backend — Postman Testing Guide

Awesome! Now that you have your JWT access token from Google, you can act as the authenticated user and test the entire backend flow. 

Here is your step-by-step journey through the EvenOut Ledger Engine:

---

## Pre-requisites (Postman Setup)

1. Open Postman.
2. In the top right, look for the **Environment Quick Look** (the eye icon) or create a New Environment.
3. Add a variable called `token` and paste your long JWT token as the value.
4. Add a variable called `baseUrl` and set it to `http://localhost:3000/api/v1`.
5. Create a new Request, go to the **Authorization** tab, select **Bearer Token**, and set the Token field to `{{token}}`. (You can set this at the Collection level so all requests inherit it).

---

## 1. Verify Your Profile (Users Module)

Since you just logged in via Google for the first time, our Supabase trigger automatically created a row in the `public.users` table for you! Let's check it.

**Request:** `GET {{baseUrl}}/users/me`

**Expected Result:** You should see your ID, email, name, avatar, and your `split_score` which is now successfully `0`! 
*Copy your `id` from the response. We will need it later.*

---

## 2. Create a Group (Groups Module)

Let's create a trip for you and your friends.

**Request:** `POST {{baseUrl}}/groups`
**Body (JSON):**
```json
{
  "name": "Pokhari Trip",
  "description": "Weekend getaway to Pokhara"
}
```

**Expected Result:** It will return the new group object, including the generated `invite_code` and `invite_qr_url`. *Copy the group `id`!*

---

## 3. Add a Friend (Friendships Module)

To add expenses, you need friends or group members. Normally, another user would log in, but since you are testing alone right now, let's just create a dummy friend directly in the database!

Go to your **Supabase Dashboard** -> **Table Editor** -> **users**.
Click **Insert Row** and add a fake user:
- `id`: *Generate a random UUID online* (e.g., `550e8400-e29b-41d4-a716-446655440000`)
- `email`: `friend@test.com`
- `display_name`: `Fake Friend`

Now, back in Postman, send them a friend request:

**Request:** `POST {{baseUrl}}/friendships/requests`
**Body (JSON):**
```json
{
  "addressee_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

*Note: Since you can't log in as them to accept the request right now, you can manually change the `status` from `pending` to `accepted` in the Supabase Table Editor under `friendships`!*

---

## 4. Add the Friend to Your Group

Go to **Supabase Dashboard** -> **Table Editor** -> **group_members**.
Insert a row:
- `group_id`: *Your group ID from Step 2*
- `user_id`: *Your friend's ID*
- `role`: `member`

---

## 5. Add a Group Expense (Expenses Module)

You paid Rs. 1000 for dinner on the Pokhari Trip. Let's split it equally.

**Request:** `POST {{baseUrl}}/expenses`
**Body (JSON):**
```json
{
  "id": "e30e50d8-6912-4f81-8124-ae3627a9addf",
  "group_id": "<YOUR_GROUP_ID>",
  "amount": 1000,
  "description": "Dinner at Lakeside",
  "split_mode": "equal",
  "splits": [
    { "user_id": "<YOUR_USER_ID>" },
    { "user_id": "<FRIEND_USER_ID>" }
  ]
}
```

**Expected Result:** The backend will automatically calculate that you owe 500 and your friend owes 500, and insert it into `expense_splits`!

---

## 6. Check the Balances (Balances Module)

Now, let's consult the Ledger Engine and run the Greedy Algorithm.

**Request:** `GET {{baseUrl}}/balances/groups/<YOUR_GROUP_ID>/optimized`

**Expected Result:** It should calculate that your friend owes you Rs. 500!
```json
[
  {
    "payerId": "<FRIEND_USER_ID>",
    "payerName": "Fake Friend",
    "payeeId": "<YOUR_USER_ID>",
    "payeeName": "Your Name",
    "amount": 500
  }
]
```

---

## 7. Record a Settlement (Settlements Module)

Your friend pays you back Rs. 500 via eSewa!

**Request:** `POST {{baseUrl}}/settlements`
**Body (JSON):**
```json
{
  "id": "f5b8c9d2-741a-4f92-9335-bf4788c2be0f",
  "group_id": "<YOUR_GROUP_ID>",
  "payer_id": "<FRIEND_USER_ID>",
  "payee_id": "<YOUR_USER_ID>",
  "amount": 500,
  "status": "confirmed",
  "esewa_transaction_id": "000P3A2"
}
```

---

## 8. Check Balances Again

Run Step 6 again (`GET {{baseUrl}}/balances/groups/<YOUR_GROUP_ID>/optimized`).
**Expected Result:** The array will be empty `[]` because everyone is settled up! The `peer_balances` view dynamically calculated that the debt is gone!




## 9. Add friends to groups

Run Step 6 again (`GET {{baseUrl}}/balances/groups/<YOUR_GROUP_ID>/optimized`).
**Expected Result:** The array will be empty `[]` because everyone is settled up! The `peer_balances` view dynamically calculated that the debt is gone!


1. Sign Up (Register)
POST {{baseUrl}}/auth/signup Body (JSON):

```json
{
  "email": "hello@example.com",
  "password": "supersecretpassword",
  "display_name": "John Doe"
}

```
Note: This automatically triggers your database trigger to insert the user into the public.users table!

2. Log In
POST {{baseUrl}}/auth/login Body (JSON):


```json
{
  "email": "hello@example.com",
  "password": "supersecretpassword"
}
```

Returns:

```json
{
  "message": "Login successful",
  "access_token": "eyJhbGciOiJIUzI1Ni...",
  "refresh_token": "v09pI...",
  "user": { ... }
}
```
You can take the access_token returned by the login endpoint and use it in Postman for all your other requests!



