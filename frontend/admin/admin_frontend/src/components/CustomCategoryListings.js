import React, { useState, useEffect, useCallback } from 'react';
import { Plus, Edit, Trash2, ArrowLeft, Eye } from 'lucide-react';
import { useNavigate, useParams } from 'react-router-dom';
import SkeletonLoader from './SkeletonLoader';
import API_URL from '../config';

const BASE = API_URL;

const STATUS_COLORS = {
  active:   { bg: '#d1fae5', color: '#065f46' },
  disabled: { bg: '#fee2e2', color: '#991b1b' },
  pending:  { bg: '#fef3c7', color: '#92400e' },
};

// ── Add / Edit Modal ─────────────────────────────────────────────────────────
const ListingModal = ({ title, initial, categoryId, onClose, onSuccess }) => {
  const [form, setForm] = useState(
    initial || { title: '', description: '', contactPhone: '', city: '', area: '', status: 'active' }
  );
  const [saving, setSaving] = useState(false);

  const set = key => e => setForm(p => ({ ...p, [key]: e.target.value }));

  const handleSubmit = async e => {
    e.preventDefault();
    if (!form.title?.trim()) { alert('Title is required'); return; }
    setSaving(true);
    try {
      const token = localStorage.getItem('adminToken');
      const url = initial
        ? `${BASE}/api/custom-categories/${categoryId}/listings/${initial._id}`
        : `${BASE}/api/custom-categories/${categoryId}/listings`;
      const res = await fetch(url, {
        method: initial ? 'PUT' : 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify(form),
      });
      if (res.ok) { onSuccess(); onClose(); }
      else { const d = await res.json(); alert(d.message); }
    } catch (ex) { alert(ex.message); }
    finally { setSaving(false); }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content modal-large" style={{ maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <h2>{title}</h2>
          <button className="close-btn" onClick={onClose}>✕</button>
        </div>
        <form onSubmit={handleSubmit} className="add-listing-form">
          <div className="form-group">
            <label>Title <span style={{ color: 'red' }}>*</span></label>
            <input value={form.title} onChange={set('title')} placeholder="Listing title" />
          </div>
          <div className="form-group">
            <label>Description</label>
            <textarea rows={3} value={form.description} onChange={set('description')} />
          </div>
          <div className="form-group">
            <label>Contact Phone</label>
            <input value={form.contactPhone} onChange={set('contactPhone')} placeholder="+49 …" />
          </div>
          <div className="form-group">
            <label>City</label>
            <input value={form.city} onChange={set('city')} />
          </div>
          <div className="form-group">
            <label>Area</label>
            <input value={form.area} onChange={set('area')} />
          </div>
          <div className="form-group">
            <label>Status</label>
            <select value={form.status} onChange={set('status')}>
              <option value="active">Active</option>
              <option value="disabled">Disabled</option>
              <option value="pending">Pending</option>
            </select>
          </div>
          <div className="form-actions">
            <button type="button" className="cancel-btn" onClick={onClose} disabled={saving}>Cancel</button>
            <button type="submit" className="create-btn" disabled={saving}>{saving ? 'Saving…' : 'Save'}</button>
          </div>
        </form>
      </div>
    </div>
  );
};

// ── View Modal ────────────────────────────────────────────────────────────────
const ViewModal = ({ item, onClose }) => (
  <div className="modal-overlay">
    <div className="modal-content" style={{ maxHeight: '90vh', overflowY: 'auto' }}>
      <div className="modal-header">
        <h2>{item.title}</h2>
        <button className="close-btn" onClick={onClose}>✕</button>
      </div>
      <div style={{ padding: '0 4px', fontSize: 14, lineHeight: 1.8 }}>
        {[['Category', item.categoryName], ['City', item.city], ['Area', item.area],
          ['Contact', item.contactPhone], ['Status', item.status],
          ['Description', item.description],
          ['Created', item.createdAt ? new Date(item.createdAt).toLocaleDateString('en-GB') : '—'],
        ].map(([label, val]) => (
          <div key={label} style={{ display: 'flex', gap: 8, marginBottom: 6 }}>
            <span style={{ color: '#6b7280', minWidth: 110 }}>{label}:</span>
            <span style={{ color: '#111827', fontWeight: 500 }}>{val || '—'}</span>
          </div>
        ))}
      </div>
      <div className="form-actions">
        <button className="cancel-btn" onClick={onClose}>Close</button>
      </div>
    </div>
  </div>
);

