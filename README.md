# Asphr — Rebuild Implementation Plan
### Intellify 4.0, Marwadi University, Rajkot — 24-Hour Build

This plan rebuilds Asphr (hazard-aware, multi-objective two-wheeler routing) from scratch, using your preferred stack: **Supabase, React (web), Flutter (app), Vercel (frontend), Railway/Render (backend)**. It is restructured specifically to avoid the three failures from your last build. Read Section 0 first — everything else implements it.

---

## 0. What Changes And Why

**1. OSM skeleton download kept crashing.**
Root cause is almost certainly a single oversized Overpass/OSMnx request (Mumbai MMR is huge) hitting a timeout or memory ceiling, not a fundamental limitation of OSMnx. Fix: shrink the target area, pre-fetch it *before* the hackathon clock starts, tile-and-compose properly instead of manually stitching, and cache the result to disk so you never re-download live. Full steps in **Section 5**.

**2. Supabase quota exhausted from loading 100k road-segment rows to the frontend.**
Direct answer: **no, you do not need to push the road network into Supabase at all**, and you should not send it to the frontend under any circumstance. The routing graph is a backend-only asset (kept in memory from a cached file). The frontend never needs raw road geometry — Mapbox's own basemap already draws every road on Earth; your app only ever needs to draw a handful of *derived* things (a computed route, a small number of hazard pins). Full reasoning and trimmed schema in **Section 4**.

**3. Hazard model accuracy stuck at ~40% on synthetic data.**
Root cause: fitting a single ML model to do the job that should really be split into a deterministic physics layer (for the live "it just works" demo) and a small ML layer (for soft route-weighting only). Chasing a high "accuracy" score on a fabricated regression target is the wrong goal. Full reframing and concrete fixes in **Section 6**.

---

## 1. Scope For 24 Hours

Every feature from the original architecture stays in the product and in the demo — nothing is dropped. The distinction below is about **how each feature is backed**, not whether it exists: **Real** means a genuinely working pipeline computes it live; **Hardcoded/Seeded** means the feature is fully present and functioning end-to-end in the UI and API, but the data behind it is a static lookup table or a curated seed set instead of a live-computed or continuously-updated pipeline. Every "Hardcoded/Seeded" item is still wired into real request/response flows and real route-weighting math — a judge clicking through the app sees all of it working. Nothing is a fake screen with no backend behind it.

| Feature (from original architecture) | Backing | Reasoning |
|---|---|---|
| Fastest + Safest route objectives | **Real** | Core route-weight math, computed live from the graph |
| Straightest route objective | **Real** | Bearing-based turn-penalty A* — same pathfinding infra as fastest/safest, low incremental cost |
| Popular route objective | **Real, seeded POI data** | Route-weighting is live; `popular_places` is a manually curated seed list (real Rajkot/Mumbai landmarks) instead of a scraped/growing dataset — still a genuinely working feature |
| Bike + Car vehicle profiles | **Real** | Full graph-pruning constraint logic |
| Truck + Supercar profiles | **Real** | Same pruning function, extended with width/height/surface checks — cheap to add once Bike/Car works |
| Live hazard map with Supabase Realtime pins | **Real** | Your visual "wow" moment |
| SOS auto-trigger pipeline | **Real** | Your emotional pitch moment ("<10 sec to hospital") |
| Physics-threshold hazard detection (Tier 1) | **Real** | Deterministic — always works live, no ML risk on stage |
| ML hazard classifier (Tier 2, soft route-weighting) | **Real, time-boxed** | Genuinely trained model; see Section 6 for how to make it converge well in a few hours |
| LSTM traffic forecasting | **Hardcoded/Seeded** — diurnal lookup table | A per-hour speed-multiplier table (built once, offline) feeds the exact same weight formula a live-trained LSTM would — the "forecast" is real in the pipeline, just backed by a static table instead of trained time-series history you don't have |
| React web app | **Real** | Primary demo surface |
| Flutter mobile app | **Real, core screens** — built after web MVP so it reuses working endpoints | Map, route request, SOS button all fully functional; polish screens can lag |
| Fleet dashboard | **Hardcoded/Seeded** | Real page, real layout, fed by a small static/mock device list with static safety scores instead of a live cross-fleet aggregation query |
| Weather-aware routing | **Real** (live single-call weather API) + **Hardcoded/Seeded** grid persistence | Current conditions at the route are fetched live and folded into the weight formula; the multi-cell `weather_grid` table (for a map overlay) is seeded with static rows instead of a 10-minute polling job |
| Live traffic conditions | **Hardcoded/Seeded** — road-class/hour lookup table | Feeds the fastest-route weight formula for real; backed by a static average-speed table instead of a live traffic feed |
| Real Pi4 + MPU-6050 + GPS + SIM hardware | **Real, tested early and isolated** | Wire it in parallel from hour 1; if it's flaky by hour 18, fall back to a simulated telemetry sender hitting the same `/iot/telemetry` endpoint — the demo looks and behaves identically either way |

---

