import os

import googlemaps
from googlemaps.exceptions import ApiError

from data.hotels import DISNEYLAND_GATES

_gmaps_client: googlemaps.Client | None = None


def _client() -> googlemaps.Client:
    global _gmaps_client
    if _gmaps_client is not None:
        return _gmaps_client
    key = os.getenv("GOOGLE_MAPS_API_KEY", "").strip()
    if not key or key == "your_google_maps_server_api_key_here":
        raise RuntimeError(
            "GOOGLE_MAPS_API_KEY is not set. Add your server API key to .env."
        )
    _gmaps_client = googlemaps.Client(key=key)
    return _gmaps_client


def walking_route(origin_address: str, destination: str = DISNEYLAND_GATES) -> dict:
    """Call Google Directions API (server-side) for a walking route."""
    client = _client()
    try:
        results = client.directions(
            origin_address,
            destination,
            mode="walking",
        )
    except ApiError as exc:
        raise RuntimeError(f"Google Directions API error: {exc}") from exc

    if not results:
        raise RuntimeError("No walking route found for this hotel.")

    leg = results[0]["legs"][0]
    overview = results[0].get("overview_polyline", {})

    return {
        "origin": leg["start_address"],
        "destination": leg["end_address"],
        "distance_text": leg["distance"]["text"],
        "distance_meters": leg["distance"]["value"],
        "duration_text": leg["duration"]["text"],
        "duration_seconds": leg["duration"]["value"],
        "duration_mins": round(leg["duration"]["value"] / 60, 1),
        "polyline": overview.get("points", ""),
    }
