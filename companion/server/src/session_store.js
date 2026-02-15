export class SessionStore {
  constructor({ sessionExpiryMs, nowFn = () => Date.now() }) {
    this.sessionExpiryMs = sessionExpiryMs;
    this.nowFn = nowFn;
    this.byCode = new Map();
    this.codeByToken = new Map();
  }

  create({ code, reconnectToken }) {
    const now = this.nowFn();
    const session = {
      code,
      reconnectToken,
      game: null,
      companion: null,
      createdAt: now,
      lastActivityAt: now,
      expiresAt: now + this.sessionExpiryMs,
      dropsThisWave: 0,
      suppliesThisWave: 0,
      radarsThisWave: 0,
      empsThisWave: 0,
      lastDropAt: 0,
      lastSupplyAt: 0,
      lastRadarAt: 0,
      lastEmpAt: 0,
      rttBuckets: {
        lt50ms: 0,
        lt100ms: 0,
        lt250ms: 0,
        lt500ms: 0,
        lt1000ms: 0,
        gte1000ms: 0
      }
    };
    this.byCode.set(code, session);
    this.codeByToken.set(reconnectToken, code);
    return session;
  }

  hasCode(code) {
    return this.byCode.has(code);
  }

  inspectByCode(code) {
    const session = this.byCode.get(code);
    if (!session) return { session: null, expired: false };
    if (this.isExpired(session)) {
      this.removeByCode(code);
      return { session: null, expired: true };
    }
    return { session, expired: false };
  }

  inspectByToken(token) {
    const code = this.codeByToken.get(token);
    if (!code) return { session: null, expired: false };
    return this.inspectByCode(code);
  }

  getByCode(code, { touch = true } = {}) {
    const session = this.byCode.get(code);
    if (!session) return null;
    if (this.isExpired(session)) {
      this.removeByCode(code);
      return null;
    }
    if (touch) this.touch(session);
    return session;
  }

  getByToken(token, { touch = true } = {}) {
    const code = this.codeByToken.get(token);
    if (!code) return null;
    return this.getByCode(code, { touch });
  }

  isExpired(session, now = this.nowFn()) {
    return now >= session.expiresAt;
  }

  touch(session, now = this.nowFn()) {
    session.lastActivityAt = now;
  }

  removeByCode(code) {
    const session = this.byCode.get(code);
    if (!session) return;
    this.byCode.delete(code);
    this.codeByToken.delete(session.reconnectToken);
  }

  detachRole(code, role) {
    const session = this.getByCode(code, { touch: false });
    if (!session) return null;
    if (role === 'game') session.game = null;
    if (role === 'companion') session.companion = null;
    this.touch(session);
    return session;
  }

  resetWaveCounters(code) {
    const session = this.getByCode(code, { touch: false });
    if (!session) return null;
    session.dropsThisWave = 0;
    session.suppliesThisWave = 0;
    session.radarsThisWave = 0;
    session.empsThisWave = 0;
    this.touch(session);
    return session;
  }

  consumeAbility(code, { perWaveKey, lastAtKey, perWaveLimit, cooldownMs, now = this.nowFn() }) {
    const session = this.getByCode(code, { touch: false });
    if (!session) return { ok: false, reason: 'missing_session' };
    if (session[perWaveKey] >= perWaveLimit) return { ok: false, reason: 'wave_limit' };
    if ((now - session[lastAtKey]) < cooldownMs) return { ok: false, reason: 'cooldown' };
    session[perWaveKey] += 1;
    session[lastAtKey] = now;
    this.touch(session, now);
    return { ok: true, session, remaining: perWaveLimit - session[perWaveKey] };
  }

  recordRoundTrip(code, ms) {
    const session = this.getByCode(code, { touch: false });
    if (!session || !Number.isFinite(ms) || ms < 0) return null;
    if (ms < 50) session.rttBuckets.lt50ms += 1;
    else if (ms < 100) session.rttBuckets.lt100ms += 1;
    else if (ms < 250) session.rttBuckets.lt250ms += 1;
    else if (ms < 500) session.rttBuckets.lt500ms += 1;
    else if (ms < 1000) session.rttBuckets.lt1000ms += 1;
    else session.rttBuckets.gte1000ms += 1;
    this.touch(session);
    return session.rttBuckets;
  }

  sweepExpired(onExpire) {
    const now = this.nowFn();
    for (const [code, session] of this.byCode.entries()) {
      if (this.isExpired(session, now)) {
        if (typeof onExpire === 'function') onExpire(session);
        this.removeByCode(code);
      }
    }
  }

  entries() {
    return this.byCode.entries();
  }
}