## 2. Final Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Database | Supabase (Postgres + PostGIS) | Free tier: 500 MB DB, ~5 GB egress/month, 2 free projects, Realtime included. Create the project on day 0 so it's warmed up — free projects auto-pause after 7 days idle, irrelevant within a 24h window but worth knowing post-hackathon. |
| Backend | FastAPI (Python), deployed on Railway or Render | Keep the in-memory NetworkX routing graph here — this is the fix for problem #2 |
| Realtime hazard push | **Supabase Realtime** (Postgres change subscriptions), not a custom WebSocket hub | Cuts hours of backend work — the frontend subscribes directly to `hazard_events` inserts |
| Web frontend | React + Vite + Mapbox GL JS + Tailwind, deployed on Vercel | |
| Mobile | Flutter, using `mapbox_gl` or `flutter_map`, hitting the same REST API | Full feature set, built after web so it reuses working endpoints |
| Routing engine | NetworkX (Dijkstra/A*) over an OSMnx-built graph, cached to a `.graphml` file | Never touches Supabase |
| Hazard detection | Rule-based physics thresholds (Tier 1, live) + lightweight Gradient Boosting/Logistic Regression (Tier 2, offline weighting) | See Section 6 |
| Hardware | Raspberry Pi 4, MPU-6050, GPS module, SIM module | Sends event-driven telemetry only, not continuous streams |

---

## 3. Architecture Overview

Four layers, same shape as your original plan, with tighter boundaries:

- **Hardware layer** — Pi4 computes vibration magnitude and tilt locally from the MPU-6050. It only transmits when a threshold is crossed (an *event*), plus a periodic heartbeat with GPS location. It never streams raw sensor data over the network.
- **Backend layer (Railway/Render)** — FastAPI app holding the routing graph in memory, running the two-tier hazard logic, exposing REST endpoints, and writing only *events* (hazards, SOS, feedback) to Supabase.
- **Database layer (Supabase)** — Stores sparse, mutable data only: hazard events, SOS alerts, feedback, device registry. Never stores or serves the bulk road network.
- **Frontend layer (Vercel / Flutter)** — Renders Mapbox's own basemap for roads (zero DB cost), overlays a small number of hazard pins fetched by viewport, and draws the one computed route returned by the backend per request. Subscribes to Supabase Realtime for live hazard pins instead of polling.

---

## 4. Database Design (Supabase)

### 4.1 Principle

Ask of every table: *"Will this ever need to return more than a few hundred rows to a browser?"* If yes, it doesn't belong verbatim in a table the frontend queries directly — either bound it (bbox + LIMIT), aggregate it, or keep it backend-only. This single rule is what caused the 100k-row quota exhaustion, and it's the rule that prevents a repeat.

Answering your question directly: **road segments do not need to live in Supabase for routing to work.** The graph that Dijkstra/A* runs on is a NetworkX object loaded from a local `.graphml` file at backend startup — a pure in-memory/on-disk concern, no database involved. Supabase is only needed for things that actually change while the app runs.

If you still want a `road_segments` table (e.g., to show judges "we use PostGIS spatial queries," or to snap IoT readings to a road via `ST_DWithin` in SQL instead of a backend KD-tree), it's optional and marked below — but if you build it, insert it in small batches with an upsert key, and never let the frontend query it directly. The backend KD-tree approach (Section 5) achieves the same nearest-road snapping without touching the database at all, which is the safer choice for a 24-hour build.

### 4.2 Enable PostGIS

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### 4.3 Core Tables (build these)

**`devices`** — registers each physical/simulated hardware unit.
```sql
CREATE TABLE devices (
    id TEXT PRIMARY KEY,                 -- device_id, e.g. 'asphr-pi4-01'
    label TEXT,
    api_key_hash TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    last_seen_at TIMESTAMP
);
```

**`hazard_events`** — the single unified table for every hazard signal, whether it came from IoT telemetry, the ML tier, or a manual test insert. This replaces the original plan's separate `segment_hazards` + `iot_readings` tables — one table, event-driven writes only, so row count stays small (hundreds, not hundreds of thousands) even over a full demo day.
```sql
CREATE TABLE hazard_events (
    id SERIAL PRIMARY KEY,
    device_id TEXT REFERENCES devices(id),
    geom GEOMETRY(Point, 4326) NOT NULL,
    hazard_type VARCHAR(30) NOT NULL,     -- 'pothole', 'speed_breaker', 'harsh_brake', 'crash_suspected'
    severity FLOAT NOT NULL CHECK (severity BETWEEN 0 AND 1),
    confidence FLOAT DEFAULT 1.0,
    source VARCHAR(20) NOT NULL,          -- 'iot_threshold', 'ml_tier', 'manual'
    road_label TEXT,                      -- optional reverse-geocoded street name, cached at insert time
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '2 hours')
);

CREATE INDEX idx_hazard_geom ON hazard_events USING GIST(geom);
CREATE INDEX idx_hazard_active ON hazard_events(expires_at);
```
(A partial index with `WHERE expires_at > NOW()` fails in Postgres — `NOW()` isn't IMMUTABLE, so it can't be baked into an index predicate. A plain index on `expires_at` still makes both the cleanup `DELETE` and any "active hazards" read fast.)
Enable Realtime on this table from the Supabase dashboard (Database → Replication) so the frontend can subscribe to inserts directly, instead of you building a WebSocket hub.

