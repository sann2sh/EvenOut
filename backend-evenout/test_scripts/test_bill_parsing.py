import anthropic
import json
import sys
import base64
from pathlib import Path

# ─── Config ───────────────────────────────────────────────────────────────────
ANTHROPIC_API_KEY = "[API KEY]"  # Replace with your Anthropic API key
# Get it from: https://console.anthropic.com/
# ──────────────────────────────────────────────────────────────────────────────

client = anthropic.Anthropic(api_key=ANTHROPIC_API_KEY)

PROMPT = """
You are a receipt parser for a Nepali expense splitting app.
Extract data from this receipt image and return ONLY a valid JSON object.
No explanation. No markdown. No extra text.

{
  "receipt_type": "restaurant | supermarket | esewa | vat_bill | handwritten | other",
  "merchant": "store or restaurant name or null",
  "date": "YYYY-MM-DD or null",
  "total": 0.00,
  "items": [
    {
      "name": "item name",
      "quantity": 1,
      "unit_price": 0.00,
      "line_total": 0.00
    }
  ],
  "payment_method": "cash | card | esewa | fonepay | bank_transfer | null",
  "bill_number": "invoice or bill number or null",
  "confidence": "high | medium | low"
}

Rules:
- Return null for any field not found, never guess
- total = final payable amount (after tax, discount, service charge)
- unit_price = price of ONE item, line_total = unit_price × quantity
- currency always NPR unless clearly stated otherwise
- confidence = high if image is clear and all fields readable
              = medium if some fields are unclear or partially visible
              = low if image is blurry, handwritten, or heavily damaged
- For eSewa/Khalti screenshots: merchant is the recipient name
- bill_number helps detect duplicate scans
"""


def parse_receipt(image_path: str) -> dict:
    """
    Send receipt image to Claude and get structured JSON back.

    Args:
        image_path: Path to the receipt image (jpg, png, webp, gif)

    Returns:
        Parsed receipt as a Python dict
    """
    path = Path(image_path)

    if not path.exists():
        raise FileNotFoundError(f"Image not found: {image_path}")

    # Load and base64-encode the image (required by Anthropic API)
    with open(path, "rb") as f:
        image_data = base64.standard_b64encode(f.read()).decode("utf-8")

    # Detect mime type from extension
    ext = path.suffix.lower()
    mime_map = {
        ".jpg":  "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png":  "image/png",
        ".webp": "image/webp",
        ".gif":  "image/gif",
    }
    media_type = mime_map.get(ext, "image/jpeg")

    print(f"📷 Sending image to Claude: {path.name}")

    # Call Claude Vision
    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": media_type,
                            "data": image_data,
                        },
                    },
                    {
                        "type": "text",
                        "text": PROMPT,
                    },
                ],
            }
        ],
    )

    raw_text = response.content[0].text.strip()

    # Strip markdown code fences if Claude adds them
    if raw_text.startswith("```"):
        raw_text = raw_text.split("```")[1]
        if raw_text.startswith("json"):
            raw_text = raw_text[4:]
        raw_text = raw_text.strip()

    parsed = json.loads(raw_text)
    return parsed


def display_result(data: dict):
    """Pretty print the parsed receipt."""
    print("\n" + "═" * 40)
    print("  PARSED RECEIPT")
    print("═" * 40)
    print(f"  Merchant  : {data.get('merchant', 'N/A')}")
    print(f"  Date      : {data.get('date', 'N/A')}")
    print(f"  Currency  : {data.get('currency', 'N/A')}")
    print(f"  Payment   : {data.get('payment_method', 'N/A')}")
    print(f"  Tax       : {data.get('tax', 0)}")
    print(f"  Total     : {data.get('total', 'N/A')}")

    items = data.get("items", [])
    if items:
        print("\n  Items:")
        for item in items:
            name  = item.get("name", "?")
            qty   = item.get("quantity", 1)
            price = item.get("price", 0)
            print(f"    - {name} x{qty}  →  {price}")

    print("═" * 40)
    print("\n  Raw JSON:")
    print(json.dumps(data, indent=2, ensure_ascii=False))


# ─── Main ─────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    # Usage: python receipt_ocr.py path/to/receipt.jpg
    # Or just hardcode a path below for quick testing

    if len(sys.argv) > 1:
        image_path = sys.argv[1]
    else:
        image_path = "test1.jpg"  # Put your test receipt image here

    try:
        result = parse_receipt(image_path)
        display_result(result)

    except FileNotFoundError as e:
        print(f"❌ {e}")
        print("   Usage: python receipt_ocr.py path/to/receipt.jpg")

    except json.JSONDecodeError as e:
        print(f"❌ Claude returned non-JSON output: {e}")

    except Exception as e:
        print(f"❌ Error: {e}")
