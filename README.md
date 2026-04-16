# COAL Rush Hour Traffic Jam Game

A high-performance implementation of the classic **Rush Hour** puzzle game using **Assembly Langauge** and the **Irvine32** library. This project features a custom-built rendering engine, real-time collision detection, and automated puzzle state management to provide a smooth, interactive gaming experience.

---

## Features

* **Interactive Gameplay:** Smooth mouse and keyboard controls for moving vehicles and navigating through challenging traffic gridlocks.
* **Dynamic Graphics:** Real-time rendering using the **Irvine32** library for high-quality 2D visuals and UI elements.
* **Custom Game Engine:** Built using modular Assembly components, including specialized utilities for color management and coordinate mapping.
* **Audio Integration:** Features background music and sound effects to enhance player immersion.
* **State Management:** Robust logic for detecting winning conditions, handling illegal moves, and tracking vehicle orientations (horizontal vs. vertical).

---

## Technical Architecture

The project is structured to separate game logic from the rendering and hardware abstraction layers.

---

## Logic & Algorithms

### 1. Grid-Based Movement

The game board is represented as a 2D coordinate system. Logic ensures vehicles only move along their fixed axes (X for horizontal, Y for vertical) and prevents overlapping with other cars or exiting board boundaries.

### 2. Rendering Pipeline

The system utilizes a custom drawing utility built on top of Irvine32 to render the grid and vehicles:

* **Buffer Management:** Draws game states to an off-screen buffer to prevent flickering.
* **Primitive Drawing:** Custom implementations for drawing rectangles and shapes representing different vehicle types.

### 3. Build & Dependency Management

A dedicated shell script handles the installation of required system libraries to ensure cross-platform compatibility on Linux environments.

---

## Getting Started

### Prerequisites

* Irvine32.inc
* Irvine32.lib
* Visual Studio Community


## Contributors

* **Huzaifa Mudassar**
* **i24-0050**