**`sos_alerts`**
```sql
CREATE TABLE sos_alerts (
    id SERIAL PRIMARY KEY,
    device_id TEXT REFERENCES devices(id),
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    triggered_at TIMESTAMP DEFAULT NOW(),
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP,
    notes TEXT
);
```

**`route_feedback`**
```sql
CREATE TABLE route_feedback (
    id SERIAL PRIMARY KEY,
    session_id TEXT,                      -- client-generated anon id, no auth needed for MVP
    start_point GEOMETRY(Point, 4326),
    end_point GEOMETRY(Point, 4326),
    route_type VARCHAR(20),
    rating INT CHECK (rating BETWEEN 1 AND 5),
    feedback_text TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 4.4 Every Original Table, Restored

Nothing here is dropped — the schema below is the full original nine-table design, kept as a working feature set. Only the *fill strategy* changes per table, per Section 1: some are populated by live pipelines, some by a seeded/hardcoded dataset. Either way, every table backs a real, queryable feature.

**`vehicle_profiles`** — real, all four types.
```sql
CREATE TABLE vehicle_profiles (
    id SERIAL PRIMARY KEY,
    vehicle_type VARCHAR(50) NOT NULL,
    max_width_m FLOAT,
    max_height_m FLOAT,
    min_road_width_m FLOAT,
    avoid_speed_bumps BOOLEAN,
    allow_narrow_roads BOOLEAN,
    prefer_highways BOOLEAN
);

INSERT INTO vehicle_profiles (vehicle_type, max_width_m, max_height_m, min_road_width_m, avoid_speed_bumps, allow_narrow_roads, prefer_highways) VALUES
('bike', 1.0, 2.0, 1.5, FALSE, TRUE, FALSE),
('car', 2.0, 1.8, 2.5, FALSE, TRUE, FALSE),
('truck', 3.0, 4.2, 3.5, FALSE, FALSE, TRUE),
('supercar', 2.1, 1.3, 2.5, TRUE, FALSE, FALSE);
```
Loaded once into the backend's graph-pruning logic at startup — a real, working constraint system for all four vehicle types.

**`popular_places`** — real feature, seeded dataset.
```sql
CREATE TABLE popular_places (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category VARCHAR(50),
    geometry GEOMETRY(Point, 4326) NOT NULL,
    popularity_score FLOAT,
    city VARCHAR(100)
);

