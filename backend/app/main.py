from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.routers import (
    alerts, animals, auth, breeding, dashboard, events, exits, farms, health_records, inventory, lots,
    production, reports, social_auth, users,
)

app = FastAPI(title="Gesti\u00f3n Ganadera API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_cors_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["Salud"])
def health():
    return {"status": "ok", "service": "gestion-ganadera-api"}


for router in (
    auth.router,
    farms.router,
    dashboard.router,
    alerts.router,
    animals.router,
    lots.router,
    exits.router,
    events.router,
    inventory.router,
    production.router,
    health_records.router,
    breeding.router,
    reports.router,
    social_auth.router,
    users.router,
):
    app.include_router(router)
