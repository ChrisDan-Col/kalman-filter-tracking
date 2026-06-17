# Parachute Feature Extraction and Kalman Filter Tracking

This project implements two computer vision tasks on a parachute image sequence: shape and texture feature extraction, and Kalman filter-based object tracking.

## Task 1 — Feature Extraction (`Task1_Feature_Christian_Arroyo.m`)

Extracts shape and texture descriptors from segmented parachute objects across the image sequence:

- **Shape features** (via `regionprops`): solidity, non-compactness, circularity, and eccentricity — characterising the parachute silhouette geometry.
- **Texture features** (HOG — Histogram of Oriented Gradients): gradient magnitudes and directions computed via `imgradient`, accumulated into 4 directional bins (0°, 45°, 90°, 135°).

Features are extracted per frame and visualised to show how the parachute's appearance changes during descent.

## Task 2 — Kalman Filter Tracking (`Task2_Tracking_Christian_Arroyo.m`)

Implements a Kalman filter to track the parachute centroid across consecutive frames:

- **State vector**: position (x, y) and velocity (vx, vy).
- **Prediction step** (`kalmanPredict.m`): propagates state forward using a constant-velocity motion model.
- **Update step** (`kalmanUpdate.m`): corrects the predicted state using the observed centroid from segmentation.

The tracker handles frame-to-frame association and visualises the predicted vs. observed trajectory overlay on the image sequence.

> `kalmanPredict.m` and `kalmanUpdate.m` are helper functions from the CMP9135 course workshop materials (University of Lincoln); their implementation is retained as provided.

## Data

- **`parachute/images/`** — PNG image sequence
- **`parachute/GT/`** — binary ground-truth masks used to extract centroids for tracking

## Tools

MATLAB Image Processing Toolbox, `regionprops`, `imgradient`

---

**Module:** Computer Vision (CMP9135) — University of Lincoln, School of Computer Science  
**Submitted as:** Assessment 2 | Academic Year 2025/2026
