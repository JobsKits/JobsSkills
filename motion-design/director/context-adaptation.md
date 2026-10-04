# <span id="前言">Context Adaptation</span>

## Platform Scaling <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Platform | Duration Modifier | Complexity | Physics |
|----------|------------------|------------|---------|
| Desktop | 1.0x (baseline) | Full | All types |
| Tablet | 0.9x | Standard | Most types |
| Mobile | 0.8x | Reduced (1-2 properties) | Snappy only |
| Watch | 0.6x | Minimal (1 property) | None |
| TV/Kiosk | 1.3x | Full | All types |

**Mobile rules**: prefer opacity + transform; touch feedback <100ms; reduce stagger budgets by 30%; avoid parallax
**Desktop opportunities**: hover states, cursor tracking, multi-column stagger, spatial choreography

## Accessibility <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### prefers-reduced-motion <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Original Motion | Reduced Alternative |
|----------------|-------------------|
| Slide entrance | Opacity fade only |
| Bounce/spring | Instant or simple ease-out |
| Parallax | Static positioning |
| Auto-playing | Paused, user-initiated |
| Complex choreography | Single fade |
| Continuous ambient | Static or subtle opacity pulse |

Reduced motion means: remove spatial movement, keep opacity, remove spring easing, reduce duration 50%+, never auto-play loops.

### Vestibular Triggers (avoid or provide alternatives) <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Large-scale zoom, full-screen position transitions
- Spinning elements >100px, parallax >2 layers, rapid direction changes

### Cognitive Accessibility <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Same interaction = same animation every time
- Pause controls for animations >5 seconds
- Don't convey critical info through motion alone

## Performance Budgets <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Tier | Properties | Max Elements |
|------|-----------|-------------|
| Optimal | transform, opacity | Unlimited (GPU) |
| Good | + color, clip-path | 10-15 |
| Acceptable | + width, height, margin | 5-8 |
| Avoid | box-shadow, border-radius, filter | 1-3 |

- Target 60fps (16.67ms/frame); animation logic <10ms/frame
- will-change sparingly; keep animated elements <20 per viewport
- Stagger reduces peak load vs simultaneous
- Fallback: 30fps acceptable for ambient

## Content Type Adaptation <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Content Type | Personality | Duration | Motion Density |
|-------------|-------------|----------|---------------|
| Financial | Corporate/Premium | 250-500ms | Low |
| Social media | Playful | 150-300ms | Medium |
| Enterprise SaaS | Corporate | 200-400ms | Low |
| Gaming | Energetic | 100-250ms | High |
| Healthcare | Corporate/Calm | 300-600ms | Very low |
| E-commerce | Varies | 200-400ms | Medium |
| Editorial | Premium | 350-600ms | Low |
| Children's apps | Playful | 150-300ms | High |

## Responsive Motion <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Container Width | Max Displacement | Duration |
|----------------|-----------------|----------|
| <400px | 20% of width | 0.8x |
| 400-800px | 25% of width | 1.0x |
| 800-1200px | 20% of width | 1.0x |
| >1200px | 15% of width | 1.1x |

- Small viewport: sequential, one element at a time
- Medium: standard stagger, 2-3 columns
- Large: full choreography, center-out stagger, parallax

## Dark Mode <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Reduce motion intensity 10-20% (bright on dark = more impact)
- Subtler ambient motion; careful with opacity values
- Avoid pure white flashes

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
