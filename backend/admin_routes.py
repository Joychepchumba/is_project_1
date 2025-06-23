from fastapi import APIRouter, HTTPException
from supabase import create_client, Client
from datetime import datetime
from collections import defaultdict

# Initialize router
router = APIRouter(tags=["Admin - Legal Aid Verification"])

# Supabase credentials
SUPABASE_URL = "https://ngfpaioekpicyvocxsbn.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nZnBhaW9la3BpY3l2b2N4c2JuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyNDA1MTgsImV4cCI6MjA2NDgxNjUxOH0.PcSVIRhmbVRN2vPG4yWfqjDsyP_tw_V3oBtL8UZot0I"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Get all pending legal aid providers
@router.get("/pending_providers")
def get_pending_providers():
    try:
        response = (
            supabase.table("legal_aid_providers")
            .select("*, legal_provider_expertise(expertise_areas(name))")
            .neq("status", "verified")
            .execute()
        )
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching providers: {str(e)}")

# Mark a provider as verified
@router.put("/verify_provider/{provider_id}")
def verify_provider(provider_id: str):
    try:
        supabase.table("legal_aid_providers").update(
            {"status": "verified"}
        ).eq("id", provider_id).execute()
        return {"message": "Provider verified"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error verifying provider: {str(e)}")

@router.get("/provider_stats")
def get_provider_stats():
    try:
        total_result = supabase.table("legal_aid_providers").select("*", count="exact").execute()
        pending_result = supabase.table("legal_aid_providers").select("*", count="exact").eq("status", "pending").execute()

        total_count = len(total_result.data) if total_result.data else 0
        pending_count = len(pending_result.data) if pending_result.data else 0


        return {
            "total": total_count,
            "pending": pending_count
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching stats: {str(e)}")
    

# Moderate_safety_tips_pages routes
@router.get("/safety_tips")
def get_safety_tips():
    result = supabase.table("safety_tips") \
        .select("*") \
        .order("created_at", desc=True) \
        .execute()
    return result.data

@router.put("/safety_tips/{tip_id}")
def update_safety_tip(tip_id: int, body: dict):
    status = body.get('status')
    if status == "delete":
        supabase.table("safety_tips").delete().eq("id", tip_id).execute()
        return {"message": "Tip deleted"}
    else:
        supabase.table("safety_tips").update({"status": status}).eq("id", tip_id).execute()
        return {"message": f"Tip status set to {status}"}
    

# Analytics routes
@router.get("/analytics/overview")
def get_analytics_overview():
    try:
        print("Fetching users...")
        users = supabase.table("users").select("*", count="exact").execute()

        print("Fetching legal aid providers...")
        providers = supabase.table("legal_aid_providers").select("*", count="exact").execute()

        print("Fetching safety tips...")
        tips = supabase.table("safety_tips").select("*", count="exact").execute()
        tips_verified = supabase.table("safety_tips").select("*", count="exact").eq("status", "verified").execute()

        print("Fetching danger zones...")
        danger_zones = supabase.table("danger_zones") \
            .select("location_name, reported_count") \
            .order("reported_count", desc=True) \
            .limit(5) \
            .execute()

        print("Fetching purchases with price join...")
        purchases = supabase.table("purchases") \
            .select("purchased_at, educational_content(price)") \
            .execute()

        print("Processing purchases for revenue chart...")
        monthly_totals = defaultdict(float)

        for p in purchases.data:
            try:
                dt = datetime.fromisoformat(p["purchased_at"])
                price = p.get("educational_content", {}).get("price", 0)
                key = dt.strftime("%b-%y")  # e.g. "Jun-25"
                monthly_totals[key] += float(price) / 1000  # convert to thousands
            except Exception as e:
                print(f"Skipping purchase due to error: {e}")
                continue

        sorted_months = sorted(monthly_totals.items())
        revenue_data = [{"month": k, "total": v} for k, v in sorted_months]

        print("Returning data to frontend...")
        return {
            "users": len(users.data),
            "providers": len(providers.data),
            "admins": 1,  # or make dynamic if needed
            "tips_total": len(tips.data),
            "tips_verified": len(tips_verified.data),
            "danger_zones": danger_zones.data or [],
            "monthly_revenue": revenue_data
        }

    except Exception as e:
        print("ERROR OCCURRED:", str(e))
        raise HTTPException(status_code=500, detail=f"Error fetching stats: {str(e)}")