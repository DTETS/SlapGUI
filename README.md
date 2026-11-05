# SLAP

MATLAB GUI for aligning a 3D/4D ultrasound volume over an MRI volume and drawing tongue polygons on the coronal slice.

## Running

```matlab
addpath(genpath('path/to/SLAP'))
SlapGUI
```

Volumes are loaded from an open WASL window with **Load MRI** and **Load US**.

## Controls (main window)

- `1` / `2` / `3`: select the coronal / axial / sagittal view
- Arrows / WASD: move the US (or only the crosshair while **Lock US** is on)
- `Q` / `E`: rotate the US around the selected view's normal; `0` resets the rotation
- `,` / `.`: step through frames (while locked); `<` / `>` buttons always work
- **±2 mm AP**: move the crosshair front/back
- **View Angle − / +**: tilt the coronal plane (oblique slice), applied to both MRI and US
- **Draw polygons**: open the coronal polygon window and export measurements to Excel

## Layout

- `Ultrasound_positioning/`: main window, loading, slicing, navigation, session save/load
- `Polygon_Drawing/`: polygon window and Excel export

Imaging data and results are not part of this repository.
