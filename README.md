# PicPak Open

PicPak Open is a Flutter-based image processing and transmission tool designed for a low-resolution, 4-colour e-ink display device. It provides a full pipeline for importing, generating, processing, previewing, and transmitting images over BLE.

---

# Core Concept

All images follow a single pipeline:

1. Image source (file import or generated swatch/note)
2. Resize + fit strategy
3. Optional filters (brightness, contrast, style adjustments)
4. Dithering (convert RGB → 4-colour palette)
5. Framebuffer generation
6. Preview rendering
7. Packetisation
8. BLE transmission

The pipeline is intentionally kept source-agnostic. Whether the input is a photo, a swatch, or a generated note, it is processed identically once converted into image bytes.

---

# Current Features

## Image Sources
- File import (any image via file picker)
- Procedural swatches (test patterns)
  - gradients
  - spectrum maps
  - high contrast patterns
  - colour stress tests
- Text notes ("post-it" style generated images)

## Image Processing
- Resize strategies:
  - crop
  - scale
- Image adjustments:
  - brightness
  - contrast
- Filter system (extensible)

## Dithering
Pluggable dither engine system:

- None (direct palette mapping, best for text/UI)
- Floyd–Steinberg
- Atkinson
- Ordered dithering
- Sierra

Each dithering method converts RGB input into a fixed 4-colour palette:
- Black
- White
- Yellow
- Red

---

## Preview System
- Framebuffer-based preview renderer
- Optional device palette simulation mode (preview only)
- Real-time reprocessing on change

---

## Transmission (in theory, untested on device yet)
- Framebuffer is packed into compact binary format
- BLE packetisation layer handles chunking
- MD5 validation packet included for integrity check
- Supports streaming to e-ink device display protocol

---

# Architecture Overview

## Packages
- `picpak_core`
  - shared types (palette index, device constants, etc.)

- `picpak_image`
  - image pipeline
  - dithering engines
  - framebuffer generation
  - preview rendering
  - encoding + packing

- Flutter app
  - UI layer
  - image selection and swatch generation
  - slider-based adjustment system
  - BLE transport

---

# Design Principles

- Single pipeline for all image sources
- No special-case rendering paths
- Dithering is pluggable and independent
- Preview is derived from framebuffer, not separate logic
- Device transmission format is fixed and isolated from UI logic

---

# Known Limitations

- Text rendering is basic (no wrapping or layout engine)
- Image processing is CPU-heavy and can cause latency on web builds
- No GPU acceleration currently used
- Preview rendering is simplified compared to final device appearance
- No persistent project/session saving yet

---

# Future Improvements

## Rendering & UI
- Improved text rendering (wrapping, auto-fit, alignment)
- True layout system for notes and templates
- UI overhaul for better visual hierarchy

## Image Generation
- More procedural templates:
  - calendars
  - reminders
  - QR codes
  - structured “cards”

## Device Features
- Multi-image storage on device
- “Post-it note” sync system
- Metadata support for frames

## UX Improvements
- Presets for filters + dithering combinations
- Palette-aware adjustment tools
- Better preview simulation of real panel behaviour
- Performance optimisations for real-time slider interaction

---

# Summary

PicPak is evolving into a lightweight image-to-e-ink content pipeline rather than a traditional image editor. The focus is on fast generation, predictable output, and consistent transformation into a constrained 4-colour display format.

# AI Assistance Disclosure
Portions of this project were developed with the assistance of AI tooling
for tasks such as architecture planning, documentation, boilerplate generation,
refactoring assistance, and code review.

All generated code is reviewed, tested, and maintained by human contributors.
Final design and implementation decisions remain the responsibility of the
project maintainers.