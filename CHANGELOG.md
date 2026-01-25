//
//  CHANGELOG.md
//  Fisheye
//
//  Created by Hanton Yang on 1/25/26.
//

# Changelog

All notable changes to Fisheye will be documented in this file.

## [2.0.0] - 2026-01-25

### Changed - BREAKING
- **Migrated from OpenGL ES to Metal rendering**
  - Replaced GLKView with MTKView
  - Implemented Metal shaders for YUV-to-RGB conversion
  - Added simd-based matrix math utilities
  - Requires iOS 15.0+ and Metal-capable devices

### Fixed
- Fixed black screen issue by correcting sphere triangle winding order for inward-facing geometry
- Fixed texture creation errors by adding Metal compatibility flag to video pixel buffers

### Removed
- OpenGL ES renderer and related files (GLProgram, Shader, GLKMatrix4 conversions)
- GLSL shader files (replaced with Metal shading language)

## [1.0.0] - [Previous Date]

### Added
- Initial release with OpenGL ES rendering
- 360-degree video playback support
- Touch-based rotation controls
