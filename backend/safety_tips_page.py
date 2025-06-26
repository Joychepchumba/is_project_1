from fastapi import APIRouter, HTTPException, Path
from pydantic import BaseModel
from supabase import create_client, Client
from fastapi.responses import RedirectResponse
import traceback

# Supabase credentials
SUPABASE_URL = "https://ngfpaioekpicyvocxsbn.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nZnBhaW9la3BpY3l2b2N4c2JuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyNDA1MTgsImV4cCI6MjA2NDgxNjUxOH0.PcSVIRhmbVRN2vPG4yWfqjDsyP_tw_V3oBtL8UZot0I"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Create router
router = APIRouter(tags=["Safety Tips & Educational Content"])

# Models
class SafetyTip(BaseModel):
    title: str
    content: str
    category: str
    submitted_by: str
    submitted_by_role: str = "user"
    status: str = "pending"

class EducationalContent(BaseModel):
    title: str
    content: str
    category: str
    price: float
    is_paid: bool = True
    uploaded_by: str

class CapturePayment(BaseModel):
    user_id: str
    content_id: str

# GET: Safety tips
@router.get("/get_tips")
def get_tips():
    try:
        response = (
            supabase.table("safety_tips")
            .select("*")
            .order("created_at", desc=True)
            .execute()
        )
        if response.data:
            return response.data
        raise HTTPException(status_code=404, detail="No safety tips found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving tips: {str(e)}")

# GET: Educational content
@router.get("/get_educational_content")
def get_educational_content():
    try:
        response = (
            supabase.table("educational_content")
            .select("*")
            .order("created_at", desc=True)
            .execute()
        )
        if response.data:
            return response.data
        raise HTTPException(status_code=404, detail="No educational content found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving educational content: {str(e)}")

# POST: Upload safety tip
@router.post("/upload_tip")
def upload_tip(tip: SafetyTip):
    try:
        if not tip.title or not tip.content or not tip.category:
            raise HTTPException(status_code=400, detail="Title, content, and category are required")

        user_check = (
            supabase.table("users")
            .select("id")
            .eq("id", tip.submitted_by)
            .maybe_single()
            .execute()
        )
        if not user_check.data:
            raise HTTPException(status_code=404, detail="User not found")

        supabase.table("safety_tips").insert(tip.dict()).execute()
        return {"message": "Tip uploaded successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error uploading tip: {str(e)}")

# Simulated PayPal checkout redirect
@router.get("/paypal_checkout")
def paypal_checkout(user_id: str, content_id: str):
    paypal_url = f"https://www.sandbox.paypal.com/checkoutnow?user_id={user_id}&content_id={content_id}"
    return RedirectResponse(paypal_url)

# GET: Purchases for a user
@router.get("/user_purchases/{user_id}")
def get_user_purchases(user_id: str):
    try:
        response = (
            supabase.table("purchases")
            .select("content_id")
            .eq("user_id", user_id)
            .execute()
        )
        content_ids = [entry["content_id"] for entry in response.data]
        return {"purchased_ids": content_ids}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching purchases: {str(e)}")

# ✅ POST: Capture PayPal payment and record purchase
@router.post("/capture-order/{order_id}")
def capture_order(order_id: str = Path(...), payload: CapturePayment = ...):
    try:
        print(f"[DEBUG] Capturing order ID: {order_id}")
        print(f"[DEBUG] user_id: {payload.user_id}, content_id: {payload.content_id}")

        result = supabase.table("purchases").insert({
            "user_id": payload.user_id,
            "content_id": payload.content_id
        }).execute()

        print(f"[DEBUG] Supabase insert result: {result}")
        return {"message": "Payment recorded"}
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error capturing payment: {str(e)}")
