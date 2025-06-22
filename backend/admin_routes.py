from fastapi import APIRouter, HTTPException
from supabase import create_client, Client

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