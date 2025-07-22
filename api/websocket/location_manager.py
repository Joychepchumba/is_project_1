import datetime
from fastapi import BackgroundTasks, WebSocket, WebSocketDisconnect
from typing import Dict, List, Set
import json
import asyncio
from uuid import UUID
import logging

from requests import Session

from backend.crud import get_current_user
from backend.database import get_db
from backend.models import RealTimeGPSLog
from backend.schema import RealTimeGPSLogCreate, RealTimeGPSLogShow

logger = logging.getLogger(__name__)

class LocationWebSocketManager:
    def __init__(self):
        # Store active connections: {user_id: {connection_id: websocket}}
        self.active_connections: Dict[str, Dict[str, WebSocket]] = {}
        # Store who is tracking whom: {tracked_user_id: set(tracker_connection_ids)}
        self.tracking_relationships: Dict[str, Set[str]] = {}
    
    async def connect(self, websocket: WebSocket, user_id: str, connection_id: str):
        """Accept a new WebSocket connection"""
        await websocket.accept()
        
        if user_id not in self.active_connections:
            self.active_connections[user_id] = {}
        
        self.active_connections[user_id][connection_id] = websocket
        logger.info(f"WebSocket connected: {user_id}:{connection_id}")
        
        # Send connection confirmation
        await self.send_personal_message({
            "type": "connection_established",
            "user_id": user_id,
            "connection_id": connection_id,
            "timestamp": asyncio.get_event_loop().time()
        }, websocket)
    
    def disconnect(self, user_id: str, connection_id: str):
        """Remove a WebSocket connection"""
        if user_id in self.active_connections:
            self.active_connections[user_id].pop(connection_id, None)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        
        # Clean up tracking relationships
        for tracked_user, trackers in self.tracking_relationships.items():
            trackers.discard(f"{user_id}:{connection_id}")
        
        logger.info(f"WebSocket disconnected: {user_id}:{connection_id}")
    
    async def send_personal_message(self, message: dict, websocket: WebSocket):
        """Send a message to a specific WebSocket connection"""
        try:
            await websocket.send_text(json.dumps(message))
        except Exception as e:
            logger.error(f"Error sending personal message: {e}")
    
    async def broadcast_to_user(self, user_id: str, message: dict):
        """Send a message to all connections of a specific user"""
        if user_id in self.active_connections:
            disconnected_connections = []
            
            for connection_id, websocket in self.active_connections[user_id].items():
                try:
                    await websocket.send_text(json.dumps(message))
                except Exception as e:
                    logger.error(f"Error broadcasting to {user_id}:{connection_id}: {e}")
                    disconnected_connections.append(connection_id)
            
            # Clean up disconnected connections
            for connection_id in disconnected_connections:
                self.disconnect(user_id, connection_id)
    
    async def broadcast_location_update(self, user_id: str, location_data: dict):
        """Broadcast location update to all users tracking this user"""
        message = {
            "type": "location_update",
            "user_id": user_id,
            "data": location_data,
            "timestamp": asyncio.get_event_loop().time()
        }
        
        # Send to trackers
        if user_id in self.tracking_relationships:
            for tracker_connection_id in self.tracking_relationships[user_id].copy():
                tracker_user_id, connection_id = tracker_connection_id.split(":", 1)
                
                if (tracker_user_id in self.active_connections and 
                    connection_id in self.active_connections[tracker_user_id]):
                    
                    websocket = self.active_connections[tracker_user_id][connection_id]
                    try:
                        await websocket.send_text(json.dumps(message))
                    except Exception as e:
                        logger.error(f"Error sending location update to tracker {tracker_connection_id}: {e}")
                        self.tracking_relationships[user_id].discard(tracker_connection_id)
    
    def start_tracking(self, tracked_user_id: str, tracker_user_id: str, tracker_connection_id: str):
        """Start tracking a user's location"""
        if tracked_user_id not in self.tracking_relationships:
            self.tracking_relationships[tracked_user_id] = set()
        
        full_tracker_id = f"{tracker_user_id}:{tracker_connection_id}"
        self.tracking_relationships[tracked_user_id].add(full_tracker_id)
        
        logger.info(f"Started tracking: {full_tracker_id} -> {tracked_user_id}")
    
    def stop_tracking(self, tracked_user_id: str, tracker_user_id: str, tracker_connection_id: str):
        """Stop tracking a user's location"""
        if tracked_user_id in self.tracking_relationships:
            full_tracker_id = f"{tracker_user_id}:{tracker_connection_id}"
            self.tracking_relationships[tracked_user_id].discard(full_tracker_id)
            
            if not self.tracking_relationships[tracked_user_id]:
                del self.tracking_relationships[tracked_user_id]
        
        logger.info(f"Stopped tracking: {tracker_user_id}:{tracker_connection_id} -> {tracked_user_id}")
    
    def get_connection_stats(self):
        """Get statistics about active connections"""
        total_connections = sum(len(connections) for connections in self.active_connections.values())
        total_users = len(self.active_connections)
        total_tracking = sum(len(trackers) for trackers in self.tracking_relationships.values())
        
        return {
            "total_connections": total_connections,
            "total_users": total_users,
            "total_tracking_relationships": total_tracking,
            "users_online": list(self.active_connections.keys())
        }

