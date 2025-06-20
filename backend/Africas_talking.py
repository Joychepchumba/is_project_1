# Africa's Talking Service
import os

from fastapi import HTTPException, logger
import httpx
import logging
logger = logging.getLogger(__name__)
class AfricasTalkingService:
    def __init__(self):
        self.username = os.getenv("AFRICAS_TALKING_USERNAME", "sandbox")
        self.api_key = os.getenv("AFRICAS_TALKING_API_KEY")
        self.sender_id = os.getenv("AFRICAS_TALKING_SENDER_ID")
        self.base_url = os.getenv("AFRICAS_TALKING_BASE_URL", "https://api.africastalking.com")
        
        if not self.api_key:
            logger.error("AFRICAS_TALKING_API_KEY not set in environment variables")
    
    def format_phone_number(self, phone_number: str) -> str:
        """Format phone number to international format (+254...)"""
        # Remove non-digit characters
        phone_number = ''.join(filter(str.isdigit, phone_number))
        
        # Add Kenya country code if not present
        if not phone_number.startswith('254'):
            if phone_number.startswith('0'):
                phone_number = '254' + phone_number[1:]
            else:
                phone_number = '254' + phone_number
        
        return '+' + phone_number
    
    async def send_sms(self, phone_number: str, message: str) -> dict:
        """Send SMS via Africa's Talking API"""
        try:
            formatted_number = self.format_phone_number(phone_number)
            
            url = self.base_url
            
            data = {
                "username": self.username,
                "to": formatted_number,
                "message": message,
            }
            
            if self.sender_id:
                data["from"] = self.sender_id
            
            headers = {
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded",
                "apiKey": self.api_key
            }
            
            async with httpx.AsyncClient() as client:
                response = await client.post(url, data=data, headers=headers)
                response.raise_for_status()
                
                result = response.json()
                
                logger.info(f"SMS sent successfully to {formatted_number}")
                return result
                
        except Exception as e:
            logger.error(f"Failed to send SMS to {phone_number}: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Failed to send SMS: {str(e)}"
            )
        

# Initialize services
sms_service = AfricasTalkingService()