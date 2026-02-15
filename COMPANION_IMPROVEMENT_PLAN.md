# Companion Improvement Implementation Roadmap

This roadmap sequences the companion-system modernization into low-to-high risk phases, with explicit operational guardrails for each release step.

## Global SLO Baseline (applies to all phases)

- **RTT target:** p50 <= 120ms, p95 <= 250ms for companion <-> server ping.
- **Reconnect success rate target:** >= 98% within 10 seconds after transient disconnect.
- **Dropped-input rate target:** <= 0.5% of valid user actions.
- **Session stability target:** >= 99.5% sessions complete without fatal protocol/server errors.

---

## Phase A — Observability, Rejection Messages, Reconnect UX (Low Risk)

### Scope
- Add end-to-end telemetry for connection lifecycle, command acceptance/rejection, and reconnect attempts.
- Add explicit rejection messages with machine-readable reasons (`cooldown`, `invalid_state`, `rate_limited`, `malformed`).
- Improve reconnect UX (backoff messaging, reconnect status banner, retry hints).

### Success Metrics (Phase Exit)
- RTT p95 <= 250ms with live dashboard visibility.
- Reconnect success rate >= 98% in chaos tests (forced socket drops).
- Dropped-input rate <= 0.5%, and >= 99% of rejections include structured reason code.
- Session stability >= 99.5% with zero crash-on-malformed-message incidents.

### Backward Compatibility Strategy
- Keep existing message envelope valid; add optional fields only (`reason_code`, `trace_id`, `reconnect_hint`).
- Consumers must ignore unknown fields.
- Introduce protocol capability flags in hello/join ack so old clients can still operate without rejection-code parsing.

### Rollback Trigger
- Reconnect success falls below 95% for 15 minutes, or malformed-message handling increases disconnections by >1%.

### Operational Checklist
- Enable feature flags: `obs_v1`, `reject_reason_v1`, `reconnect_ux_v1`.
- Confirm dashboards/alerts are active before traffic ramp.
- Run canary (5% sessions), then 25%, then 100%.
- Validate log volume/cost impact.
- If rollback triggered: disable flags, verify reconnect returns to baseline, preserve logs for postmortem.

---

## Phase B — Protocol Sequencing and State Unification

### Scope
- Introduce monotonically increasing sequence IDs for action/state messages.
- Unify authoritative state machine across game/server/companion (`connecting`, `ready`, `active`, `paused`, `ended`, `reconnecting`).
- Deduplicate and reorder-tolerant processing based on sequence and session epoch.

### Success Metrics (Phase Exit)
- RTT unchanged from Phase A baseline (no >10ms regression p95).
- Reconnect success rate >= 98.5% with deterministic state recovery.
- Dropped-input rate <= 0.3% (improved via de-dupe and ordered apply).
- Session stability >= 99.7%; protocol mismatch incidents < 0.1% of sessions.

### Backward Compatibility Strategy
- Dual protocol parser: accept legacy unsequenced packets and new sequenced packets.
- Server emits format based on negotiated capabilities (`protocol_v1`, `protocol_v2_seq`).
- Maintain legacy state labels via mapping table until all clients upgraded.

### Rollback Trigger
- Sequence desync incidents > 0.5% sessions or duplicate action execution detected in production.

### Operational Checklist
- Deploy parser first (read-new/write-old), then enable write-new for canary.
- Verify sequence-gap and replay alerts.
- Run synthetic out-of-order packet tests in staging and canary.
- Keep legacy writer path hot for one full release cycle.
- On rollback: force `protocol_v1`, clear seq caches for affected sessions, announce incident window.

---

## Phase C — Minimap Delta Transport and Render Optimizations

### Scope
- Replace full-frame minimap payloads with delta updates + periodic keyframes.
- Add render pipeline optimizations (batch draw, interpolation tuning, adaptive frame pacing).
- Add recovery path when deltas are missed (request keyframe/resync).

