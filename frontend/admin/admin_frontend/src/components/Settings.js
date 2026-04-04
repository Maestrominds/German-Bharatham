import React, { useState, useEffect } from 'react';
import { ChevronUp, ChevronDown, Save, Lock, Edit2, X, Eye, EyeOff } from 'lucide-react';
import API_URL from '../config';

const CONTENT_KEYS = [
  { key: 'aboutUs',          label: 'About Us',             type: 'textarea' },
  { key: 'contactInfo',      label: 'Contact Information',  type: 'textarea' },
  { key: 'privacyPolicy',    label: 'Privacy Policy',       type: 'textarea' },
  { key: 'termsConditions',  label: 'Terms & Conditions',   type: 'textarea' },
];

const DEFAULT_VALUES = {
  aboutUs:         'German Bharatham is a platform connecting the German-Indian community with local services, accommodations, food, and job opportunities.',
  contactInfo:     'Email: contact@germanbharatham.com\nPhone: +49 123 456 7890\nAddress: Berlin, Germany',
  privacyPolicy:   'We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we look after your personal data.',
  termsConditions: 'By accessing this platform, you agree to be bound by these terms and conditions. Please read them carefully before using our services.',
};

const fmt = (dateStr) => {
  if (!dateStr) return '2024-09-11';
  const d = new Date(dateStr);
  return isNaN(d) ? '2024-09-11' : d.toISOString().slice(0, 10);
};

// ── Edit Modal ─────────────────────────────────────────────────────────────────
const EditModal = ({ item, onClose, onSave }) => {
  const [value, setValue] = useState(item.value);
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    await onSave(item.key, value);
    setSaving(false);
    onClose();
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content" style={{ maxWidth: 600, width: '95%' }}>
        <div className="modal-header">
          <h2 style={{ color: '#2d5a3d' }}>Edit {item.label}</h2>
          <button className="close-btn" onClick={onClose}><X size={20} /></button>
        </div>
        <div style={{ padding: '16px 0' }}>
          <textarea
            value={value}
            onChange={e => setValue(e.target.value)}
            rows={8}
            style={{
              width: '100%', padding: 12, borderRadius: 8,
              border: '1px solid #d1d5db', fontSize: 14, lineHeight: 1.6,
              resize: 'vertical', fontFamily: 'inherit', boxSizing: 'border-box'
            }}
          />
        </div>
        <div className="form-actions">
          <button className="cancel-btn" onClick={onClose} disabled={saving}>Cancel</button>
          <button className="create-btn" onClick={handleSave} disabled={saving}>
            {saving ? 'Saving…' : 'Save Changes'}
          </button>
        </div>
      </div>
    </div>
  );
};

