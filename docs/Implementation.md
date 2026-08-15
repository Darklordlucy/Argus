# Reverse Engineering & Implementation Plan: Asphr System Architecture

---

## Executive Summary & System Blueprint

**Asphr** is an intelligent, multi-objective spatial routing engine and real-time IoT hazard monitoring system built specifically for complex urban road networks (such as Mumbai). The system fuses real-time telemetry from vehicle sensors, dual machine learning models (PyTorch LSTM and Scikit-Learn Gradient Boosting), and dynamic spatial graph algorithms (NetworkX + PostGIS) to compute customized routes based on travel preferences and vehicle profiles.

This document serves as the complete, step-by-step reverse engineering implementation plan to recreate the entire Asphr project from scratch, structured strictly in sequence:
1. **Tools & Infrastructure Setup**
2. **Database Architecture & Table Schemas (with SQL DDL Queries)**
3. **Backend Core & Processing Engines**
4. **API Gateway & WebSocket Layer**
5. **Frontend Application Layer**

---

## 1. Tools, Libraries & Development Environment

### 1.1 Backend & Data Engineering Tools
- **Python 3.11+**: Primary programming runtime for high-concurrency async web servers and ML inference.
- **FastAPI**: Modern, async ASGI web framework for building performant REST APIs and WebSocket endpoints.
- **Uvicorn**: High-performance ASGI server implementation using `uvloop` and `httptools`.
- **SQLAlchemy 2.0 (Async) & GeoAlchemy2**: Object-Relational Mapper providing spatial extension support for PostGIS geometries.
- **asyncpg & psycopg2-binary**: PostgreSQL database drivers for async operation and spatial binary serialization.
- **NetworkX**: In-memory MultiDiGraph library for spatial graph representation and graph algorithm execution.
- **OSMnx**: OpenStreetMap integration tool to download, simplify, project, and cache urban street networks.
- **Shapely**: High-performance spatial geometry manipulation library (Point, LineString, Polygon operations).
- **SciPy / KD-Tree**: Spatial indexing library used for rapid coordinate-to-graph-node nearest-neighbor lookup.
- **APScheduler**: Advanced Python Scheduler for background recurring cron jobs.
- **httpx**: Fully async HTTP client for querying external APIs (Mapbox, OpenWeatherMap, TomTom).
- **pydantic-settings**: Environment variable parser and configuration validator.

### 1.2 Machine Learning Infrastructure
- **PyTorch (`torch`)**: Deep learning framework used to execute the 2-layer LSTM sequence model for 30-minute traffic speed forecasting.
- **Scikit-Learn (`scikit-learn`)**: Machine learning library running the Gradient Boosting Regressor model for road hazard probability estimation.
- **NumPy & Pandas**: Array processing and tabular feature matrix manipulation.
- **Joblib**: Model serialization tool to load pre-trained Scikit-Learn `.pkl` model artifacts.

### 1.3 Database & Spatial Storage
- **Supabase / PostgreSQL 15+**: Relational database storage engine.
- **PostGIS 3+**: Spatial database extension enabling spatial data types (`GEOMETRY`), spatial indexes (`GIST`), and spatial SQL functions (`ST_DWithin`, `ST_Intersects`, `ST_AsText`).

### 1.4 Frontend Tech Stack
- **Node.js 18+ & Vite 8**: Fast frontend build tool and development environment for React.
- **React 19**: Modern declarative UI framework.
- **React Router v7**: Client-side single-page application routing library.
- **Mapbox GL JS (v3.25) & react-map-gl (v8.1)**: WebGL-powered interactive mapping library for vector tiles, spatial GeoJSON rendering, and custom route overlays.
- **Tailwind CSS (v3.4) & PostCSS**: Utility-first CSS framework with custom design tokens.
- **Lucide React**: Crisp UI iconography library.
- **Oxlint**: Modern high-speed JavaScript/JSX linter.

---

## 2. Database Architecture & Table Creation Queries

The database relies on PostgreSQL with the **PostGIS** extension activated to support spatial geometries (`Point`, `LineString`, `Polygon`) in SRID 4326 (WGS 84 coordinate system).

### Step 2.1: Database Initialization
1. Connect to PostgreSQL / Supabase instance.
2. Enable spatial queries by executing the PostGIS extension script:
   `CREATE EXTENSION IF NOT EXISTS postgis;`

### Step 2.2: Table Creation Queries & Schema Specifications

