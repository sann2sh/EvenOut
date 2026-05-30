# EvenOut — Receipt OCR Testing Guide (Postman)

This guide walks you through testing the **Intelligent OCR Bill Scanning** engine (Feature 5) in your local backend server using **Postman**. 

To make development and testing incredibly smooth, the backend supports **both** uploading a local file directly and sending a public image URL.

---

## 1. Prerequisites (Setup Your API Key)

Before starting the server, you need to configure your Anthropic API key:
1. Open or create the `.env` file in the root of `/backend-evenout`.
2. Add your API key like so:
   ```env
   ANTHROPIC_API_KEY=your_actual_anthropic_claude_api_key_here
   ```
3. Start your NestJS development server:
   ```bash
   npm run start:dev
   ```

---

## 2. Authenticate in Postman

The OCR endpoint is secure and requires a user token (just like the rest of the ledger endpoints).
1. Send a request to sign up or log in:
   - **Request**: `POST {{baseUrl}}/auth/login` (or signup if you haven't registered)
   - **Body (JSON)**:
     ```json
     {
       "email": "your_email@example.com",
       "password": "yourpassword"
     }
     ```
2. Copy the `access_token` returned in the response.
3. In Postman, go to your environment variables (or collection properties) and set `token` to the value of this JWT access token.
4. Verify that your requests have **Authorization** set to **Bearer Token** with value `{{token}}` (or `{{access_token}}`).

---

## 3. Test Case A: Parse via Local File Upload (Highly Recommended)

*This is the easiest way to test! You can upload any receipt image file sitting on your computer directly through Postman.*

1. Create a new request in Postman:
   - **Method**: `POST`
   - **URL**: `{{baseUrl}}/expenses/parse-receipt`
   - **Auth**: `Bearer Token` -> `{{token}}`
2. Select the **Body** tab:
   - Choose **form-data**.
   - In the **Key** field, type `file`.
   - Hover over the right-side of the `file` key input and click the dropdown that appears. Change it from **Text** to **File**.
   - Click **Select Files** in the Value column and choose a sample receipt image from your machine (PNG, JPEG, WEBP, or GIF).
3. **Leave the JSON/URL body completely empty**.
4. Click **Send**!

### Expected Result
You should receive a clean, fully parsed JSON object with a status code of `201 Created`:
```json
{
  "receipt_type": "restaurant",
  "merchant": "Roadhouse Cafe",
  "date": "2026-05-30",
  "total": 1450.00,
  "items": [
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
  ],
  "payment_method": "fonepay",
  "bill_number": "INV-88902",
  "confidence": "high"
}
```

---

## 4. Test Case B: Parse via Public Image URL

*This mirrors exactly what the mobile app does when uploading to Supabase Storage first and sending the URL to NestJS.*

1. Create a new request in Postman:
   - **Method**: `POST`
   - **URL**: `{{baseUrl}}/expenses/parse-receipt`
   - **Auth**: `Bearer Token` -> `{{token}}`
2. Select the **Body** tab:
   - Choose **raw** and set the format to **JSON**.
   - Provide the public URL of the receipt image:
     ```json
     {
       "imageUrl": "https://raw.githubusercontent.com/tesseract-ocr/tesseract/main/testing/eurotext.png"
     }
     ```
3. Click **Send**!

### Expected Result
The backend downloads the image from the URL, sends it base64-encoded to Claude, and returns the structured JSON of items.

---

## 5. Test Case C: Save Expense with Receipt Attachment

After parsing the receipt, the user assigns the dishes/items on the UI and confirms the expense. When saving, the client submits the expense along with the `receipt_url` and `parsed_items`.

1. Create a new request in Postman:
   - **Method**: `POST`
   - **URL**: `{{baseUrl}}/expenses`
   - **Auth**: `Bearer Token` -> `{{token}}`
2. Select the **Body** tab -> **raw (JSON)**:
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
     "receipt_url": "https://your-supabase-bucket.supabase.co/storage/v1/object/public/receipts/roadhouse_dinner.jpg",
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
3. Click **Send**!

### Verify in Database
Go to your **Supabase Dashboard** -> **Table Editor** -> **receipts**.
You will see that a row has been successfully created/updated:
- `expense_id`: Associated with the newly created expense `a3bb98d2-441a-4d92-9335-bf4788c2be0f`.
- `public_url`: Correctly saved.
- `ocr_status`: Marked as `'completed'`.
- `parsed_line_items`: Holds the JSON array of individual pizza and beer items!
