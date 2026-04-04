import React, { useEffect, useState } from 'react';
import SkeletonLoader from './SkeletonLoader';
import API_URL from '../config';

const Subscriptions = () => {
  const [items, setItems] = useState([]);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  const [plans, setPlans] = useState([]);
  const [plansError, setPlansError] = useState(null);
  const [savingPlans, setSavingPlans] = useState(false);

  const BASE = API_URL;

  const authHeaders = () => {
    const token = localStorage.getItem('adminToken');
    return {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    };
  };

  const fetchPlans = async () => {
    setPlansError(null);
    try {
      const res = await fetch(`${BASE}/api/subscriptions/admin/plans`, {
        headers: authHeaders(),
      });
      const text = await res.text();
      let data;
      try {
        data = text ? JSON.parse(text) : null;
      } catch (_) {
        data = null;
      }
      if (!res.ok) {
        const msg = (data && data.message)
          ? data.message
          : `Failed (HTTP ${res.status})`;
        setPlansError(msg);
        setPlans([]);
        return;
      }
      setPlans(Array.isArray(data) ? data : []);
    } catch (e) {
      setPlansError(e?.message || 'Failed to load plans');
      setPlans([]);
    }
  };

  const savePlans = async () => {
    setSavingPlans(true);
    setPlansError(null);
    try {
      const res = await fetch(`${BASE}/api/subscriptions/admin/plans`, {
        method: 'PUT',
        headers: authHeaders(),
        body: JSON.stringify({ plans }),
      });
      const text = await res.text();
      let data;
      try {
        data = text ? JSON.parse(text) : null;
      } catch (_) {
        data = null;
      }
      if (!res.ok) {
        const msg = (data && data.message)
          ? data.message
          : `Failed (HTTP ${res.status})`;
        setPlansError(msg);
        return;
      }
      setPlans(Array.isArray(data) ? data : plans);
    } catch (e) {
      setPlansError(e?.message || 'Failed to save plans');
    } finally {
      setSavingPlans(false);
    }
  };

  const fetchSubscriptions = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${BASE}/api/subscriptions/admin`, {
        headers: authHeaders(),
      });
      const text = await res.text();
      let data;
      try {
        data = text ? JSON.parse(text) : null;
      } catch (_) {
        data = null;
      }
      if (!res.ok) {
        const message = (data && data.message)
          ? data.message
          : (text && text.trim().startsWith('<!DOCTYPE'))
            ? `Failed (HTTP ${res.status}) - backend returned HTML (likely not redeployed)`
            : `Failed (HTTP ${res.status})`;
        setError(message);
        setItems([]);
        return;
      }
      setItems(Array.isArray(data) ? data : []);
    } catch (e) {
      setError(e?.message || 'Failed to load subscriptions');
      setItems([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSubscriptions();
    fetchPlans();
  }, []);


  const onPlanChange = (id, patch) => {
    setPlans((prev) => prev.map((p) => (p.id === id ? { ...p, ...patch } : p)));
  };

  const addPlan = () => {
    // Add a new plan with temporary id
    const newId = 'plan' + Math.floor(Math.random() * 1000000);
    setPlans((prev) => [
      ...prev,
      {
        id: newId,
        label: '',
        priceInr: 0,
        durationDays: 30,
        currency: 'INR',
        active: true,
        _isNew: true,
      },
    ]);
  };

  const deletePlan = async (id) => {
    if (!window.confirm('Delete this plan?')) return;
    try {
      const res = await fetch(`${BASE}/api/subscriptions/admin/plans/${id}`, {
        method: 'DELETE',
        headers: authHeaders(),
      });
      if (!res.ok) {
        const text = await res.text();
        let data;
        try { data = text ? JSON.parse(text) : null; } catch { data = null; }
        alert(data?.message || `Failed (HTTP ${res.status})`);
        return;
      }
      setPlans((prev) => prev.filter((p) => p.id !== id));
    } catch (e) {
      alert(e?.message || 'Failed to delete plan');
    }
  };

  const saveNewPlans = async () => {
    // Save any new plans (with _isNew flag)
    const newPlans = plans.filter((p) => p._isNew);
    for (const p of newPlans) {
      if (!p.id || !p.label || !p.durationDays) {
        alert('Fill all fields for new plan');
        return;
      }
      try {
        const res = await fetch(`${BASE}/api/subscriptions/admin/plans`, {
          method: 'POST',
          headers: authHeaders(),
          body: JSON.stringify({
            id: p.id,
            label: p.label,
            priceInr: p.priceInr,
            durationDays: p.durationDays,
            currency: p.currency,
            active: p.active,
          }),
        });
        if (!res.ok) {
          const text = await res.text();
          let data;
          try { data = text ? JSON.parse(text) : null; } catch { data = null; }
          alert(data?.message || `Failed (HTTP ${res.status})`);
          return;
        }
      } catch (e) {
        alert(e?.message || 'Failed to add plan');
        return;
      }
    }
    // Remove _isNew flag and reload
    fetchPlans();
  };

  const formatDuration = (days) => {
    const n = Number(days);
    if (!Number.isFinite(n) || n <= 0) return '-';
    if (n === 365) return '1 year';
    if (n % 30 === 0) return `${Math.round(n / 30)} month(s)`;
    return `${n} day(s)`;
  };

  return (
    <div className="users">
      <div className="users-header">
        <div>
          <h1>Subscriptions</h1>
          <p>View all user subscriptions.</p>
        </div>
        <div className="header-filters">
          <button className="action-btn activate-btn" onClick={fetchSubscriptions}>
            Refresh
          </button>
        </div>
      </div>

      <div className="users-table" style={{ marginBottom: 18 }}>
        <div style={{ padding: 16, borderBottom: '1px solid #e5e7eb' }}>
          <h2 style={{ margin: 0, fontSize: 16 }}>Plan prices</h2>
          <p style={{ margin: '6px 0 0', color: '#6b7280', fontSize: 13 }}>
            Admin can modify subscription prices here.
          </p>
          {plansError && (
            <p style={{ margin: '10px 0 0', color: '#b00020', fontSize: 13 }}>{plansError}</p>
          )}
        </div>


        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>LABEL</th>
              <th>DURATION (days)</th>
              <th>PRICE (INR)</th>
              <th>ACTIVE</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {plans.length === 0 ? (
              <tr><td colSpan={6} style={{ textAlign: 'center', padding: 24, color: '#6b7280' }}>No plans</td></tr>
            ) : plans.map((p) => (
              <tr key={p.id}>
                <td>
                  <input
                    type="text"
                    value={p.id}
                    disabled={!p._isNew}
                    onChange={(e) => onPlanChange(p.id, { id: e.target.value })}
                    style={{ width: 70, padding: '6px 8px', border: '1px solid #e5e7eb', borderRadius: 8 }}
                  />
                </td>
                <td>
                  <input
                    type="text"
                    value={p.label}
                    onChange={(e) => onPlanChange(p.id, { label: e.target.value })}
                    style={{ width: 110, padding: '6px 8px', border: '1px solid #e5e7eb', borderRadius: 8 }}
                  />
                </td>
                <td>
                  <input
                    type="number"
                    min="1"
                    value={p.durationDays ?? 30}
                    onChange={(e) => onPlanChange(p.id, { durationDays: Number(e.target.value) })}
                    style={{ width: 70, padding: '6px 8px', border: '1px solid #e5e7eb', borderRadius: 8 }}
                  />
                </td>
                <td>
                  <input
                    type="number"
                    min="0"
                    value={p.priceInr ?? 0}
                    onChange={(e) => onPlanChange(p.id, { priceInr: Number(e.target.value) })}
                    style={{ width: 90, padding: '6px 8px', border: '1px solid #e5e7eb', borderRadius: 8 }}
                  />
                </td>
                <td>
                  <input
                    type="checkbox"
                    checked={p.active !== false}
                    onChange={(e) => onPlanChange(p.id, { active: e.target.checked })}
                  />
                </td>
                <td>
                  <button className="action-btn" style={{ color: '#b00020' }} onClick={() => deletePlan(p.id)}>
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        <div style={{ padding: 16, display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
          <button className="action-btn" onClick={addPlan} disabled={savingPlans}>
            Add Plan
          </button>
          <button className="action-btn" onClick={fetchPlans} disabled={savingPlans}>
            Refresh plans
          </button>
          <button className="action-btn activate-btn" onClick={saveNewPlans} disabled={savingPlans}>
            Save New
          </button>
          <button className="action-btn activate-btn" onClick={savePlans} disabled={savingPlans}>
            {savingPlans ? 'Save All…' : 'Save All'}
          </button>
        </div>
      </div>

      <div className="users-table">
        <table>
          <thead>
            <tr>
              <th>USER (EMAIL)</th>
              <th>PLAN</th>
              <th>STATUS</th>
              <th>START</th>
              <th>EXPIRES</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={5} style={{ textAlign: 'center', padding: 24, color: '#6b7280' }}>Loading…</td></tr>
            ) : error ? (
              <tr><td colSpan={5} style={{ textAlign: 'center', padding: 24, color: '#b00020' }}>{error}</td></tr>
            ) : items.length === 0 ? (
              <tr><td colSpan={5} style={{ textAlign: 'center', padding: 24, color: '#6b7280' }}>No subscriptions found.</td></tr>
            ) : items.map((s) => (
              <tr key={s.id || s._id || s.userId}>
                <td style={{ fontFamily: 'monospace', fontSize: 12 }}>
                  {s.userEmail || (s.userId && typeof s.userId === 'object' ? s.userId.email : s.userId) || '-'}
                </td>
                <td>{s.planId || '-'}</td>
                <td>{s.status || '-'}</td>
                <td>{s.periodStart ? new Date(s.periodStart).toLocaleString() : '-'}</td>
                <td>{s.periodEnd ? new Date(s.periodEnd).toLocaleString() : '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {!loading && !error && items.length > 0 && (
        <p style={{ fontSize: 13, color: '#6b7280', padding: '8px 0', textAlign: 'right' }}>
          Total: {items.length}
        </p>
      )}
    </div>
  );
};

export default Subscriptions;