#### 1. `road_segments` Table
Stores the static OpenStreetMap road network graph edges, physical geometry, and metadata attributes.
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

#### 2. `segment_hazards` Table
Stores dynamic hazard scores per segment generated by ML inference, IoT telemetry, or external APIs with automated time-to-live (TTL) expiration.
```sql
CREATE TABLE segment_hazards (
    id SERIAL PRIMARY KEY,
    segment_id INT REFERENCES road_segments(id) ON DELETE CASCADE,
    hazard_score FLOAT NOT NULL CHECK (hazard_score BETWEEN 0 AND 1),
    hazard_type VARCHAR(50),
    confidence FLOAT,
    source VARCHAR(20),
    recorded_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP
);

CREATE INDEX idx_hazards_segment ON segment_hazards(segment_id);
CREATE INDEX idx_hazards_time ON segment_hazards(recorded_at);
```

#### 3. `iot_readings` Table
Raw high-frequency accelerometer and gyroscope sensor telemetry sent by vehicle hardware fleets.
```sql
CREATE TABLE iot_readings (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    segment_id INT REFERENCES road_segments(id),
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    accel_x FLOAT,
    accel_y FLOAT,
    accel_z FLOAT,
    gyro_x FLOAT,
    gyro_y FLOAT,
    gyro_z FLOAT,
    vibration_level FLOAT,
    road_condition VARCHAR(20),
    timestamp TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_iot_device ON iot_readings(device_id);
CREATE INDEX idx_iot_location ON iot_readings USING GIST(
    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
);
CREATE INDEX idx_iot_time ON iot_readings(timestamp);
```

#### 4. `traffic_conditions` Table
Real-time traffic speeds and congestion classifications (0 = Free Flow, 4 = Gridlock) mapped to network segments.
```sql
CREATE TABLE traffic_conditions (
    id SERIAL PRIMARY KEY,
    segment_id INT REFERENCES road_segments(id),
    speed_kmh FLOAT,
    congestion_level INT CHECK (congestion_level BETWEEN 0 AND 4),
    traffic_volume INT,
    recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_traffic_segment ON traffic_conditions(segment_id);
CREATE INDEX idx_traffic_time ON traffic_conditions(recorded_at);
```

#### 5. `weather_grid` Table
Geographic polygon cells (0.05° resolution grid) storing ambient environmental conditions.
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

#### 6. `popular_places` Table
Points of Interest (POIs) used to bias scenic/popular pathfinding routes.
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