### Success Metrics (Phase Exit)
- RTT p95 <= 230ms under load (network savings should help).
- Reconnect success rate >= 98.5% including delta-resync path.
- Dropped-input rate <= 0.3% (no interaction regressions from render changes).
- Session stability >= 99.7%; minimap desync complaints < 0.2% sessions.

### Backward Compatibility Strategy
- Support `minimap_full_v1` and `minimap_delta_v2` concurrently.
- Keyframe contains version + absolute snapshot so legacy decode remains unaffected.
- Capability negotiation controls whether client receives full or delta stream.

### Rollback Trigger
- Delta decode failures > 0.3% sessions, or client render CPU/power usage regresses by >20% median.

### Operational Checklist
- Ship decoder first behind `minimap_delta_v2` flag.
- Canary by platform class (desktop/mobile) to detect device-specific rendering regressions.
- Monitor payload size, FPS, battery/CPU telemetry.
- Keep periodic full snapshot fallback enabled during ramp.
- On rollback: disable delta flag, force full snapshots, invalidate stale delta buffers.

---

## Phase D — Gameplay Combo Features and Visual Overhaul

### Scope
- Add combo-oriented companion gameplay interactions (chain bonuses, synchronized assists, contextual effects).
- Refresh companion visual design, feedback cues, and impact animations.
- Ensure mechanics are server-authoritative with explicit cooldown/state validation.

### Success Metrics (Phase Exit)
- RTT p95 remains <= 250ms after visual/gameplay additions.
- Reconnect success rate >= 98% (no regression from feature complexity).
- Dropped-input rate <= 0.4% while new abilities are active.
- Session stability >= 99.5%; combo-feature error rate < 0.5% of activations.

### Backward Compatibility Strategy
- Gate new combo actions behind capability bit (`combo_v1`).
- Old clients receive translated fallback events (standard action equivalents).
- Keep legacy UI path and assets while new visual theme rolls out incrementally.

### Rollback Trigger
- Balance or reliability issues: combo actions cause >2% invalid-state rejections or crash rate increases by >0.2%.

### Operational Checklist
- Separate rollout flags for mechanics and visuals (`combo_logic_v1`, `visual_overhaul_v1`).
- Run gameplay A/B and monitor fairness/retention metrics.
- Validate accessibility (contrast, motion reduction, touch targets).
- Provide live-ops kill switch for each new ability.
- On rollback: disable combo flags, remap queued combo actions to legacy equivalents, clear temporary buffs safely.

---

## Phase E — Scaling, Storage Migration, and Hardening

### Scope
- Migrate ephemeral in-memory session/state to durable scalable storage (e.g., Redis + persistent backing where needed).
- Add horizontal scaling controls, rate limiting, abuse protection, and disaster-recovery runbooks.
- Harden protocol/security boundaries (authN/authZ, schema validation, load shedding).

### Success Metrics (Phase Exit)
- RTT p95 <= 260ms at 3x current peak concurrent sessions.
- Reconnect success rate >= 99% across node failover events.
- Dropped-input rate <= 0.3% under peak and failover scenarios.
- Session stability >= 99.9% with zero data-loss incidents in migration window.

### Backward Compatibility Strategy
- Dual-write session metadata to old and new stores during migration.
- Read-path shadowing and consistency checks before read cutover.
- Message schema remains versioned; old/new nodes interoperate via stable wire contract.

### Rollback Trigger
- Data consistency mismatch > 0.1% between old/new stores, or failover reconnect success < 97%.

### Operational Checklist
- Pre-migration backup/snapshot + restoration test.
- Enable dual-write, then shadow-read validation.
- Gradual read cutover by shard/tenant.
- Run failover game-day (node kill, network partition, regional degradation).
- On rollback: revert reads to old store, keep dual-write until reconciliation complete, execute incident communication + repair plan.

---

## Recommended Delivery Cadence

1. Complete Phase A and hold one stable release cycle.
2. Deliver Phase B before any high-frequency transport optimization.
3. Ship Phase C only after sequence/state foundations are proven.
4. Build player-facing novelty in Phase D once reliability is established.
5. Finish with Phase E to support long-term scale and resilience.
