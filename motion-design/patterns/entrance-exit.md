# <span id="前言">Entrance & Exit Patterns</span>

## Entrance Strategies <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 1. Direct Entrance (Slide In) <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Position + opacity; offset 20-40px + opacity 0 → final position + opacity 1
- Easing: ease-out; duration 200-350ms

| Personality | Offset | Easing | Overshoot |
|------------|--------|--------|-----------|
| Playful | 30-50px | ease-out-back | 10-15% |
| Premium | 15-25px | (0.4, 0, 0.2, 1) | 0% |
| Corporate | 20-30px | (0.2, 0, 0, 1) | 0-3% |
| Energetic | 40-80px | ease-out-expo | 15-25% |

Direction: below=arrival, right=forward, left=back, above=dropdown/authority.

### 2. Emergent Entrance (Scale In) <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Scale + opacity; start 85-95% + opacity 0 → 100% + opacity 1
- Duration 250-400ms

| Personality | Start Scale | Easing | Overshoot |
|------------|------------|--------|-----------|
| Playful | 70-80% | ease-out-back | 10-20% |
| Premium | 95-98% | (0.4, 0, 0.2, 1) | 0% |
| Corporate | 90-95% | (0.2, 0, 0, 1) | 0-3% |
| Energetic | 50-70% | ease-out-expo | 15-30% |

Best for: modals, dialogs, notifications, popovers, tooltips.

### 3. Reveal Entrance (Clip/Mask) <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- clip-path or mask + opacity; 300-500ms, ease-out
- Directions: top-to-bottom (dramatic), L-to-R (reading order), center-out (focus), edge-in (contained)

### 4. Assembled Entrance (Multi-Part) <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Parts arrive from different positions; stagger 50-100ms; total 300-600ms
- Best for: icon assembly, logo builds, data viz construction

## Exit Strategies <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

**Rule**: Exits = 65-75% of entrance duration.

### 1. Direct Exit (Slide Out) <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Offset 20-40px + opacity 0; ease-in; 150-250ms

### 2. Dissolve Exit (Fade Out) <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Opacity (+ optional scale to 98%); ease-in; 150-250ms
- Best for: gentle departures, backgrounding, crossfades

### 3. Collapse Exit (Shrink Out) <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Scale 85-95% + opacity 0; ease-in; 150-250ms
- Best for: deletion, closing modals, dismissal

### 4. Transfer Exit (Move Away) <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Position toward destination + scale shrink; ease-in-out; 250-400ms
- Best for: add-to-cart, save-to-collection, move-to-folder

## Entrance-Exit Continuity <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Eye follows naturally from exit to entrance
- Exit point near entry point when possible
- 100-150ms timing overlap between exit and entrance
- Same easing family for paired entrance-exit

## Common Recipes <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### Notification Slide-In <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
1. Slide from right + opacity (250ms, ease-out)
2. Overshoot 3-5% (corporate) or 10-15% (playful)
3. Icon appears (100ms, 50ms delay)

### Toast Dismiss <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
1. Slide toward edge + opacity (180ms, ease-in)
2. Remaining toasts shift up (200ms, ease-in-out)

### Dropdown Open <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
1. Scale Y 0→100% (200ms, ease-out)
2. Items stagger fade in (30ms apart, 50ms after container)

### Page Transition (Forward) <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
1. Current page slides left + fades (300ms, ease-in)
2. New page from right + fades in (400ms, ease-out, 100ms delay)
3. Shared elements morph (400ms, ease-in-out)

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
