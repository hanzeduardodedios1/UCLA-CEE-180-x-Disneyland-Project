import logging
import os
import time
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from data.hotels import DISNEYLAND_GATES, HOTEL_ANALYSIS, HOTELS, parkingcost
from services.directions import walking_route

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger("disneyland-api")

limiter = Limiter(key_func=get_remote_address)
app = FastAPI(title="Disneyland Hotel API", version="1.1.0")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


@app.on_event("startup")
def _log_routes():
    paths = sorted({getattr(r, "path", "") for r in app.routes} - {""})
    logger.info("Disneyland Hotel API v1.1.0 — routes: %s", ", ".join(paths))

_cors = os.getenv("CORS_ORIGINS", "").strip()
if not _cors or _cors == "*":
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[o.strip() for o in _cors.split(",") if o.strip()],
        allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )


@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    ms = (time.perf_counter() - start) * 1000
    logger.info(
        "%s %s -> %s (%.1f ms)",
        request.method,
        request.url.path,
        response.status_code,
        ms,
    )
    return response


class HotelRow(BaseModel):
    hotel: str
    address: str
    nightly_rate: int
    drivingcost: int
    walk_mins: float
    transit_mins: float | None
    transit_saved_mins: float


class HotelRouteResponse(BaseModel):
    hotel: str
    origin: str
    destination: str
    distance_text: str
    distance_meters: int
    duration_text: str
    duration_seconds: int
    duration_mins: float
    polyline: str


def _build_row(name: str) -> HotelRow | None:
    base = next((h for h in HOTELS if h["name"].lower() == name.lower()), None)
    stats = next((a for a in HOTEL_ANALYSIS if a["hotel"].lower() == name.lower()), None)
    if not base or not stats:
        return None
    transit = stats["transit_mins"]
    nightly_rate = stats["nightly_rate"]
    return HotelRow(
        hotel=base["name"],
        address=base["address"],
        nightly_rate=nightly_rate,
        drivingcost=nightly_rate + parkingcost,
        walk_mins=stats["walk_mins"],
        transit_mins=transit if transit is not None else None,
        transit_saved_mins=stats["transit_saved_mins"],
    )


def _search_hotels(query: str) -> list[HotelRow]:
    q = query.strip().lower()
    if not q:
        return []
    matches = []
    for analysis in HOTEL_ANALYSIS:
        if q in analysis["hotel"].lower():
            row = _build_row(analysis["hotel"])
            if row:
                matches.append(row)
    return matches


@app.get("/api/health")
def health():
    return {"status": "ok", "hotels": len(HOTELS)}


@app.get("/api/hotels/names")
def hotel_names():
    return [h["name"] for h in HOTELS]


@app.get("/api/hotels/suggest")
def suggest_hotels(q: str = Query("", description="Partial hotel name")):
    """Filtered hotel names for the search dropdown."""
    needle = q.strip().lower()
    if not needle:
        return [h["name"] for h in HOTELS]
    return [h["name"] for h in HOTELS if needle in h["name"].lower()]


@app.get("/api/hotels/search", response_model=HotelRow)
@limiter.limit("30/minute")
def search_hotel(
    request: Request,
    q: str = Query(..., min_length=1, description="Hotel name to search"),
    exact: bool = Query(False, description="Require exact hotel name match"),
):
    if exact:
        row = _build_row(q.strip())
        if row is None:
            raise HTTPException(status_code=404, detail=f"No Disneyland hotel found for '{q}'")
        return row

    matches = _search_hotels(q)
    if not matches:
        raise HTTPException(status_code=404, detail=f"No Disneyland hotel found for '{q}'")
    if len(matches) > 1:
        raise HTTPException(
            status_code=400,
            detail={
                "message": "Multiple hotels match. Be more specific.",
                "matches": [m.hotel for m in matches],
            },
        )
    return matches[0]


@app.get("/api/hotels/route", response_model=HotelRouteResponse)
@limiter.limit("10/minute")
def hotel_route(
    request: Request,
    hotel: str = Query(..., min_length=1, description="Exact hotel name"),
):
    """Walking route from hotel to Disneyland gates via Google Directions API."""
    name = hotel.strip()
    row = _build_row(name)
    if row is None:
        logger.warning("Route 404: unknown hotel name %r", name)
        raise HTTPException(
            status_code=404,
            detail=f"No Disneyland hotel found for '{name}'",
        )

    address = row.address
    logger.info("Route requested: %s (%s) -> %s", name, address, DISNEYLAND_GATES)

    try:
        route = walking_route(address)
    except RuntimeError as exc:
        msg = str(exc)
        logger.warning("Route failed for %s: %s", name, msg)
        if "GOOGLE_MAPS_API_KEY" in msg:
            raise HTTPException(status_code=503, detail=msg) from exc
        raise HTTPException(status_code=502, detail=msg) from exc

    logger.info(
        "Route OK: %s — %s (%s)",
        name,
        route["duration_text"],
        route["distance_text"],
    )

    return HotelRouteResponse(hotel=name, **route)