# Global instance
location_ws_manager = LocationWebSocketManager()

# WebSocket endpoints to add to your FastAPI router
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
import uuid

ws_router = APIRouter()

@ws_router.websocket("/ws/location/{user_id}")
async def location_websocket_endpoint(
    websocket: WebSocket, 
    user_id: str,
    # current_user = Depends(get_current_user_ws)  # You'll need to implement WebSocket auth
):
    connection_id = str(uuid.uuid4())
    
    await location_ws_manager.connect(websocket, user_id, connection_id)
    
    try:
        while True:
            # Receive messages from client
            data = await websocket.receive_text()
            message = json.loads(data)
            
            message_type = message.get("type")
            
            if message_type == "location_update":
                # Client is sending location update
                location_data = message.get("data", {})
                await location_ws_manager.broadcast_location_update(user_id, location_data)
                
            elif message_type == "start_tracking":
                # Client wants to start tracking another user
                tracked_user_id = message.get("tracked_user_id")
                if tracked_user_id:
                    location_ws_manager.start_tracking(tracked_user_id, user_id, connection_id)
                    await location_ws_manager.send_personal_message({
                        "type": "tracking_started",
                        "tracked_user_id": tracked_user_id
                    }, websocket)
            
            elif message_type == "stop_tracking":
                # Client wants to stop tracking another user
                tracked_user_id = message.get("tracked_user_id")
                if tracked_user_id:
                    location_ws_manager.stop_tracking(tracked_user_id, user_id, connection_id)
                    await location_ws_manager.send_personal_message({
                        "type": "tracking_stopped",
                        "tracked_user_id": tracked_user_id
                    }, websocket)
            
            elif message_type == "ping":
                # Heartbeat/ping message
                await location_ws_manager.send_personal_message({
                    "type": "pong",
                    "timestamp": asyncio.get_event_loop().time()
                }, websocket)
    
    except WebSocketDisconnect:
        location_ws_manager.disconnect(user_id, connection_id)
    except Exception as e:
        logger.error(f"WebSocket error for {user_id}:{connection_id}: {e}")
        location_ws_manager.disconnect(user_id, connection_id)

@ws_router.get("/ws/stats")
async def get_websocket_stats():
    """Get WebSocket connection statistics"""
    return location_ws_manager.get_connection_stats()

# Enhanced GPS logging endpoint that broadcasts via WebSocket
@router.post("/log-realtime", response_model=RealTimeGPSLogShow)
async def create_realtime_gps_log(
    gps_data: RealTimeGPSLogCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new GPS log entry and broadcast to WebSocket connections"""
    try:
        # Create GPS log entry
        db_gps_log = RealTimeGPSLog(
            user_id=current_user.id,
            activity_id=gps_data.activity_id,
            latitude=gps_data.latitude,
            longitude=gps_data.longitude,
            recorded_at=datetime.utcnow()
        )
        
        db.add(db_gps_log)
        db.commit()
        db.refresh(db_gps_log)
        
        # Broadcast via WebSocket
        location_data = {
            "latitude": gps_data.latitude,
            "longitude": gps_data.longitude,
            "activity_id": gps_data.activity_id,
            "recorded_at": db_gps_log.recorded_at.isoformat()
        }
        
        background_tasks.add_task(
            location_ws_manager.broadcast_location_update,
            str(current_user.id),
            location_data
        )
        
        return db_gps_log
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create GPS log: {str(e)}")