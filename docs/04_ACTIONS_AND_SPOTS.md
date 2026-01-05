# Actions and Spots Catalog

This document describes the parametric play system used in INSTALL.

## Overview

INSTALL uses a **parametric editing system** instead of freeform drawing. Coaches edit plays by:
1. Selecting from **named spots** on the court (e.g., "top", "wing_l")
2. Choosing **action types** from a catalog (e.g., "ball_screen", "cut")
3. Configuring **fromSpot**, **toSpot**, and optional **target position**

This approach ensures:
- **Phone legibility:** No tiny, hand-drawn diagrams
- **Consistency:** All plays render similarly
- **Role clarity:** Players understand their specific actions
- **Coach familiarity:** Uses native basketball terminology

## Spot Definitions

All spots use **normalized coordinates** [0..1] on a half-court:
- **X-axis:** 0 = left sideline, 1 = right sideline, 0.5 = center
- **Y-axis:** 0 = baseline, 1 = half court line, 0.5 = free throw line extended

### Spot Map

| Spot ID          | Display Name        | X    | Y    | Description                    |
|------------------|---------------------|------|------|--------------------------------|
| `top`            | Top                 | 0.5  | 0.85 | Top of the key                 |
| `slot_l`         | Left Slot           | 0.25 | 0.75 | Left slot (extended top)       |
| `slot_r`         | Right Slot          | 0.75 | 0.75 | Right slot (extended top)      |
| `wing_l`         | Left Wing           | 0.15 | 0.60 | Left wing (FT line extended)   |
| `wing_r`         | Right Wing          | 0.85 | 0.60 | Right wing (FT line extended)  |
| `corner_l`       | Left Corner         | 0.05 | 0.15 | Left corner (3-point line)     |
| `corner_r`       | Right Corner        | 0.95 | 0.15 | Right corner (3-point line)    |
| `shortcorner_l`  | Left Short Corner   | 0.10 | 0.35 | Left short corner (between)    |
| `shortcorner_r`  | Right Short Corner  | 0.90 | 0.35 | Right short corner (between)   |
| `elbow_l`        | Left Elbow          | 0.28 | 0.55 | Left elbow (FT line)           |
| `elbow_r`        | Right Elbow         | 0.72 | 0.55 | Right elbow (FT line)          |
| `lowpost_l`      | Left Low Post       | 0.25 | 0.25 | Left low post (block)          |
| `lowpost_r`      | Right Low Post      | 0.75 | 0.25 | Right low post (block)         |
| `dunker_l`       | Left Dunker         | 0.20 | 0.12 | Left dunker spot (below block) |
| `dunker_r`       | Right Dunker        | 0.80 | 0.12 | Right dunker spot (below block)|

### Visual Reference

```
                    Half Court (y=1.0)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│                                                │
│         slot_l       top       slot_r         │
│            ●          ●           ●            │
│                                                │
│   elbow_l                         elbow_r     │
│      ●                               ●         │
│                                                │
│ wing_l                               wing_r   │
│   ●                                     ●      │
│                                                │
│ short_l                             short_r   │
│   ●                                     ●      │
│                                                │
│ low_l                                 low_r    │
│   ●                                     ●      │
│                                                │
│ dunker_l                           dunker_r   │
│   ●                                     ●      │
│                                                │
│ corner_l                           corner_r   │
│   ●                                     ●      │
│                                                │
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    Baseline (y=0.0)
```

## Action Types

### Off-Ball Movement

| Action Type   | Display Name  | Requires To Spot | Requires Target | Description                                  |
|---------------|---------------|------------------|-----------------|----------------------------------------------|
| `spot_up`     | Spot Up       | No               | No              | Stationary, ready to shoot                   |
| `cut`         | Cut           | Yes              | No              | Move from one spot to another                |
| `replace`     | Replace       | Yes              | No              | Fill a vacated spot                          |
| `lift`        | Lift          | Yes              | No              | Move up/out to extend the floor              |
| `drift`       | Drift         | Yes              | No              | Subtle shift (defensive adjustment)          |
| `decoy`       | Decoy         | No               | No              | Occupy defense without scoring intent        |