#### 7. `vehicle_profiles` Table
Physical and operational constraints governing vehicle-aware graph edge filtering.
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
```

#### 8. `sos_alerts` Table
Emergency accident events triggered by onboard accelerometer/gyroscope spikes.
```sql
CREATE TABLE sos_alerts (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(50),
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    triggered_at TIMESTAMP DEFAULT NOW(),
    resolved BOOLEAN DEFAULT FALSE,
    hospital_notified BOOLEAN DEFAULT FALSE
);
```

#### 9. `route_feedback` Table
Post-trip spatial driver feedback collected for RLHF model fine-tuning.
```sql
CREATE TABLE route_feedback (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(100),
    start_point GEOMETRY(Point, 4326),
    end_point GEOMETRY(Point, 4326),
    route_geometry GEOMETRY(LineString, 4326),
    route_type VARCHAR(20),
    rating INT CHECK (rating BETWEEN 1 AND 5),
    feedback_text TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 3. Step-by-Step Backend Reverse Engineering

### Step 3.1: Environment & Project Setup
1. Create a Python backend workspace structured into modular directories:
   - `app/config.py`: Environment configuration loader reading `.env` variables (Database URL, API keys for Mapbox, TomTom, OpenWeatherMap).
   - `app/models/`: Database models (`db_models.py`), PyTorch model (`traffic_forecaster.py`), Scikit-Learn predictor (`hazard_predictor.py`), and pathfinder (`route_optimizer.py`).
   - `app/algorithms/`: OSMnx graph builder and spatial indexer (`graph_builder.py`).
   - `app/services/`: Services for geocoding, IoT handling, background scheduling, weather grid updates, and WebSocket broadcasting.
   - `app/routers/`: Individual API route handlers.

2. Configure database access via SQLAlchemy async engine using `asyncpg` for non-blocking database queries.

### Step 3.2: Spatial Graph Ingestion Engine (`graph_builder.py`)
1. **Fetch OSM Street Network**: Use OSMnx to download the driveable street network for Mumbai using a predefined bounding box or polygon query.
2. **Network Simplification & Projection**: Retain topology while removing intermediate non-intersection nodes. Project graph coordinates to WGS84 (EPSG:4326).
3. **GraphML Cache Persistence**: Save the simplified network graph as a `.graphml` file on local disk to ensure instant application boot times without re-downloading OSM data.
4. **In-Memory NetworkX MultiDiGraph**: Load the cached graph into memory as a `nx.MultiDiGraph` instance. Extract node coordinates (latitude, longitude) and store them in a SciPy `cKDTree` index for $O(\log N)$ spatial snapping.
5. **Database Node/Edge Sync**: Iterate over graph edges and execute spatial `INSERT` statements into PostgreSQL `road_segments` table if segments do not yet exist.

### Step 3.3: Dual Machine Learning Inference Pipelines

#### A. Traffic Speed Forecaster (`traffic_forecaster.py`)
1. Build a PyTorch `nn.Module` containing a 2-layer LSTM network with a hidden dimension of 32.
2. Design the input sequence format: accepts a 4-step temporal sequence (45-minute lookback of average segment speeds).
3. Output target: scalar representing predicted segment speed 30 minutes in the future.
4. Load saved PyTorch model checkpoint weights (`.pt`) on startup. Include fallbacks to default speed limits if sequence data is insufficient.

#### B. Hazard Probability Predictor (`hazard_predictor.py`)
1. Implement a Scikit-Learn `GradientBoostingRegressor` model wrapper.
2. Construct a 23-feature vector per segment combining:
   - Telemetry signals: Vibration magnitude, peak acceleration values.
   - Traffic metrics: Current speed, speed deviation, congestion level (0-4).
   - Road attributes: Surface flag, lanes, speed bump presence, road classification.
   - Environmental factors: Rain intensity, visibility distance, temperature.
   - Temporal signals: Hour of day, day of week cyclical sine/cosine encodings.
3. Load the pre-trained `joblib` `.pkl` model file.
4. Provide single-segment and batch prediction functions that return a probability score bounded between $0.0$ (safe) and $1.0$ (severely hazardous).

### Step 3.4: Dynamic Graph Enrichment & Weight Formulation Engine
Every 5 minutes, run a background job that updates all edge attributes in the in-memory NetworkX graph according to four distinct mathematical cost functions:

1. **Fastest Route Objective**:
   - Calculates base travel time from segment length and current speed.
   - Applies an exponential penalty factor based on PyTorch LSTM predicted speed drops:
     $$\text{Weight} = \frac{\text{Length}}{\text{Speed}_{\text{current}} / 3.6} \times \left(1 + \max\left(0, \frac{\text{Speed}_{\text{limit}} - \text{Speed}_{\text{predicted}}}{\text{Speed}_{\text{limit}}}\right)\right)$$

2. **Safest Route Objective**:
   - Blends ML predicted hazard score ($70\%$) with live database hazards ($30\%$).
   - Scales cost by weather severity multipliers:
     $$\text{Weight} = \text{Length} \times (1 + H_{\text{blended}}) \times (1 + C_{\text{weather}})$$

3. **Straightest Route Objective**:
   - Computes angular bearing differences between incoming and outgoing edges at each node.
   - Enforces a turn penalty factor ($\Delta\theta \times 2.5$) inside a custom A* pathfinder.

4. **Popular Route Objective**:
   - Executes spatial proximity queries against the `popular_places` table.
   - Reduces edge cost proportionally to the density of nearby Points of Interest within a 500-meter radius.

### Step 3.5: Vehicle Constraint Graph Pruning Engine
Before initiating pathfinding for a request, dynamically clone and filter the graph based on the selected `vehicle_type`:
- **Bike**: Strip out highways, motorways, and trunk roads.
- **Truck**: Remove edges with width restrictions $<3.0\text{m}$, low height clearances, or residential status.
- **Supercar**: Filter out any edge flagged with speed bumps (`has_speed_bump = True`) or unpaved/rough surface classifications.
- **Car**: Unrestricted routing on all standard road segments.

### Step 3.6: Background Scheduler (`scheduler.py`)
Initialize APScheduler with `AsyncIOScheduler` and register three periodic async background tasks:
1. **Graph Enrichment (Every 5 minutes)**: Queries current DB hazards, traffic, weather, runs PyTorch/GBM batch inference, and updates NetworkX edge weights.
2. **Weather Grid Refresh (Every 10 minutes)**: Calls OpenWeatherMap API for Mumbai grid coordinates and writes updated polygon records into `weather_grid`.
3. **Hazard Expiration Cleanup (Every 5 minutes)**: Executes `DELETE FROM segment_hazards WHERE expires_at < NOW()`.

---

## 4. API Gateway & WebSocket Architecture

Construct FastAPI route modules under `/api/v1` and a WebSocket hub under `/ws`.

### 4.1 Route Computation API (`/api/v1/routes`)
- `POST /api/v1/routes/compute`
  - Accepts: Origin coordinates (`lat`, `lon`), Destination coordinates (`lat`, `lon`), `vehicle_type` (`bike`, `car`, `truck`, `supercar`), and `route_type` (`fastest`, `safest`, `straightest`, `popular`).
  - Action: Snaps coordinates to graph nodes via KD-Tree, applies vehicle graph filter, runs Dijkstra/A* shortest path on enriched graph weights, extracts segment geometries, formats turn-by-turn navigation steps, hazard alerts, and weather summaries.
  - Returns: GeoJSON FeatureCollection containing path geometry, total distance (meters), estimated time (seconds), average hazard score, and step instructions.
- `POST /api/v1/routes/feedback`
  - Accepts: User ID, start/end points, route LineString geometry, route type, 1-5 rating, and feedback comments. Writes to `route_feedback` table.
- `GET /api/v1/routes/popular`
  - Returns list of popular places and POIs filtered by city.

### 4.2 Geocoding API (`/api/v1/geocode`)
- `GET /api/v1/geocode/search?q={query}`
  - Action: Forwards search string to Mapbox Geocoding API. If rate-limited or unfulfilled, falls back to OpenStreetMap Nominatim API with rate limiting.
- `GET /api/v1/geocode/reverse?lat={lat}&lon={lon}`
  - Action: Converts lat/lon pair into reverse geocoded street address.

### 4.3 IoT & Telemetry API (`/api/v1/iot`)
- `POST /api/v1/iot/telemetry`
  - Accepts: Hardware payload (`device_id`, `latitude`, `longitude`, `accel_x`, `accel_y`, `accel_z`, `gyro_x`, `gyro_y`, `gyro_z`).
  - Action: Computes vibration magnitude vector $\sqrt{x^2 + y^2 + z^2}$. Executes PostGIS `ST_DWithin` spatial query to snap reading to nearest `road_segments` record. Writes to `iot_readings`. If vibration exceeds threshold, inserts a new record into `segment_hazards` with a 2-hour expiration and triggers a WebSocket hazard broadcast.
- `POST /api/v1/iot/sos`
  - Accepts: Emergency trigger payload (`device_id`, `latitude`, `longitude`). Inserts record into `sos_alerts` and flags nearby hospital dispatch notifications.

### 4.4 Custom Database Spatial Query API (`/api/v1/custom-db`)
- `GET /api/v1/custom-db/hazards?min_lat={}&min_lon={}&max_lat={}&max_lon={}`
  - Accepts: Viewport bounding box parameters.
  - Action: Executes PostGIS spatial query returning all active hazards within the current map viewport for rendering live map heatmaps.

### 4.5 Real-Time WebSocket Server (`/ws`)
- Maintains a thread-safe connection manager (`ConnectionManager`) tracking all active client WebSocket connections.
- Enables clients to subscribe to live system events.
- Broadcasts JSON payloads for:
  - `hazard_alert`: Potholes or obstacle detections from IoT fleet.
  - `weather_update`: Real-time rain/fog updates.
  - `graph_refreshed`: Notification that graph weights have been re-calculated.

### 4.6 Health Check API (`/health`)
- `GET /health`
  - Validates PostgreSQL database connection status, in-memory graph node count, edge count, and ML model loaded states.

---

## 5. Frontend Development Blueprint

The frontend is built as a single-page application (SPA) using React 19, Vite, Tailwind CSS, and Mapbox GL JS.

### Step 5.1: Project Initialization & Configuration
1. Initialize Vite project with React template.
2. Install dependencies: `mapbox-gl`, `react-map-gl`, `react-router-dom`, `lucide-react`, `tailwindcss`, `postcss`, `autoprefixer`.
3. Configure Tailwind CSS with custom color schemes (dark slate themes, vibrant accents for hazard color ramps: green $\rightarrow$ yellow $\rightarrow$ orange $\rightarrow$ red).
4. Configure Mapbox access token in `.env`.

### Step 5.2: API & WebSocket Service Layer (`src/services/api.js`)
1. Create unified HTTP request helper functions mapping to FastAPI endpoints (`computeRoute`, `searchGeocode`, `fetchViewportHazards`, `submitFeedback`, `sendSOS`).
2. Implement `WebSocketService`: Establishes persistent WebSocket connection to `ws://backend/ws`, handles ping/pong keep-alives, auto-reconnects on dropouts, and dispatches custom browser events when `hazard_alert` messages arrive.

### Step 5.3: Layout & Common Components
1. **`Navbar.jsx`**: Top navigation header containing branding logo, live system status badge (connected/disconnected), and links to main pages:
   - `Home` (`/`)
   - `Maps` (`/maps`)
   - `Routes` (`/routes`)
   - `Services` (`/services`)
2. **Landing Page Modules**:
   - `HeroContent.jsx`: Call to action banner highlighting hazard-aware spatial routing.
   - `IntroAsphr.jsx`: Narrative overview of the problem statement.
   - `CrisisStatsSection.jsx`: Statistical dashboard showcasing road hazard metrics and accidents solved.
   - `ChaptersSection.jsx`: Deep dive into system architecture chapters.
   - `ScrollRouteSection.jsx`: Interactive scroll-driven animation demonstrating route optimization.

### Step 5.4: Page Implementations

#### 1. Landing Page (`Home.jsx`)
Assembles landing page components with responsive hero sections, feature grids, and interactive previews.

#### 2. Live Spatial Hazard Map Page (`Maps.jsx`)
- Render full-screen Mapbox map using `react-map-gl`.
- Attach map viewport movement event listeners (`onMoveEnd`) to extract current bounding box (`min_lat`, `min_lon`, `max_lat`, `max_lon`).
- Fetch active hazards within bounding box via `/api/v1/custom-db/hazards` and render as GeoJSON point and heat map layers with dynamic color scaling based on `hazard_score`.
- Integrate real-time WebSocket listener: when a new IoT hazard alert arrives, display an animated popup toast on the map at the exact coordinates and auto-center the viewport if selected.
- Include a floating **SOS Alert Trigger Panel**: button to dispatch emergency coordinates to `/api/v1/iot/sos` with confirmation state.

#### 3. Intelligent Multi-Objective Routing Page (`Routes.jsx`)
- Build control panel sidebar:
  - **Geocoding Search Inputs**: Origin and Destination autocompletion inputs querying `/api/v1/geocode/search`.
  - **Vehicle Selector Tabs**: Bike, Car, Truck, Supercar (updates vehicle constraints).
  - **Routing Objective Toggle**: Fastest, Safest, Straightest, Popular.
- Execute route computation request to `/api/v1/routes/compute`.
- Display Mapbox map with computed GeoJSON route LineString layer. Color-code path segments based on local hazard intensity.
- Render turn-by-turn direction instructions panel with distance, estimated time, and hazard warnings.
- Render post-route **RLHF Feedback Modal**: 5-question rating form allowing users to submit ratings and comments to `/api/v1/routes/feedback`.

#### 4. System Telemetry & Services Page (`Services.jsx`)
- Real-time dashboard displaying system operational health, backend API response latencies, active database connection stats, APScheduler job execution logs, PyTorch/GBM model load states, and connected IoT device counts.

---

## 6. End-to-End Execution Sequence Summary

```
┌────────────────────────────────────────────────────────────────────────┐
1. Setup Database: Run SQL DDL scripts to create PostGIS spatial tables.
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
2. Build Spatial Graph: Run OSMnx script to cache Mumbai GraphML network.
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
3. Load Machine Learning Models: Initialize PyTorch LSTM & sklearn GBM.
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
4. Start FastAPI Gateway & Background Scheduler: Run Uvicorn ASGI server.
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
5. Start Background Jobs: Enrich NetworkX weights every 5 min.
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
6. Launch React Frontend: Vite dev server with Mapbox & WebSockets.
└────────────────────────────────────────────────────────────────────────┘
```

This reverse engineering document outlines every tool, table creation query, architectural pattern, backend service, API endpoint, and frontend component necessary to reconstruct the complete Asphr platform.