CREATE INDEX idx_places_geom ON popular_places USING GIST(geometry);
CREATE INDEX idx_places_city ON popular_places(city);
```
Seed this with 15–25 real, manually looked-up landmarks for your demo city (malls, colleges, stations, temples). The "Popular" route objective queries this table live via `ST_DWithin` — genuinely functioning, just backed by a curated list instead of a continuously-growing one.

**`traffic_conditions`** — hardcoded/seeded lookup, wired into real weighting.
```sql
CREATE TABLE traffic_conditions (
    id SERIAL PRIMARY KEY,
    road_class VARCHAR(50),
    hour_of_day INT CHECK (hour_of_day BETWEEN 0 AND 23),
    avg_speed_kmh FLOAT,
    congestion_level INT CHECK (congestion_level BETWEEN 0 AND 4)
);
```
Seed once with a static average-speed table per road class × hour of day (a plausible diurnal curve you sketch out, not a live feed). The fastest-route weight function reads this table for real on every request — the feature functions correctly, it's just not fed by a live traffic API.

**`weather_grid`** — hybrid: live point lookup + seeded grid.
```sql
CREATE TABLE weather_grid (
    id SERIAL PRIMARY KEY,
    cell_geometry GEOMETRY(Polygon, 4326) NOT NULL,
    temperature FLOAT,
    humidity FLOAT,
    visibility_km FLOAT,
    precipitation_mm FLOAT,
    wind_speed_kmh FLOAT,
    weather_condition VARCHAR(50),
    recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_weather_geom ON weather_grid USING GIST(cell_geometry);
```
Route-time weather (current conditions at origin/destination) comes from one **live** API call per route request — cheap, real, and it's the version that actually affects the weight formula. This table stores a small set of **seeded** grid cells for the map's weather-overlay visual, rather than running a live 10-minute polling job across the whole city.

**`road_segments`** — real, backend-only (this is the fix for problem #2, not a cut feature).
```sql
CREATE TABLE road_segments (
    id SERIAL PRIMARY KEY,
    osm_way_id BIGINT,
    source_node BIGINT NOT NULL,
    target_node BIGINT NOT NULL,
    geometry GEOMETRY(LineString, 4326) NOT NULL,
    length_meters FLOAT NOT NULL,
    road_type VARCHAR(50),
    max_speed INT,
    lanes INT,
    has_speed_bump BOOLEAN DEFAULT FALSE,
    is_toll BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_road_segments_geom ON road_segments USING GIST(geometry);
CREATE INDEX idx_road_segments_source ON road_segments(source_node);
CREATE INDEX idx_road_segments_target ON road_segments(target_node);
```
This table is fully part of the architecture — populate it from your cached graph in batched upserts (500–1000 rows per batch, unique key on `osm_way_id`/`source_node`/`target_node`) so judges can see real PostGIS spatial queries (`ST_DWithin` snapping for IoT readings) running against it. The one rule that doesn't change: the frontend never queries this table directly or fetches it in bulk — that specific pattern is what caused the quota exhaustion last time, and it's a correctness fix, not a feature cut. Routing itself still runs off the in-memory graph either way.

**`iot_readings`** — real, throttled instead of streamed.
```sql
CREATE TABLE iot_readings (
    id SERIAL PRIMARY KEY,
    device_id TEXT REFERENCES devices(id),
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    vibration_magnitude FLOAT,
    tilt_angle FLOAT,
    recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_iot_device ON iot_readings(device_id);
CREATE INDEX idx_iot_time ON iot_readings(recorded_at);
```
Restored for the fleet dashboard's telemetry log. Keep it real but throttled — one row per device every few seconds (not raw sensor rate), which is what keeps this table small without removing the feature. The fleet dashboard's aggregate stats (per-device safety score, heatmap) are the part seeded with mock data per Section 1; this raw log itself is genuinely populated.

### 4.5 Cleanup Job

Run this from the backend's existing scheduler (see Section 7), every 5–10 minutes, so `hazard_events` never grows unbounded during the demo:
```sql
DELETE FROM hazard_events WHERE expires_at < NOW();
```

---

## 5. OSM Road Network Pipeline (fixing the crash)

The highest-leverage fix is procedural, not technical: **do this before the hackathon starts**, not during it. A city-scale OSMnx download is a one-time, network-heavy, crash-prone step — it has no business being on your 24-hour critical path.

1. **Pick the smallest bounding box that covers your demo route(s).** Rajkot city itself (not a wider district) is almost certainly enough, and it's dramatically smaller than the Mumbai MMR corridor you fought with last time — faster download, lower memory footprint, and it's a nice local touch for judges at a Rajkot venue. Keep the Panvel/Mumbai extract as a fallback dataset if you want continuity with earlier work, but don't target both in one pass.
2. **Download in tiles deliberately, not simplified.** Split the bounding box into a small grid (4–9 tiles is usually enough for a city-sized area). Download each tile with `simplify=False`. Simplifying *before* merging tiles corrupts topology at tile borders — this is a likely secondary contributor to your earlier crashes/integration pain, on top of the raw size problem.
3. **Save each tile to its own `.graphml` file immediately after a successful download**, before moving to the next tile. A crash mid-run then costs you one tile's re-download, not the whole area.
4. **Compose all tiles into a single graph, then simplify once**, on the merged graph, not per-tile. This is the correct way to do what you were doing manually with chunked integration — the composition step handles overlapping nodes/edges at tile boundaries correctly.
5. **Cache the final merged, simplified graph to one `.graphml` file and commit it into the repo** (a Rajkot-city extract is typically a few MB — well within normal git limits). The backend loads this file into memory at startup. You now have zero network dependency for the routing graph during the entire 24-hour window.
6. **If Overpass API access is flaky at the venue** (shared conference WiFi is often bad for large API calls), download the raw `.osm.pbf` extract for Gujarat from Geofabrik ahead of time and build the graph from that local file instead of hitting Overpass at all — same OSMnx pipeline, just pointed at a local file source.
7. **Raise the OSMnx/Overpass timeout setting and keep the polygon simple** (a rectangular bbox, not a complex multipolygon) for the tiled downloads — complex polygon queries are slower and more failure-prone than simple bbox queries.

Net effect: the thing that crashed you last time now happens once, in a low-stress setting, with checkpointed progress, and never touches your hackathon clock again.

---

## 6. Hazard Detection (fixing the 40% accuracy)

### 6.1 Reframe the problem

A single ML model trying to predict a continuous hazard score from synthetic data, evaluated on raw accuracy, is a hard problem even with weeks of tuning — it's the wrong shape for a 24-hour build and it puts your flashiest demo moment (SOS, live hazard alerts) at the mercy of a model you can't fully trust. Split it in two:

- **Tier 1 — Physics threshold engine (deterministic, drives the live demo).** A crash/pothole/harsh-brake event is fundamentally a signal-processing question: does vibration magnitude or tilt angle cross a known physical threshold? This needs no training data at all, will never misbehave on stage, and is exactly what your pitch deck already promises ("3.5g impact and 90° tilt → automatic SOS"). This is what actually fires your SOS pipeline and live hazard pins.
- **Tier 2 — Lightweight ML classifier (offline, soft route-weighting only).** Used to nudge the "safest route" cost function based on patterns across many hazard events (e.g., "this road class + this hour tends to have more incidents"). If it's mediocre, the routing still works correctly — it just weighs safety slightly less precisely. It never gates anything user-facing directly.

This alone removes the model from your critical path for the live "wow" moment.

### 6.2 Concrete fixes for Tier 2's accuracy

1. **Cut the feature set from ~23 down to 6–8 high-signal features**: vibration magnitude, peak acceleration, road class, lane count, speed-bump flag, hour-of-day (sin/cos). Fewer synthetic features means less compounding noise — this is very likely the biggest single contributor to your 40% result.
2. **Generate synthetic data from a parameterized simulation of each event type, not random labels on random features.** Simulate a plausible accelerometer/gyroscope signature for "pothole," "speed breaker," "harsh brake," and "smooth road" with realistic noise around each class's known signal shape. A model trained on genuinely separable simulated classes will hit high accuracy easily; one trained on arbitrary label assignment never will, no matter how you tune it.
3. **Balance your classes.** Equal counts per hazard type (including "no hazard") — synthetic-data imbalance is a very common, easy-to-miss cause of a stuck low accuracy number.
4. **Reframe as binary classification (hazard / no-hazard) rather than a continuous regression target for the headline metric.** It's both easier to hit a strong, honest number on cleanly-separable synthetic classes, and more meaningful for what the system actually needs to do.
5. **Report precision/recall/F1 alongside accuracy**, especially if classes aren't perfectly balanced — a single accuracy number on synthetic data is easy to game and easy to misread; F1 tells a more honest (and often better-looking) story to judges.
6. **Use a small, low-variance model** — shallow Gradient Boosting or plain Logistic Regression. Complex models overfit small, noisy synthetic datasets; simpler models generalize better here and train in seconds, which matters when you're time-boxing.
7. **Time-box this to at most a few hours.** If it's not converging cleanly by then, ship Tier 1 alone for the live demo and present Tier 2 in the pitch as "integrated into the safest-route cost function" without depending on it for the on-stage moment.

### 6.3 Traffic Forecasting (restored, hardcoded backing)

The LSTM traffic forecaster stays in the architecture and in the pitch — it just isn't trained live against real time-series history you don't have. Build a static diurnal lookup table (predicted speed multiplier per hour of day, sketched from plausible commute patterns) and feed it into the exact same "fastest route" weight formula a live-trained LSTM output would feed. The feature functions identically from the outside — routes visibly change based on time of day — while the backing data is a one-time hardcoded table instead of a trained model. If time allows after Tier 2 is stable, you can upgrade this to an actual tiny LSTM trained on synthetic diurnal curves (a smooth, easy-to-fit pattern, unlike per-segment hazard data) — but the lookup table alone is enough to ship the feature as real and working.

---

## 7. Backend Build Order (FastAPI on Railway/Render)

1. Scaffold the FastAPI project with the module layout from your original plan (`config.py`, `models/`, `algorithms/`, `services/`, `routers/`) — the structure was sound, keep it.
2. Wire the Supabase connection (async SQLAlchemy + asyncpg, or the Supabase Python client directly — the client is simpler for a 24h build and avoids ORM setup time).
3. Load the pre-built `.graphml` file (from Section 5) into a NetworkX `MultiDiGraph` at startup, and build the SciPy KD-tree for coordinate-to-node snapping. Confirm graph load time is acceptable on the deployed instance, not just locally.
4. Implement vehicle-constraint graph pruning for all four `vehicle_profiles` rows (Bike, Car, Truck, Supercar) — one filter function reading width/height/surface/highway constraints, not four separate code paths.
5. Implement the Tier-1 physics threshold function for hazard classification (pure function, no DB or ML dependency).
6. Implement all four edge-weight functions: **fastest** (length/speed, now also multiplied by the hardcoded diurnal traffic lookup), **safest** (Tier-1 + Tier-2 blended hazard score), **straightest** (bearing-delta turn penalty inside A*), **popular** (cost reduction near `popular_places` via `ST_DWithin`).
7. Build `/api/v1/routes/compute`, accepting all four `vehicle_type` and all four `route_type` values, returning a GeoJSON route, distance, estimated time, and average hazard score.
8. Build `/api/v1/iot/telemetry` (event-driven inserts into `hazard_events` and throttled inserts into `iot_readings` when Tier-1 thresholds are crossed) and `/api/v1/iot/sos`.
9. Build `/api/v1/routes/feedback`, `/api/v1/routes/popular`, and `/health`.
10. Seed `vehicle_profiles`, `popular_places`, `traffic_conditions`, and `weather_grid` with the static datasets from Section 4.4.
11. Wire a single live weather API call into route computation (real), and build `/api/v1/fleet/dashboard` returning aggregate stats from a small mock/static device list (hardcoded, per Section 1) alongside real recent rows from `iot_readings`.
12. Add the background cleanup job (APScheduler, every 5–10 min) for expired `hazard_events`.
13. Deploy to Railway/Render **early** (end of hour 2–3, even with stub endpoints) — catching deployment/env-var issues on day one is far cheaper than discovering them at hour 20.
14. Only after the above is stable, layer in the Tier-2 ML weighting as a multiplier on the "safest" weight function.

---

## 8. API Endpoints (MVP)

| Method & Path | Purpose |
|---|---|
| `POST /api/v1/routes/compute` | Origin, destination, vehicle_type (bike/car/truck/supercar), route_type (fastest/safest/straightest/popular) → GeoJSON route + stats |
| `POST /api/v1/routes/feedback` | Post-trip rating, writes to `route_feedback` |
| `GET /api/v1/routes/popular?city=` | Returns seeded `popular_places` rows for the requested city |
| `GET /api/v1/hazards?min_lat=&min_lon=&max_lat=&max_lon=` | Viewport-bounded hazard fetch, hard `LIMIT` (e.g. 200 rows) — never an unbounded table scan |
| `POST /api/v1/iot/telemetry` | Event-driven hardware payload; only sent when a threshold is crossed |
| `POST /api/v1/iot/sos` | Emergency trigger → `sos_alerts` insert |
| `GET /api/v1/fleet/dashboard` | Aggregate fleet stats — mock/static device list + real recent `iot_readings` |
| `GET /api/v1/geocode/search?q=` | Proxies Mapbox Geocoding (fallback: Nominatim) |
| `GET /api/v1/geocode/reverse?lat=&lon=` | Reverse geocode |
| `GET /health` | DB connectivity, graph node/edge counts, model load state |

Live hazard pins on the map do **not** need a dedicated endpoint beyond the bounded `GET /hazards` for initial load — new events after that arrive via the frontend's direct Supabase Realtime subscription on `hazard_events`, not a custom WebSocket channel.

---

## 9. Frontend Build Order (React + Vercel)

1. Scaffold with Vite + React + Tailwind; install `mapbox-gl`, `react-map-gl`, `@supabase/supabase-js`.
2. Build the Mapbox base map — this alone renders every road with zero backend or database cost.
3. Build the Routes page: origin/destination search (calling `/geocode/search`), vehicle tabs (Bike/Car/Truck/Supercar), route-type toggle (Fastest/Safest/Straightest/Popular), call `/routes/compute`, draw the returned GeoJSON line, show turn-by-turn/summary stats.
4. Build the post-route feedback modal → `POST /routes/feedback`.
5. Build the live hazard layer: on load, fetch `GET /hazards` bounded to the current viewport; subscribe to Supabase Realtime on `hazard_events` inserts for live updates; re-fetch on `onMoveEnd` with the new bounding box, never the whole table.
6. Build the SOS panel: a manual trigger button for demo purposes, plus a listener that shows an animated toast when a real `sos_alerts` row lands via Realtime.
7. Build the Services/Fleet dashboard page: system health from `/health`, fleet stats from `/api/v1/fleet/dashboard` — a real page, real request, mock data behind it per Section 1.
8. Deploy to Vercel, wire the backend URL, Mapbox token, and Supabase anon key as environment variables.

---

## 10. Mobile App (Flutter) — Built After Web MVP, Same Full Feature Set

Sequenced after the web MVP because it reuses every backend endpoint as-is — not because anything is cut. Same routing objectives, same vehicle types, same SOS pipeline:

1. Scaffold a Flutter project with a map package (`mapbox_gl` for visual parity with web, or `flutter_map` if you want to move faster).
2. Build the map + route screen: origin/destination inputs, full vehicle tabs (Bike/Car/Truck/Supercar), full route-type toggle (Fastest/Safest/Straightest/Popular), calling the same `/routes/compute` endpoint.
3. Add the SOS button, calling the same `/iot/sos` endpoint, and the live hazard layer via the same bounded `/hazards` fetch + Supabase Realtime subscription used on web.
4. Add the feedback modal and fleet dashboard screen once the above is solid — same endpoints as web, so this is UI time, not new backend work.

---

## 11. Hardware / IoT Integration

1. Get the Pi4 + MPU-6050 + GPS reading raw values locally first, independent of any network call — validate the sensor pipeline in isolation before wiring it to your API.
2. Implement the vibration-magnitude and tilt-angle threshold check **on the device**, not the backend — this is what makes telemetry event-driven instead of a continuous stream, which is also what keeps `hazard_events` small.
3. On threshold crossing, POST a single event to `/api/v1/iot/telemetry` with device_id, coordinates, and the computed magnitude/tilt values.
4. On a harder threshold (impact + tilt combination matching your "3.5g / 90°" pitch line), POST to `/api/v1/iot/sos`.
5. Build a simulated telemetry sender (a script that POSTs the same payload shape on a timer/manual trigger) in parallel from hour 1, as insurance — if the real hardware isn't reliable by hour 18, swap to the simulator for the live demo without changing anything backend- or frontend-side.
6. If SIM-module connectivity is untested territory, prefer Pi4 WiFi at the venue for the live demo and keep the SIM module as a "designed for" pitch point rather than a live dependency.

---

## 12. Deployment Sequence

1. Create the Supabase project, run the DDL from Section 4, enable Realtime on `hazard_events`, grab the project URL + anon key + service role key.
2. Deploy the backend to Railway/Render with the service role key (server-side only, never shipped to any client), Mapbox token, and the cached `.graphml` bundled into the deploy.
3. Smoke-test `/health` and `/routes/compute` against the deployed backend directly (curl/Postman) before touching the frontend.
4. Deploy the frontend to Vercel with the backend URL, Mapbox public token, and Supabase URL + **anon** key (never the service role key in frontend env vars).
5. Run one full end-to-end pass: compute a route, trigger a simulated hazard event, confirm it appears live on the map via Realtime, trigger a simulated SOS, confirm the toast fires.
6. Repeat the same env-var wiring for the Flutter build.

---

## 13. Hour-by-Hour Timeline (24 Hours)

| Hours | Focus |
|---|---|
| 0–1 | Kickoff, repo scaffold, Supabase project created, roles split (backend / ML / frontend / hardware) |
| 1–3 | Backend skeleton deployed to Railway/Render (even with stub endpoints); DB schema applied (all tables from Section 4.4); cached `.graphml` loaded and route-computable locally |
| 3–6 | `/routes/compute` working end-to-end for all four vehicle types and fastest/safest; `vehicle_profiles` seeded and driving real pruning |
| 4–8 | (parallel) React scaffold, Mapbox basemap, Routes page wired to the live backend |
| 6–8 | Straightest (turn-penalty) and Popular (seeded `popular_places`) route objectives added to the same weight/pathfinding infra |
| 8–10 | `hazard_events` + bounded `/hazards` endpoint + Realtime subscription live on the map |
| 9–10 | Diurnal traffic lookup table + seeded `traffic_conditions`/`weather_grid` wired into the fastest-route weight formula; live single-call weather API added |
| 10–13 | SOS pipeline working end-to-end using the simulated telemetry sender; SOS panel + toast UI |
| 11–15 | (parallel) Tier-2 ML training on properly-simulated data; integrate as a soft weight once it's stable — does not block anything above |
| 13–14 | Fleet dashboard endpoint (mock device list + real `iot_readings` tail) and page |
| 14–18 | Flutter build (full route/vehicle/SOS/hazard feature set, reusing existing endpoints) |
| 16–19 | Frontend polish (feedback modal, turn-by-turn panel, fleet page), Vercel deploy, full env-var wiring |
| 18–21 | Real hardware integration test; fall back to simulator if not reliable |
| 20–23 | Bug bash across all four route types and all four vehicle types, seed demo `hazard_events`, rehearse the live demo script (including the SOS moment), record a fallback video in case venue WiFi fails |
| 23–24 | Final deploy freeze, pitch alignment check, submission |

---

## 14. Demo-Day Risk Mitigation

- **Venue WiFi is unreliable at most hackathons.** Have a pre-recorded screen capture of the full demo flow (route compute → live hazard pin → SOS toast) as a fallback if live network fails on stage.
- **Never demo live ML training** — Tier 2 should be trained and frozen well before the demo; only Tier 1 (deterministic) needs to work live.
- **Seed a few realistic `hazard_events` rows manually before judging** so the map doesn't look empty if no real/simulated telemetry has fired recently.
- **Keep the simulated telemetry sender as your primary SOS trigger for the demo**, even if real hardware works — it's more reliable on a schedule and looks identical to judges.
- **Confirm the Supabase service role key never ends up in frontend or Flutter env vars** — a leaked key is a fast way to blow through the free-tier egress quota again, this time from anywhere on the internet, not just your own app.

---

## 15. Project Folder Structure

Monorepo layout — three top-level apps sharing one repo, so a single Vercel/Railway/Render setup can point at subfolders without submodule hassle.

```
asphr/
├── backend/                          # FastAPI on Railway/Render
│   ├── app/
│   │   ├── main.py                   # FastAPI app entrypoint, router registration
│   │   ├── config.py                 # env vars: Supabase URL/keys, Mapbox, weather API, JWT/device secrets
│   │   ├── models/
│   │   │   ├── db_models.py          # Pydantic/SQLAlchemy models mirroring the Supabase schema
│   │   │   ├── hazard_predictor.py   # Tier-2 GBM/Logistic Regression wrapper
│   │   │   └── route_optimizer.py    # A*/Dijkstra pathfinder, edge-weight functions
│   │   ├── algorithms/
│   │   │   ├── graph_builder.py      # OSMnx tile download + compose + simplify (offline, pre-hackathon)
│   │   │   ├── graph_loader.py       # loads cached .graphml into memory + builds KD-tree at startup
│   │   │   └── vehicle_pruning.py    # graph filtering per vehicle_profiles row
│   │   ├── services/
│   │   │   ├── supabase_client.py    # single shared Supabase client (service role key, backend-only)
│   │   │   ├── geocoding.py          # Mapbox Geocoding + Nominatim fallback
│   │   │   ├── weather.py            # live single-call weather lookup
│   │   │   ├── traffic_lookup.py     # diurnal traffic_conditions + hardcoded LSTM-equivalent lookup
│   │   │   ├── hazard_tier1.py       # physics threshold engine (vibration/tilt)
│   │   │   ├── realtime.py           # helpers for writing rows that trigger Supabase Realtime
│   │   │   └── scheduler.py          # APScheduler: hazard_events cleanup job
│   │   └── routers/
│   │       ├── routes.py             # /api/v1/routes/*
│   │       ├── hazards.py            # /api/v1/hazards
│   │       ├── iot.py                # /api/v1/iot/*
│   │       ├── fleet.py              # /api/v1/fleet/dashboard
│   │       ├── geocode.py            # /api/v1/geocode/*
│   │       └── health.py             # /health
│   ├── data/
│   │   └── rajkot.graphml            # pre-built, cached road network (Section 5)
│   ├── db/
│   │   ├── schema.sql                # full DDL from Section 4 (all tables, indexes)
│   │   └── seed.sql                  # vehicle_profiles, popular_places, traffic_conditions, weather_grid seed data
│   ├── ml/
│   │   ├── train_hazard_model.py     # Tier-2 training script (offline, run before demo)
│   │   ├── generate_synthetic_data.py
│   │   └── hazard_model.pkl          # trained artifact, loaded by hazard_predictor.py
│   ├── scripts/
│   │   └── simulate_telemetry.py     # fallback telemetry/SOS sender (Section 11)
│   ├── requirements.txt
│   ├── .env.example
│   └── Procfile / railway.json       # deploy config for Railway or Render
│
├── frontend-web/                     # React + Vite on Vercel
│   ├── src/
│   │   ├── main.jsx
│   │   ├── App.jsx
│   │   ├── pages/
│   │   │   ├── Home.jsx
│   │   │   ├── Maps.jsx              # live hazard map, Realtime subscription
│   │   │   ├── Routes.jsx            # route compute UI, vehicle/route-type toggles
│   │   │   └── Services.jsx          # fleet dashboard + system health
│   │   ├── components/
│   │   │   ├── layout/
│   │   │   │   └── Navbar.jsx
│   │   │   ├── landing/
│   │   │   │   ├── HeroContent.jsx
│   │   │   │   ├── IntroAsphr.jsx
│   │   │   │   ├── CrisisStatsSection.jsx
│   │   │   │   ├── ChaptersSection.jsx
│   │   │   │   └── ScrollRouteSection.jsx
│   │   │   ├── map/
│   │   │   │   ├── HazardLayer.jsx
│   │   │   │   └── RouteLayer.jsx
│   │   │   └── routes/
│   │   │       ├── VehicleSelector.jsx
│   │   │       ├── RouteTypeToggle.jsx
│   │   │       ├── FeedbackModal.jsx
│   │   │       └── SosPanel.jsx
│   │   ├── services/
│   │   │   ├── api.js                # REST calls to the backend
│   │   │   └── supabaseRealtime.js   # Realtime subscription setup
│   │   └── styles/
│   ├── public/
│   ├── index.html
│   ├── package.json
│   ├── tailwind.config.js
│   ├── vite.config.js
│   └── .env.example                  # VITE_BACKEND_URL, VITE_MAPBOX_TOKEN, VITE_SUPABASE_URL/ANON_KEY
│
├── mobile-app/                       # Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── map_route_screen.dart
│   │   │   ├── fleet_dashboard_screen.dart
│   │   │   └── feedback_screen.dart
│   │   ├── widgets/
│   │   │   ├── vehicle_selector.dart
│   │   │   ├── route_type_toggle.dart
│   │   │   └── sos_button.dart
│   │   └── services/
│   │       ├── api_client.dart
│   │       └── realtime_client.dart
│   ├── pubspec.yaml
│   └── .env.example
│
├── hardware/                         # Pi4 firmware, kept out of the two deployed apps
│   ├── telemetry_reader.py           # MPU-6050 + GPS polling, local threshold check
│   ├── sos_trigger.py
│   └── config.py                     # device_id, API base URL, API key
│
├── docs/
│   └── ASPHR_Rebuild_Implementation_Plan.md   # this plan
│
└── README.md
```

Notes:
- `backend/data/rajkot.graphml` and `backend/ml/hazard_model.pkl` are the two pre-built artifacts from Sections 5 and 6 — commit them so the deployed backend never rebuilds either live.
- `backend/db/schema.sql` and `seed.sql` are what you actually run against the Supabase SQL editor; keep them in the repo as the source of truth rather than clicking through the dashboard by hand.
- Each app folder (`backend/`, `frontend-web/`, `mobile-app/`) gets its own `.env.example` so Railway/Render, Vercel, and the Flutter build each get exactly the env vars they need — never share the service role key into `frontend-web/` or `mobile-app/`.
