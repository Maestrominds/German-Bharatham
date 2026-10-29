import React, { useState, useEffect } from 'react';
import { ChevronUp, ChevronDown, Save, Lock, Edit2, X, Eye, EyeOff, Plus, RotateCcw } from 'lucide-react';
import API_URL from '../config';

const CONTENT_KEYS = [
  { key: 'aboutUs',          label: 'About Us',             type: 'textarea' },
  { key: 'contactInfo',      label: 'Contact Information',  type: 'textarea' },
  { key: 'privacyPolicy',    label: 'Privacy Policy',       type: 'textarea' },
  { key: 'termsConditions',  label: 'Terms & Conditions',   type: 'textarea' },
  { key: 'latestAppVersion', label: 'Latest App Version (e.g. 1.0.4)', type: 'text' },
];

const DEFAULT_VALUES = {
  aboutUs:         'German Bharatham is a platform connecting the German-Indian community with local services, accommodations, and job opportunities.',
  contactInfo:     'Email: contact@germanbharatham.com\nPhone: +49 123 456 7890\nAddress: Berlin, Germany',
  privacyPolicy:   'We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we look after your personal data.',
  termsConditions: 'By accessing this platform, you agree to be bound by these terms and conditions. Please read them carefully before using our services.',
  latestAppVersion: '1.0.4',
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
          {item.type === 'text' ? (
            <input
              type="text"
              value={value}
              onChange={e => setValue(e.target.value)}
              style={{
                width: '100%', padding: 12, borderRadius: 8,
                border: '1px solid #d1d5db', fontSize: 14,
                fontFamily: 'inherit', boxSizing: 'border-box'
              }}
            />
          ) : (
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
          )}
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
  const [dropdownsOpen, setDropdownsOpen] = useState(true);
  const [passwordOpen, setPasswordOpen] = useState(false);

  const [contentData, setContentData] = useState(
    Object.fromEntries(CONTENT_KEYS.map(k => [k.key, { value: DEFAULT_VALUES[k.key], updatedAt: null }]))
  );
  const [editingItem, setEditingItem] = useState(null); // { key, label, value }

  // 🌟 Dynamic Profile Dropdown Options directly from database
  const [domains, setDomains] = useState([]);
  const [languages, setLanguages] = useState([]);
  const [cities, setCities] = useState([]);

  const [newDomain, setNewDomain] = useState('');
  const [newLanguage, setNewLanguage] = useState('');
  const [newCity, setNewCity] = useState('');
  const [optionsLoading, setOptionsLoading] = useState(false);

  const [passwordData, setPasswordData] = useState({ currentPassword: '', newPassword: '', confirmPassword: '' });
  const [pwLoading, setPwLoading] = useState(false);
  const [saveLoading, setSaveLoading] = useState(false);
  const [showPw, setShowPw] = useState({ current: false, newPw: false, confirm: false });

  const token = () => localStorage.getItem('adminToken');

  // Load content & dynamic profile options from backend on mount
  useEffect(() => {
    const loadContent = async () => {
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

    const loadProfileOptions = async () => {
      setOptionsLoading(true);
      try {
        const res = await fetch(`${API_URL}/api/profile-options`);
        if (res.ok) {
          const data = await res.json();
          setDomains(data.domains || []);
          setLanguages(data.languages || []);
          setCities(data.cities || []);
        }
      } catch (e) {
        console.error("Failed to load profile options:", e);
      } finally {
        setOptionsLoading(false);
      }
    };

    loadContent();
    loadProfileOptions();
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
        const err = await res.json().catch(() => ({}));
        alert('Error: ' + (err.message || 'Failed to save'));
      }
    } catch (e) {
      alert('Error: ' + e.message);
    }
  };

  // Save all content settings at once
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
        const now = new Date().toISOString();
        setContentData(prev => {
          const updated = { ...prev };
          CONTENT_KEYS.forEach(({ key }) => { updated[key] = { ...updated[key], updatedAt: now }; });
          return updated;
        });
        alert('Settings saved successfully!');
      } else {
        const err = await res.json().catch(() => ({}));
        alert('Error: ' + (err.message || 'Failed to save'));
      }
    } catch (e) {
      alert('Error: ' + e.message);
    } finally {
      setSaveLoading(false);
    }
  };

  // ── Dynamic Profile Option Handlers (Database-Backed) ────────────────────────
  const handleAddOption = async (e, type, name, clearFn) => {
    e.preventDefault();
    const cleanName = (name || '').trim();
    if (!cleanName) return;

    try {
      const res = await fetch(`${API_URL}/api/profile-options`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token()}`
        },
        body: JSON.stringify({ type, name: cleanName })
      });

      const data = await res.json();
      if (!res.ok) {
        alert(data.message || 'Failed to add option');
        return;
      }

      if (type === 'domain') setDomains(prev => [...prev, data]);
      else if (type === 'language') setLanguages(prev => [...prev, data]);
      else if (type === 'city') setCities(prev => [...prev, data]);

      clearFn();
    } catch (err) {
      alert('Error adding option: ' + err.message);
    }
  };

  const handleDeleteOption = async (opt) => {
    if (!window.confirm(`Delete "${opt.name}" from ${opt.type} options?`)) return;

    try {
      const res = await fetch(`${API_URL}/api/profile-options/${opt.id}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${token()}`
        }
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        alert(err.message || 'Failed to delete option');
        return;
      }

      if (opt.type === 'domain') setDomains(prev => prev.filter(d => d.id !== opt.id));
      else if (opt.type === 'language') setLanguages(prev => prev.filter(l => l.id !== opt.id));
      else if (opt.type === 'city') setCities(prev => prev.filter(c => c.id !== opt.id));
    } catch (err) {
      alert('Error deleting option: ' + err.message);
    }
  };

  const handleResetDefaults = async (type) => {
    if (!window.confirm(`Reset ${type} options to default list in database?`)) return;

    try {
      const res = await fetch(`${API_URL}/api/profile-options/reset-defaults`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token()}`
        },
        body: JSON.stringify({ type })
      });

      const data = await res.json();
      if (res.ok) {
        if (data.domains) setDomains(data.domains);
        if (data.languages) setLanguages(data.languages);
        if (data.cities) setCities(data.cities);
        alert(`Default ${type} options restored in database!`);
      } else {
        alert(data.message || 'Failed to reset defaults');
      }
    } catch (err) {
      alert('Error resetting defaults: ' + err.message);
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
    setEditingItem({ key, label: meta?.label || key, type: meta?.type || 'textarea', value: contentData[key]?.value || '' });
  };

  return (
    <div className="settings-page">
      <div className="settings-header">
        <h1>Settings</h1>
        <p>Manage app content, profile dropdown options, and policies</p>
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

        {/* 🌟 DYNAMIC PROFILE DROPDOWNS SECTION */}
        <div className="settings-accordion" style={{ marginTop: '1.5rem' }}>
          <div className="accordion-header" onClick={() => setDropdownsOpen(!dropdownsOpen)}>
            <div>
              <h2>Profile Dropdowns Management</h2>
              <span style={{ fontSize: '13px', color: '#6b7280', fontWeight: 400 }}>
                Manage live dynamic options stored in database for Domain, Language, and City
              </span>
            </div>
            {dropdownsOpen ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
          </div>

          {dropdownsOpen && (
            <div className="accordion-content">
              {optionsLoading ? (
                <div style={{ padding: '2rem', textAlign: 'center', color: '#6b7280' }}>
                  Loading database options...
                </div>
              ) : (
                <>
                  {/* 1. Domains */}
                  <div style={{ marginBottom: '2rem', paddingBottom: '1.5rem', borderBottom: '1px solid #eee' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
                      <div>
                        <h3 style={{ fontSize: '1rem', fontWeight: 600, color: '#1f2937', margin: 0 }}>
                          Domains / Industries ({domains.length})
                        </h3>
                        <p style={{ fontSize: '13px', color: '#6b7280', margin: '4px 0 0 0' }}>
                          Users can select from these domains or type a custom domain in the app.
                        </p>
                      </div>
                      <button
                        type="button"
                        onClick={() => handleResetDefaults('domain')}
                        style={{
                          display: 'inline-flex', alignItems: 'center', gap: '5px',
                          background: 'none', border: '1px solid #d1d5db', padding: '4px 10px',
                          borderRadius: '6px', fontSize: '12px', color: '#4b5563', cursor: 'pointer'
                        }}
                        title="Reset domain defaults in DB"
                      >
                        <RotateCcw size={12} /> Reset Defaults
                      </button>
                    </div>

                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', marginBottom: '12px', minHeight: '36px' }}>
                      {domains.map((item) => (
                        <span
                          key={item.id}
                          style={{
                            display: 'inline-flex', alignItems: 'center', gap: '6px',
                            padding: '6px 12px', borderRadius: '20px',
                            backgroundColor: '#e8f5e8', color: '#2d5a3d', fontSize: '13px',
                            fontWeight: 500, border: '1px solid #c2e0c6'
                          }}
                        >
                          {item.name}
                          <button
                            type="button"
                            onClick={() => handleDeleteOption(item)}
                            style={{
                              background: 'none', border: 'none', color: '#dc3545',
                              cursor: 'pointer', padding: 0, display: 'inline-flex', alignItems: 'center'
                            }}
                            title={`Delete ${item.name}`}
                          >
                            <X size={14} />
                          </button>
                        </span>
                      ))}
                    </div>

                    <form onSubmit={(e) => handleAddOption(e, 'domain', newDomain, () => setNewDomain(''))} style={{ display: 'flex', gap: '8px', maxWidth: '500px' }}>
                      <input
                        type="text"
                        placeholder="Add new domain (e.g. Medical Domain, Aerospace)..."
                        value={newDomain}
                        onChange={e => setNewDomain(e.target.value)}
                        style={{
                          flex: 1, padding: '8px 12px', borderRadius: '8px',
                          border: '1px solid #d1d5db', fontSize: '14px'
                        }}
                      />
                      <button
                        type="submit"
                        style={{
                          display: 'inline-flex', alignItems: 'center', gap: '4px',
                          padding: '8px 16px', backgroundColor: '#2d5a3d', color: 'white',
                          border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 500, fontSize: '13px'
                        }}
                      >
                        <Plus size={16} /> Add Domain
                      </button>
                    </form>
                  </div>

                  {/* 2. Languages */}
                  <div style={{ marginBottom: '2rem', paddingBottom: '1.5rem', borderBottom: '1px solid #eee' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
                      <div>
                        <h3 style={{ fontSize: '1rem', fontWeight: 600, color: '#1f2937', margin: 0 }}>
                          Languages / Mother Tongues ({languages.length})
                        </h3>
                        <p style={{ fontSize: '13px', color: '#6b7280', margin: '4px 0 0 0' }}>
                          Available languages for user profile setup and community filtering.
                        </p>
                      </div>
                      <button
                        type="button"
                        onClick={() => handleResetDefaults('language')}
                        style={{
                          display: 'inline-flex', alignItems: 'center', gap: '5px',
                          background: 'none', border: '1px solid #d1d5db', padding: '4px 10px',
                          borderRadius: '6px', fontSize: '12px', color: '#4b5563', cursor: 'pointer'
                        }}
                        title="Reset language defaults in DB"
                      >
                        <RotateCcw size={12} /> Reset Defaults
                      </button>
                    </div>

                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', marginBottom: '12px', minHeight: '36px' }}>
                      {languages.map((item) => (
                        <span
                          key={item.id}
                          style={{
                            display: 'inline-flex', alignItems: 'center', gap: '6px',
                            padding: '6px 12px', borderRadius: '20px',
                            backgroundColor: '#e0f2fe', color: '#0369a1', fontSize: '13px',
                            fontWeight: 500, border: '1px solid #bae6fd'
                          }}
                        >
                          {item.name}
                          <button
                            type="button"
                            onClick={() => handleDeleteOption(item)}
                            style={{
                              background: 'none', border: 'none', color: '#dc3545',
                              cursor: 'pointer', padding: 0, display: 'inline-flex', alignItems: 'center'
                            }}
                            title={`Delete ${item.name}`}
                          >
                            <X size={14} />
                          </button>
                        </span>
                      ))}
                    </div>

                    <form onSubmit={(e) => handleAddOption(e, 'language', newLanguage, () => setNewLanguage(''))} style={{ display: 'flex', gap: '8px', maxWidth: '500px' }}>
                      <input
                        type="text"
                        placeholder="Add new language (e.g. French, Spanish)..."
                        value={newLanguage}
                        onChange={e => setNewLanguage(e.target.value)}
                        style={{
                          flex: 1, padding: '8px 12px', borderRadius: '8px',
                          border: '1px solid #d1d5db', fontSize: '14px'
                        }}
                      />
                      <button
                        type="submit"
                        style={{
                          display: 'inline-flex', alignItems: 'center', gap: '4px',
                          padding: '8px 16px', backgroundColor: '#0369a1', color: 'white',
                          border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 500, fontSize: '13px'
                        }}
                      >
                        <Plus size={16} /> Add Language
                      </button>
                    </form>
                  </div>

                  {/* 3. Cities */}
                  <div style={{ marginBottom: '1.5rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
                      <div>
                        <h3 style={{ fontSize: '1rem', fontWeight: 600, color: '#1f2937', margin: 0 }}>
                          Cities in Germany ({cities.length})
                        </h3>
                        <p style={{ fontSize: '13px', color: '#6b7280', margin: '4px 0 0 0' }}>
                          Predefined German cities for preferred living/working city dropdown.
                        </p>
                      </div>
                      <button
                        type="button"
                        onClick={() => handleResetDefaults('city')}
                        style={{
                          display: 'inline-flex', alignItems: 'center', gap: '5px',
                          background: 'none', border: '1px solid #d1d5db', padding: '4px 10px',
                          borderRadius: '6px', fontSize: '12px', color: '#4b5563', cursor: 'pointer'
                        }}
                        title="Reset city defaults in DB"
                      >
                        <RotateCcw size={12} /> Reset Defaults
                      </button>
                    </div>

                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', marginBottom: '12px', minHeight: '36px' }}>
                      {cities.map((item) => (
                        <span
                          key={item.id}
                          style={{
                            display: 'inline-flex', alignItems: 'center', gap: '6px',
                            padding: '6px 12px', borderRadius: '20px',
                            backgroundColor: '#fef3c7', color: '#92400e', fontSize: '13px',
                            fontWeight: 500, border: '1px solid #fde68a'
                          }}
                        >
                          {item.name}
                          <button
                            type="button"
                            onClick={() => handleDeleteOption(item)}
                            style={{
                              background: 'none', border: 'none', color: '#dc3545',
                              cursor: 'pointer', padding: 0, display: 'inline-flex', alignItems: 'center'
                            }}
                            title={`Delete ${item.name}`}
                          >
                            <X size={14} />
                          </button>
                        </span>
                      ))}
                    </div>

                    <form onSubmit={(e) => handleAddOption(e, 'city', newCity, () => setNewCity(''))} style={{ display: 'flex', gap: '8px', maxWidth: '500px' }}>
                      <input
                        type="text"
                        placeholder="Add new city (e.g. Heidelberg, Dortmund)..."
                        value={newCity}
                        onChange={e => setNewCity(e.target.value)}
                        style={{
                          flex: 1, padding: '8px 12px', borderRadius: '8px',
                          border: '1px solid #d1d5db', fontSize: '14px'
                        }}
                      />
                      <button
                        type="submit"
                        style={{
                          display: 'inline-flex', alignItems: 'center', gap: '4px',
                          padding: '8px 16px', backgroundColor: '#92400e', color: 'white',
                          border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 500, fontSize: '13px'
                        }}
                      >
                        <Plus size={16} /> Add City
                      </button>
                    </form>
                  </div>
                </>
              )}
            </div>
          )}
        </div>

        {/* Change Password Section */}
        <div className="settings-accordion" style={{ marginTop: '1.5rem' }}>
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
