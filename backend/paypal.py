from fastapi import APIRouter, HTTPException, Request
import requests
from supabase import create_client, Client

paypal_router = APIRouter(tags=["Payments"])

# PayPal sandbox credentials
PAYPAL_CLIENT_ID = "AbwGuuy79yh2NStNQwFBMCro4VVt_UhszJCmvsshxsEwUO-nUPb7B710_Fvcz4HN2deCEcrY5AohK-zI"
PAYPAL_SECRET = "EJYGRwweIqjtIM9DIlx0b5lLfy-4NBJlZzP3fXx1HtyWmi6DDtL2cwWDjYZNI6EOYe397eX2gXkf0g3O"
PAYPAL_BASE = "https://api-m.sandbox.paypal.com"

# Supabase credentials
SUPABASE_URL = "https://ngfpaioekpicyvocxsbn.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nZnBhaW9la3BpY3l2b2N4c2JuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyNDA1MTgsImV4cCI6MjA2NDgxNjUxOH0.PcSVIRhmbVRN2vPG4yWfqjDsyP_tw_V3oBtL8UZot0I"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Get PayPal Access Token
def get_paypal_token():
    response = requests.post(
        f"{PAYPAL_BASE}/v1/oauth2/token",
        auth=(PAYPAL_CLIENT_ID, PAYPAL_SECRET),
        headers={"Accept": "application/json"},
        data={"grant_type": "client_credentials"},
    )
    print("PayPal Token Response Status:", response.status_code)
    print("PayPal Token Response Text:", response.text)

    if response.status_code != 200:
        raise HTTPException(status_code=500, detail="Failed to get PayPal token")
    return response.json()["access_token"]

# Create PayPal order
@paypal_router.post("/create-order")
def create_paypal_order(payload: dict):
    user_id = payload.get("user_id")
    content_id = payload.get("content_id")
    content_title = payload.get("content_title")
    amount = payload.get("amount")
    currency = payload.get("currency", "USD")

    if not all([user_id, content_id, content_title, amount]):
        raise HTTPException(status_code=400, detail="Missing required payment details")

    try:
        formatted_amount = f"{float(amount):.2f}"
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid amount format")

    token = get_paypal_token()
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    body = {
        "intent": "CAPTURE",
        "purchase_units": [{
            "amount": {
                "currency_code": currency,
                "value": formatted_amount
            },
            "description": f"Unlock: {content_title} (Content ID: {content_id})"
        }],
        "application_context": {
            "brand_name": "Safety App",
            "landing_page": "NO_PREFERENCE",
            "user_action": "PAY_NOW",
            "return_url": "https://example.com/payment-success",
            "cancel_url": "https://example.com/payment-cancelled"
        }
    }

    response = requests.post(f"{PAYPAL_BASE}/v2/checkout/orders", headers=headers, json=body)

    print("PayPal Order Create Status Code:", response.status_code)
    print("PayPal Order Create Response:", response.text)

    if response.status_code != 201:
        raise HTTPException(status_code=500, detail=f"PayPal error: {response.text}")

    order = response.json()
    approval_url = next((link["href"] for link in order["links"] if link["rel"] == "approve"), None)

    return {
        "order_id": order["id"],
        "approval_url": approval_url
    }

# Capture PayPal payment
@paypal_router.post("/capture-order/{order_id}")
async def capture_order(order_id: str, request: Request):
    token = get_paypal_token()
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    response = requests.post(
        f"{PAYPAL_BASE}/v2/checkout/orders/{order_id}/capture",
        headers=headers
    )

    print("Capture Status Code:", response.status_code)
    print("Capture Response:", response.text)

    if response.status_code != 201:
        raise HTTPException(
            status_code=500,
            detail=f"Payment capture failed: {response.text}"
        )

    purchase_data = response.json()

    try:
        body = await request.json()
        user_id = body.get("user_id")
        content_id = body.get("content_id")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid request body")

    if not user_id or not content_id:
        raise HTTPException(status_code=400, detail="Missing user_id or content_id")

    try:
        supabase.table("purchases").insert({
            "user_id": user_id,
            "content_id": content_id,
        }).execute()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to record purchase: {str(e)}")

    return {
        "message": "Payment successful",
        "paypal_response": purchase_data
    }
    