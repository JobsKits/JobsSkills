# <span id="前言">Quality Checklist</span>

## Visual Quality <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- [ ] Elements >40px for motion, >100px for detail
- [ ] Readable at full speed without slow-motion
- [ ] Clear primary, secondary, ambient layers
- [ ] Counter-motion for balance where needed
- [ ] Natural arcs (unless intentionally mechanical)
- [ ] 1/3 rule (distance): no unbroken motion >1/3 container
- [ ] 1/3 rule (density): max 1/3 elements active simultaneously

## Technical Quality <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- [ ] No linear easing on spatial movement
- [ ] Duration matches element type table
- [ ] Ease-out entrances, ease-in exits
- [ ] Duration proportional to distance
- [ ] Entrance duration >= exit duration
- [ ] Not opacity-only for important state changes
- [ ] Stagger total <500ms
- [ ] Follow-through: child elements offset 50-150ms

## Emotional Quality <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- [ ] Target emotion identified before properties
- [ ] Personality archetype matches brand
- [ ] Setup → action → resolution structure
- [ ] Intensity matches interaction importance
- [ ] Consistent: same interaction = same motion
- [ ] Appropriate on 100th viewing

## Performance Quality <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- [ ] Primary motion uses transform + opacity
- [ ] <20 animated elements per viewport
- [ ] No layout-triggering properties animated
- [ ] Elements staggered, not simultaneous
- [ ] Maintains 60fps (30fps acceptable for ambient)

## Accessibility Quality <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- [ ] prefers-reduced-motion alternative provided
- [ ] No vestibular triggers without alternative
- [ ] Same interaction = same animation
- [ ] Critical info not motion-only
- [ ] Animations >5s are pausable

## Severity Tiers <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### CRITICAL <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Linear easing on spatial movement
- Opacity-only for important states
- Exceeds 1/3 screen rule
- Missing primary layer
- Stagger >500ms
- Layout property animation causing jank

### HIGH <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Missing secondary layer
- Duration mismatch with element type
- Wrong directional easing
- Inconsistent personality
- No follow-through
- Missing reduced-motion alternative

### MEDIUM <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>
- Missing ambient layer
- No anticipation phase
- Overshoot mismatch
- Could use better arcs
- Missing counter-motion

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