### Screens (Off-Ball)

| Action Type      | Display Name   | Requires To Spot | Requires Target | Description                              |
|------------------|----------------|------------------|-----------------|------------------------------------------|
| `screen`         | Screen         | Optional         | Yes             | Generic off-ball screen                  |
| `down_screen`    | Down Screen    | Yes              | Yes             | Screen toward the basket                 |
| `flare_screen`   | Flare Screen   | Yes              | Yes             | Screen away from the basket              |
| `ball_screen`    | Ball Screen    | Yes              | Yes             | Screen for ball handler                  |

### Ball Screens & Actions

| Action Type   | Display Name  | Requires To Spot | Requires Target | Description                                  |
|---------------|---------------|------------------|-----------------|----------------------------------------------|
| `handoff`     | Handoff       | Yes              | Yes             | Hand the ball off to target                  |
| `roll`        | Roll          | Yes              | No              | Roll to basket after screen                  |
| `pop`         | Pop           | Yes              | No              | Pop out after screen                         |
| `slip`        | Slip          | Yes              | No              | Slip screen early                            |

### Post Actions

| Action Type   | Display Name  | Requires To Spot | Requires Target | Description                                  |
|---------------|---------------|------------------|-----------------|----------------------------------------------|
| `post_up`     | Post Up       | Yes              | No              | Establish position in the post               |
| `duck_in`     | Duck In       | Yes              | No              | Quick move to the post                       |
| `flash`       | Flash         | Yes              | No              | Quick move to high post/elbow                |
| `seal`        | Seal          | No               | No              | Hold defensive position in post              |

## PlayerAction Data Structure

```typescript
interface PlayerAction {
  position: number; // 1-5
  actionType: ActionType;
  fromSpotId: string; // Required: starting spot
  toSpotId?: string; // Optional: ending spot (required if involves movement)
  targetPosition?: number; // Optional: 1-5 (required for screens/handoffs)
  hasBall: boolean;
}
```

### Examples

**Example 1: Spot Up**
```json
{
  "position": 2,
  "actionType": "spot_up",
  "fromSpotId": "wing_r",
  "hasBall": false
}
```

**Example 2: Cut**
```json
{
  "position": 3,
  "actionType": "cut",
  "fromSpotId": "wing_l",
  "toSpotId": "dunker_l",
  "hasBall": false
}
```

**Example 3: Ball Screen**
```json
{
  "position": 5,
  "actionType": "ball_screen",
  "fromSpotId": "elbow_r",
  "toSpotId": "top",
  "targetPosition": 1,
  "hasBall": false
}
```

**Example 4: Roll**
```json
{
  "position": 5,
  "actionType": "roll",
  "fromSpotId": "top",
  "toSpotId": "dunker_r",
  "hasBall": false
}
```

## Step Structure

A **Step** represents a single moment in a play. Each step contains:
- 5 **PlayerActions** (one for each position)
- A **label** (e.g., "Ball Screen Right")
- An optional **note** (coach instruction)
- An **enabled** flag (allow disabling steps)
- Optional **emphasisPosition** (which position to highlight)

```typescript
interface Step {
  index: number; // 0-based step order
  label: string;
  note?: string;
  enabled: boolean;
  emphasisPosition?: number; // 1-5
  playerActions: PlayerAction[]; // Exactly 5
}
```

### Example Step: Horns Ball Screen

