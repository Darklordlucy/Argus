# Asphr — Intelligent Hazard-Aware Dynamic Routing Engine (Flutter Mobile App)

Asphr is a full-stack spatial intelligence and dynamic navigation platform built for complex urban road networks like Mumbai. It fuses real-time vehicle IoT telemetry, machine learning inference (PyTorch LSTM + Scikit-Learn GBM), and spatial graph algorithms to compute personalized, hazard-aware routes.

---

## 📱 Key Mobile App Modules

### 1. Interactive Route Engine (`lib/screens/route_planner_screen.dart`)
- **Multi-Objective Strategies**:
  - **Fastest**: Travel time minimization with proactive PyTorch LSTM 30-min traffic speed forecast penalty.
  - **Safest**: Hazard-weighted path blending ML hazard prediction (70%) with live DB scores (30%), scaled by weather severity.
  - **Straightest**: Custom A* with angular bearing deviation penalty ($1 + \Delta\theta \times 2.5$).
  - **Popular**: Scenic routing rewarding segments near high-density POIs.
- **Vehicle Profile Constraints**:
  - **Car**: Unrestricted city routing.
  - **Bike**: Excludes motorways and trunk roads for rider safety.
  - **Truck**: Restricted to roads $\ge 3\text{m}$ width; avoids residential shortcuts.
  - **Supercar**: Excludes speed bumps and unclassified road surfaces.

### 2. Real-Time IoT Telemetry & Hazard Heatmap (`lib/screens/iot_heatmap_screen.dart`)
- 3-axis accelerometer waveform ($\text{Acc}_x, \text{Acc}_y, \text{Acc}_z$) visualizer.
- PostGIS spatial segment snapper (`ST_DWithin`).
- WebSocket live `hazard_alert` broadcast stream with 2-hour auto-TTL expiry.

### 3. Machine Learning Inference Dashboard (`lib/screens/ml_dashboard_screen.dart`)
- **Traffic Forecaster**: PyTorch LSTM (2-layer, hidden_dim=32, 4-step temporal window).
- **Hazard Predictor**: Scikit-Learn Gradient Boosting on 23-feature vector (vibration magnitude, traffic speed, weather, temporal signals, POI density).

### 4. RLHF Spatial Feedback Loop (`lib/screens/rlhf_feedback_screen.dart`)
- 5-dimension spatial rating collector: Hazard Accuracy, Ride Comfort, Unmapped Hazards, Route Efficiency, Overall Recommendation.

### 5. SOS Emergency Crash Response (`lib/screens/sos_emergency_screen.dart`)
- Gyroscope & accelerometer high G-force crash detector ($>4.0\text{G}$ spike).
- Automatic PostGIS geofencing to the nearest hospital node in Mumbai (e.g. Lilavati Hospital).

---

## 🎨 Theme & Styling

- **Obsidian Dark Background**: `#070A11`
- **Cyber Cyan Accent**: `#00F2FE`
- **Hazard Severity Palette**: Severe Red (`#FF3B30`), Rough Orange (`#FF9500`), Moderate Yellow (`#FFCC00`), Smooth Green (`#30D158`)
- **Glassmorphism**: Backdrop blur with subtle neon border glow (`#151C2E`)

---

## 🛠️ Stack & Architecture

- **Framework**: Flutter 3.0+ (Dart)
- **State Management**: Provider
- **Charts & Graphics**: CustomPainter (Waveforms, Custom Map Renderer)
- **Design Tokens**: `lib/theme/app_theme.dart`
