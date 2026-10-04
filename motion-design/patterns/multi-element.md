# <span id="前言">Multi-Element Patterns</span>

## Stagger Recipes <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### List Items <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Slide up 20px + fade (200ms, ease-out); stagger 40-60ms; total <400ms for 8 items

| Personality | Duration | Stagger | Easing |
|------------|---------|---------|--------|
| Playful | 250ms | 60ms | ease-out-back |
| Premium | 350ms | 80ms | (0.4, 0, 0.2, 1) |
| Corporate | 200ms | 50ms | (0.2, 0, 0, 1) |
| Energetic | 150ms | 30ms | ease-out-expo |

### Grid Cards <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Scale from 95% + fade (250ms, ease-out); stagger 50-80ms reading order; +20ms per new row
- Shadow 50ms after card. Alt patterns: center-out, column-first, random

### Navigation Items <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Slide from side + fade (180ms, ease-out); stagger 30-50ms; total <300ms

### Dashboard Widgets <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
```
0ms   — Skeletons visible
100ms — Hero metric (250ms, ease-out)
200ms — Widgets begin (200ms each, 60ms stagger)
350ms — Hero complete, chart draws (300ms)
500ms — All landed
650ms — Ambient pulse begins
```

## Coordinated Sequences <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### Modal with Content <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
0ms: backdrop dims (200ms) → 50ms: modal scales 95%→100% (300ms) → 200ms: title → 280ms: body → 350ms: buttons → 400ms: close button. Content in reading order.

### Tab Switch <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
0ms: indicator slides (250ms, ease-in-out) + old fades (150ms) → 100ms: new content from tab direction (200ms) → 150ms: elements stagger (40ms)

### Accordion <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
Expand: arrow rotates (150ms) + height expands (250ms) + content fades at 50ms (200ms); siblings shift (200ms). Collapse: reverse, ease-in.

### Page Transition <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
Current slides left+fades (300ms, ease-in) → new from right (400ms, ease-out, 100ms delay) → hero scales in → content staggers (50ms). Optional shared element morph (400ms).

### Drag and Drop <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
Drag: lift (scale 1.03, 150ms); others shift (200ms). Drop: settle (scale 1.0, 200ms); gaps close.

## Choreography Rules <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### Timing Overlap <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
0%=methodical | 25%=brisk (standard) | 50%=fluid | 75%=rapid (energetic)

### Group Rules <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Same easing family; different durations/delays fine
- Exception: secondary/ambient can differ

### Shared Origin <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
Motion from trigger point; closer=first; farther=more delay

### Counter-Motion <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Hero Does | Counter-Motion |
|-----------|---------------|
| Slides right | Background left (20-30%) |
| Scales up | Shadow spreads |
| Lifts up | Shadow drops+softens |
| Rotates CW | Ambient CCW |
| Expands | Siblings compress |

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