```json
{
  "index": 1,
  "label": "Ball Screen Right",
  "note": "5 sets ball screen for 1",
  "enabled": true,
  "emphasisPosition": null,
  "playerActions": [
    {
      "position": 1,
      "actionType": "cut",
      "fromSpotId": "top",
      "toSpotId": "wing_r",
      "hasBall": true
    },
    {
      "position": 2,
      "actionType": "lift",
      "fromSpotId": "wing_r",
      "toSpotId": "corner_r",
      "hasBall": false
    },
    {
      "position": 3,
      "actionType": "spot_up",
      "fromSpotId": "wing_l",
      "hasBall": false
    },
    {
      "position": 4,
      "actionType": "spot_up",
      "fromSpotId": "elbow_l",
      "hasBall": false
    },
    {
      "position": 5,
      "actionType": "ball_screen",
      "fromSpotId": "elbow_r",
      "toSpotId": "top",
      "targetPosition": 1,
      "hasBall": false
    }
  ]
}
```

## Rendering Logic

### Court Coordinate Transformation

```swift
// Normalize spot to canvas
func toCanvasCoordinates(normalized: CGPoint, canvasSize: CGSize) -> CGPoint {
    let padding: CGFloat = 40
    let courtWidth = canvasSize.width - (padding * 2)
    let courtHeight = canvasSize.height - (padding * 2)

    let x = padding + (normalized.x * courtWidth)
    let y = padding + ((1.0 - normalized.y) * courtHeight) // Invert Y

    return CGPoint(x: x, y: y)
}
```

### Player Token Rendering

```swift
// For each playerAction in step
let spot = Spots.spot(for: playerAction.fromSpotId)
let canvasPoint = CourtGeometry.toCanvasCoordinates(
    normalized: CGPoint(x: spot.x, y: spot.y),
    canvasSize: canvasSize
)

// Render circle at canvasPoint
Circle()
    .fill(playerAction.hasBall ? .orange : .blue)
    .frame(width: 36, height: 36)
    .overlay(Text("\(playerAction.position)").foregroundColor(.white))
    .position(canvasPoint)
```

### Movement Arrows

If `playerAction.toSpotId` exists:
```swift
let fromSpot = Spots.spot(for: playerAction.fromSpotId)
let toSpot = Spots.spot(for: playerAction.toSpotId!)

let fromPoint = CourtGeometry.toCanvasCoordinates(normalized: CGPoint(x: fromSpot.x, y: fromSpot.y), canvasSize: canvasSize)
let toPoint = CourtGeometry.toCanvasCoordinates(normalized: CGPoint(x: toSpot.x, y: toSpot.y), canvasSize: canvasSize)

// Draw arrow from fromPoint to toPoint
Path { path in
    path.move(to: fromPoint)
    path.addLine(to: toPoint)
}
.stroke(Color.gray, lineWidth: 2)
```

## Editing UI (Coach)

When a coach edits a step, they see forms like:

**Position 1:**
- Action Type: [Dropdown: cut, spot_up, ball_screen, ...]
- From Spot: [Dropdown: top, wing_l, corner_r, ...]
- To Spot: [Dropdown: top, wing_r, ...] (if action involves movement)
- Target: [Dropdown: 1, 2, 3, 4, 5] (if action requires target)
- Has Ball: [Toggle]

This ensures:
- No freeform drawing required
- All plays are legible on phones
- Consistent visual language
- Easy to duplicate and modify

## Defense Scenarios

Defense uses the **same system**:
- Spots represent defensive positions (guarding spots)
- Actions like `drift`, `replace`, `spot_up` represent rotations
- Steps represent: alignment → trigger → rotation

Example: Drop Coverage
1. **Step 0:** Initial man-to-man alignment
2. **Step 1:** Screen recognition (5 shows, 1 goes under)
3. **Step 2:** Drop coverage (5 drops to paint, 1 recovers)

## Templates

Templates are **preloaded sets/defense scenarios** that ship with the app. Coaches:
1. **Cannot create blank plays** (v1 constraint)
2. **Duplicate templates** to their team playbook
3. **Edit duplicates** via spot/action dropdowns
4. **Publish** to notify players

Templates are defined in:
- `mobile/ios/INSTALL/Resources/templates/offense_templates.json`
- `mobile/ios/INSTALL/Resources/templates/defense_templates.json`

See those files for 12+ offense templates and 5 defense scenarios.