// ── Main Page ─────────────────────────────────────────────────────────────────
const CustomCategoryListings = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  const [category,     setCategory]     = useState(null);
  const [items,        setItems]        = useState([]);
  const [loading,      setLoading]      = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [showAdd,      setShowAdd]      = useState(false);
  const [editItem,     setEditItem]     = useState(null);
  const [viewItem,     setViewItem]     = useState(null);

  const getAuthHeaders = useCallback(
    () => ({ Authorization: `Bearer ${localStorage.getItem('adminToken')}` }),
    []
  );

  const fetchCategory = useCallback(async () => {
    try {
      const res = await fetch(`${BASE}/api/custom-categories`, { headers: getAuthHeaders() });
      if (res.ok) {
        const cats = await res.json();
        const found = cats.find(c => c._id === id);
        if (found) setCategory(found);
      }
    } catch {}
  }, [id, getAuthHeaders]);

  const fetchListings = useCallback(async () => {
    setLoading(true);
    try {
      const url = statusFilter
        ? `${BASE}/api/custom-categories/${id}/listings?status=${statusFilter}`
        : `${BASE}/api/custom-categories/${id}/listings`;
      const res = await fetch(url, { headers: getAuthHeaders() });
      if (res.ok) { const d = await res.json(); setItems(d.data || []); }
    } catch (e) { console.error(e); }
    finally { setLoading(false); }
  }, [id, statusFilter, getAuthHeaders]);

  useEffect(() => { fetchCategory(); }, [fetchCategory]);
  useEffect(() => { fetchListings(); }, [fetchListings]);

  const handleDelete = async (item) => {
    if (!window.confirm(`Delete "${item.title}"?`)) return;
    try {
      const res = await fetch(`${BASE}/api/custom-categories/${id}/listings/${item._id}`, {
        method: 'DELETE', headers: getAuthHeaders(),
      });
      if (res.ok) fetchListings();
      else alert('Failed to delete');
    } catch (e) { alert(e.message); }
  };

  const handleStatusChange = async (item, newStatus) => {
    try {
      const res = await fetch(`${BASE}/api/custom-categories/${id}/listings/${item._id}/status`, {
        method: 'PATCH',
        headers: { ...getAuthHeaders(), 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus }),
      });
      if (res.ok) {
        setItems(prev => prev.map(i => i._id === item._id ? { ...i, status: newStatus } : i));
      } else { alert('Failed to update status'); }
    } catch (e) { alert(e.message); }
  };

  const sc = st => STATUS_COLORS[st] || STATUS_COLORS.disabled;

  return (
    <div className="listings">
      <div className="listings-header">
        <div>
          <button onClick={() => navigate('/categories')}
            style={{ background: 'none', border: 'none', color: '#6b9976', cursor: 'pointer',
              display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10, fontSize: 14 }}>
            <ArrowLeft size={16} /> Back to Categories
          </button>
          <h1>{category?.icon || '📋'} {category?.name || 'Custom'} Listings</h1>
          <p>Total: {items.length}</p>
        </div>
        <div className="header-actions" style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
          <select
            value={statusFilter}
            onChange={e => setStatusFilter(e.target.value)}
            style={{ padding: '8px 12px', borderRadius: 8, border: '1px solid #e5e7eb', fontSize: 14, cursor: 'pointer' }}
          >
            <option value="">All Status</option>
            <option value="active">Active</option>
            <option value="disabled">Disabled</option>
            <option value="pending">Pending</option>
          </select>
          <button className="add-listing-btn" onClick={() => setShowAdd(true)}>
            <Plus size={20} /> New Listing
          </button>
        </div>
      </div>

      {loading ? (
        <SkeletonLoader rows={5} columns={6} type="table" />
      ) : items.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 40 }}>No listings found.</div>
      ) : (
        <div className="listings-table">
          <table>
            <thead>
              <tr>
                <th>TITLE</th>
                <th>CITY</th>
                <th>CONTACT</th>
                <th>STATUS</th>
                <th>CREATED</th>
                <th>ACTION</th>
              </tr>
            </thead>
            <tbody>
              {items.map(item => (
                <tr key={item._id}>
                  <td className="listing-title">{item.title}</td>
                  <td>{[item.city, item.area].filter(Boolean).join(', ') || '—'}</td>
                  <td>{item.contactPhone || '—'}</td>
                  <td>
                    <select
                      value={item.status || 'active'}
                      onChange={e => handleStatusChange(item, e.target.value)}
                      style={{
                        background: sc(item.status).bg, color: sc(item.status).color,
                        border: 'none', borderRadius: 12, padding: '3px 10px',
                        fontSize: 12, fontWeight: 600, cursor: 'pointer',
                      }}
                    >
                      <option value="active">Active</option>
                      <option value="disabled">Disabled</option>
                      <option value="pending">Pending</option>
                    </select>
                  </td>
                  <td>{item.createdAt ? new Date(item.createdAt).toLocaleDateString('en-GB') : '—'}</td>
                  <td>
                    <div className="action-buttons">
                      <button className="action-btn" title="View" style={{ color: '#6b9976' }} onClick={() => setViewItem(item)}><Eye size={16} /></button>
                      <button className="action-btn" title="Edit" style={{ color: '#3b82f6' }} onClick={() => setEditItem(item)}><Edit size={16} /></button>
                      <button className="action-btn delete-btn" title="Delete" onClick={() => handleDelete(item)}><Trash2 size={16} /></button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {showAdd && (
        <ListingModal
          title={`New ${category?.name || ''} Listing`}
          categoryId={id}
          onClose={() => setShowAdd(false)}
          onSuccess={fetchListings}
        />
      )}
      {editItem && (
        <ListingModal
          title="Edit Listing"
          initial={editItem}
          categoryId={id}
          onClose={() => setEditItem(null)}
          onSuccess={fetchListings}
        />
      )}
      {viewItem && <ViewModal item={viewItem} onClose={() => setViewItem(null)} />}
    </div>
  );
};

export default CustomCategoryListings;