// ── Main component ─────────────────────────────────────────────────────────────
const Settings = () => {
  const [contentOpen, setContentOpen] = useState(true);
  const [passwordOpen, setPasswordOpen] = useState(true);

  const [contentData, setContentData] = useState(
    Object.fromEntries(CONTENT_KEYS.map(k => [k.key, { value: DEFAULT_VALUES[k.key], updatedAt: null }]))
  );
  const [editingItem, setEditingItem] = useState(null); // { key, label, value }

  const [passwordData, setPasswordData] = useState({ currentPassword: '', newPassword: '', confirmPassword: '' });
  const [pwLoading, setPwLoading] = useState(false);
  const [saveLoading, setSaveLoading] = useState(false);
  const [showPw, setShowPw] = useState({ current: false, newPw: false, confirm: false });

  const token = () => localStorage.getItem('adminToken');

  // Load content from backend on mount
  useEffect(() => {
    const load = async () => {
      try {
        const res = await fetch(`${API_URL}/api/admin/settings/content`, {
          headers: { Authorization: `Bearer ${token()}` },
        });
        if (res.ok) {
          const data = await res.json();
          setContentData(prev => {
            const updated = { ...prev };
            CONTENT_KEYS.forEach(({ key }) => {
              if (data[key]) updated[key] = data[key];
            });
            return updated;
          });
        }
      } catch (e) { /* use defaults */ }
    };
    load();
  }, []);

  // Save a single field (from edit modal)
  const handleSaveOne = async (key, value) => {
    try {
      const res = await fetch(`${API_URL}/api/admin/settings/content/${key}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token()}` },
        body: JSON.stringify({ value }),
      });
      if (res.ok) {
        const doc = await res.json();
        setContentData(prev => ({ ...prev, [key]: { value: doc.value, updatedAt: doc.updatedAt } }));
      } else {
        const err = await res.json();
        alert('Error: ' + err.message);
      }
    } catch (e) {
      alert('Error: ' + e.message);
    }
  };

  // Save all at once
  const handleSaveAll = async () => {
    setSaveLoading(true);
    try {
      const payload = {};
      CONTENT_KEYS.forEach(({ key }) => { payload[key] = contentData[key]?.value || ''; });
      const res = await fetch(`${API_URL}/api/admin/settings/content`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token()}` },
        body: JSON.stringify(payload),
      });
      if (res.ok) {
        // Refresh dates
        const now = new Date().toISOString();
        setContentData(prev => {
          const updated = { ...prev };
          CONTENT_KEYS.forEach(({ key }) => { updated[key] = { ...updated[key], updatedAt: now }; });
          return updated;
        });
        alert('Settings saved successfully!');
      } else {
        const err = await res.json();
        alert('Error: ' + err.message);
      }
    } catch (e) {
      alert('Error: ' + e.message);
    } finally {
      setSaveLoading(false);
    }
  };

  // Change password
  const handleUpdatePassword = async () => {
    const { currentPassword, newPassword, confirmPassword } = passwordData;
    if (!currentPassword || !newPassword || !confirmPassword) {
      alert('All fields are required'); return;
    }
    if (newPassword !== confirmPassword) {
      alert('New passwords do not match'); return;
    }
    setPwLoading(true);
    try {
      const res = await fetch(`${API_URL}/api/admin/settings/change-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token()}` },
        body: JSON.stringify({ currentPassword, newPassword, confirmPassword }),
      });
      const data = await res.json();
      if (res.ok) {
        alert(data.message);
        setPasswordData({ currentPassword: '', newPassword: '', confirmPassword: '' });
      } else {
        alert('Error: ' + data.message);
      }
    } catch (e) {
      alert('Error: ' + e.message);
    } finally {
      setPwLoading(false);
    }
  };

  const openEdit = (key) => {
    const meta = CONTENT_KEYS.find(k => k.key === key);
    setEditingItem({ key, label: meta.label, value: contentData[key]?.value || '' });
  };

  return (
    <div className="settings">
      <div className="settings-header">
        <h1>Settings</h1>
        <p>Manage app content and policies</p>
      </div>

      <div className="settings-content">
        {/* Content Management Section */}
        <div className="settings-accordion">
          <div className="accordion-header" onClick={() => setContentOpen(!contentOpen)}>
            <h2>Content Management</h2>
            {contentOpen ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
          </div>

          {contentOpen && (
            <div className="accordion-content">
              {CONTENT_KEYS.map(({ key, label }) => (
                <div className="content-item" key={key}>
                  <div className="content-item-header">
                    <span className="content-label">{label}</span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                      <span className="last-updated">Last Updated on {fmt(contentData[key]?.updatedAt)}</span>
                      <button
                        onClick={() => openEdit(key)}
                        style={{
                          display: 'flex', alignItems: 'center', gap: 5,
                          padding: '5px 12px', borderRadius: 6, border: '1px solid #6b9976',
                          background: '#fff', color: '#2d5a3d', cursor: 'pointer',
                          fontSize: 13, fontWeight: 600,
                        }}
                      >
                        <Edit2 size={13} /> Edit
                      </button>
                    </div>
                  </div>
                  <div
                    style={{
                      padding: '12px 14px', borderRadius: 8, border: '1px solid #e5e7eb',
                      background: '#f9fafb', fontSize: 14, color: '#374151',
                      lineHeight: 1.6, whiteSpace: 'pre-wrap', minHeight: 56,
                    }}
                  >
                    {contentData[key]?.value || DEFAULT_VALUES[key]}
                  </div>
                </div>
              ))}

              <button className="save-all-btn" onClick={handleSaveAll} disabled={saveLoading}>
                <Save size={18} />
                {saveLoading ? 'Saving…' : 'Save All Settings'}
              </button>
            </div>
          )}
        </div>

        {/* Change Password Section */}
        <div className="settings-accordion">
          <div className="accordion-header" onClick={() => setPasswordOpen(!passwordOpen)}>
            <h2>Change Password</h2>
            {passwordOpen ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
          </div>

          {passwordOpen && (
            <div className="accordion-content">
              <div className="password-form">
                <div className="form-group">
                  <label>Current Password</label>
                  <div style={{ position: 'relative' }}>
                    <input
                      type={showPw.current ? 'text' : 'password'}
                      placeholder="Enter your current password"
                      value={passwordData.currentPassword}
                      onChange={e => setPasswordData(p => ({ ...p, currentPassword: e.target.value }))}
                      style={{ paddingRight: 40 }}
                    />
                    <button type="button" onClick={() => setShowPw(p => ({ ...p, current: !p.current }))}
                      style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: '#6b7280', padding: 0, display: 'flex' }}>
                      {showPw.current ? <EyeOff size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                </div>
                <div className="form-group">
                  <label>New Password</label>
                  <div style={{ position: 'relative' }}>
                    <input
                      type={showPw.newPw ? 'text' : 'password'}
                      placeholder="Enter new Password"
                      value={passwordData.newPassword}
                      onChange={e => setPasswordData(p => ({ ...p, newPassword: e.target.value }))}
                      style={{ paddingRight: 40 }}
                    />
                    <button type="button" onClick={() => setShowPw(p => ({ ...p, newPw: !p.newPw }))}
                      style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: '#6b7280', padding: 0, display: 'flex' }}>
                      {showPw.newPw ? <EyeOff size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                </div>
                <div className="form-group">
                  <label>Confirm New Password</label>
                  <div style={{ position: 'relative' }}>
                    <input
                      type={showPw.confirm ? 'text' : 'password'}
                      placeholder="Confirm new Password"
                      value={passwordData.confirmPassword}
                      onChange={e => setPasswordData(p => ({ ...p, confirmPassword: e.target.value }))}
                      style={{ paddingRight: 40 }}
                    />
                    <button type="button" onClick={() => setShowPw(p => ({ ...p, confirm: !p.confirm }))}
                      style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: '#6b7280', padding: 0, display: 'flex' }}>
                      {showPw.confirm ? <EyeOff size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                </div>
                <div className="password-actions">
                  <button
                    className="cancel-btn"
                    onClick={() => setPasswordData({ currentPassword: '', newPassword: '', confirmPassword: '' })}
                    disabled={pwLoading}
                  >
                    Cancel
                  </button>
                  <button className="update-password-btn" onClick={handleUpdatePassword} disabled={pwLoading}>
                    <Lock size={16} />
                    {pwLoading ? 'Updating…' : 'Update Password'}
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Edit Modal */}
      {editingItem && (
        <EditModal
          item={editingItem}
          onClose={() => setEditingItem(null)}
          onSave={handleSaveOne}
        />
      )}
    </div>
  );
};

export default Settings;
