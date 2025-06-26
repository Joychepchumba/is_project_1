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

# --- LEGAL PROVIDERS ---

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

        return {
            "total": len(total_result.data or []),
            "pending": len(pending_result.data or [])
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching stats: {str(e)}")


# --- SAFETY TIPS ---

@router.get("/safety_tips")
def get_safety_tips():
    result = supabase.table("safety_tips").select("*").order("created_at", desc=True).execute()
    return result.data


@router.put("/safety_tips/{tip_id}")
def update_safety_tip(tip_id: int, body: dict):
    status = body.get('status')

    if status not in ["pending", "verified", "false", "deleted"]:
        return {"error": f"Invalid status: {status}"}, 400

    # Soft update the status field
    supabase.table("safety_tips").update({"status": status}).eq("id", tip_id).execute()
    return {"message": f"Tip status set to {status}"}



# --- ANALYTICS OVERVIEW ---

@router.get("/analytics/overview")
def get_analytics_overview():
    try:
        # Users and Providers
        users = supabase.table("users").select("*", count="exact").execute()
        providers = supabase.table("legal_aid_providers").select("*", count="exact").execute()

        # Safety Tips
        tips = supabase.table("safety_tips").select("*", count="exact").execute()
        tips_verified = supabase.table("safety_tips").select("*", count="exact").eq("status", "verified").execute()
        tips_pending = supabase.table("safety_tips").select("*", count="exact").eq("status", "pending").execute()

        submitters = {
            tip.get("submitted_by") for tip in tips.data if tip.get("submitted_by")
        }

        # Top Danger Zones
        danger_zones = supabase.table("danger_zones") \
            .select("location_name, reported_count") \
            .order("reported_count", desc=True) \
            .limit(5) \
            .execute()

        # Revenue: total, top content, recent
        purchases = supabase.table("purchases") \
            .select("purchased_at, educational_content(title, price)") \
            .order("purchased_at", desc=True) \
            .limit(20) \
            .execute()

        total_revenue = 0.0
        top_content = defaultdict(float)
        recent_purchases = []

        for p in purchases.data:
            try:
                dt = datetime.fromisoformat(p["purchased_at"])
                content = p.get("educational_content", {})
                title = content.get("title", "Unknown")
                price = float(content.get("price", 0))

                total_revenue += price
                top_content[title] += price

                recent_purchases.append({
                    "date": dt.strftime("%b %d"),
                    "title": title,
                    "amount": int(price)
                })

            except Exception:
                continue

        top_content_sorted = sorted(top_content.items(), key=lambda x: x[1], reverse=True)[:5]
        top_content_data = [{"title": k, "total": int(v)} for k, v in top_content_sorted]

        return {
            "users": len(users.data or []),
            "providers": len(providers.data or []),
            "admins": 1,
            "tips_total": len(tips.data or []),
            "tips_verified": len(tips_verified.data or []),
            "tips_pending": len(tips_pending.data or []),
            "tips_submitters": len(submitters),
            "danger_zones": danger_zones.data or [],
            "total_revenue": int(total_revenue),
            "top_content": top_content_data,
            "recent_purchases": recent_purchases
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching analytics: {str(e)}")