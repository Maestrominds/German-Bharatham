import React, { useState } from 'react';
import { X } from 'lucide-react';

// ─── simple field row ────────────────────────────────────────────────────────
const Row = ({ label, value }) => (
  <div style={{ display: 'flex', gap: 8, marginBottom: 10, fontSize: 14 }}>
    <span style={{ color: '#6b7280', minWidth: 150, flexShrink: 0 }}>{label}:</span>
    <span style={{ color: '#111827', fontWeight: 500 }}>{value || '—'}</span>
  </div>
);

const StatusBadge = ({ status }) => {
  const map = {
    active:   { bg: '#d1fae5', color: '#065f46' },
    pending:  { bg: '#fef3c7', color: '#92400e' },
    disabled: { bg: '#f3f4f6', color: '#6b7280' },
    inactive: { bg: '#fee2e2', color: '#991b1b' },
  };
  const st = (status || 'active').toLowerCase();
  const s = map[st] || map.disabled;
  return (
    <span style={{ background: s.bg, color: s.color, borderRadius: 20,
      padding: '3px 14px', fontSize: 13, fontWeight: 700 }}>
      {status || '—'}
    </span>
  );
};

// kept for any future internal use
const Section = ({ title, children }) => (
  <div style={{ marginBottom: 20 }}>
    <h4 style={{ color: '#6b9976', borderBottom: '1px solid #e5e7eb', paddingBottom: 6, marginBottom: 12 }}>{title}</h4>
    {children}
  </div>
);

const Badge = ({ active, label }) => (
  <span style={{
    display: 'inline-block', padding: '2px 10px', borderRadius: 12, fontSize: 12, fontWeight: 600,
    background: active ? '#d1fae5' : '#f3f4f6', color: active ? '#065f46' : '#6b7280',
    marginRight: 6, marginBottom: 4
  }}>{label}</span>
);

const ViewAccommodationModal = ({ accommodation: acc, onClose }) => {
  const [imgIndex, setImgIndex] = useState(0);
  if (!acc) return null;

  const images = acc.media?.images || [];
  const price = acc.rentDetails?.warmRent
    ? `€${acc.rentDetails.warmRent}/month`
    : acc.rentDetails?.coldRent
    ? `€${acc.rentDetails.coldRent}/month`
    : null;

  // amenities stored as object {wifi:true} or array ['WiFi']
  let amenityList = [];
  if (Array.isArray(acc.amenities)) {
    amenityList = acc.amenities;
  } else if (acc.amenities && typeof acc.amenities === 'object') {
    amenityList = Object.entries(acc.amenities)
      .filter(([, v]) => v)
      .map(([k]) => k.replace(/([A-Z])/g, ' $1').replace(/^./, s => s.toUpperCase()));
  }

  return (
    <div className="modal-overlay">
      <div className="modal-content modal-large" style={{ maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <h2 style={{ fontSize: 18 }}>{acc.title || 'Accommodation Details'}</h2>
          <button className="close-btn" onClick={onClose}><X size={24} /></button>
        </div>

        {/* Image gallery */}
        {images.length > 0 && (
          <div style={{ marginBottom: 20 }}>
            <img src={images[imgIndex]} alt="property"
              style={{ width: '100%', maxHeight: 260, objectFit: 'cover', borderRadius: 8 }} />
            {images.length > 1 && (
              <div style={{ display: 'flex', gap: 6, marginTop: 8, flexWrap: 'wrap' }}>
                {images.map((img, i) => (
                  <img key={i} src={img} alt={`thumb-${i}`} onClick={() => setImgIndex(i)}
                    style={{ width: 60, height: 48, objectFit: 'cover', borderRadius: 4, cursor: 'pointer',
                      border: i === imgIndex ? '2px solid #6b9976' : '2px solid #e5e7eb' }} />
                ))}
              </div>
            )}
          </div>
        )}

        <div style={{ padding: '0 4px' }}>
          <Row label="Title"         value={acc.title} />
          <Row label="Property Type" value={acc.propertyType} />
          <Row label="Location"      value={[acc.city, acc.area].filter(Boolean).join(', ')} />
          <Row label="Contact"       value={acc.contactPhone} />
          <Row label="Description"   value={acc.description} />
          <Row label="Price"         value={price} />

          <div style={{ display: 'flex', gap: 8, marginBottom: 10, fontSize: 14, alignItems: 'center' }}>
            <span style={{ color: '#6b7280', minWidth: 150, flexShrink: 0 }}>Status:</span>
            <StatusBadge status={acc.status || (acc.adminControls?.isActive ? 'active' : 'disabled')} />
          </div>

          {amenityList.length > 0 && (
            <div style={{ marginTop: 8 }}>
              <span style={{ color: '#6b7280', fontSize: 14 }}>Amenities:</span>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 6 }}>
                {amenityList.map(a => (
                  <span key={a} style={{ background: '#d1fae5', color: '#065f46', borderRadius: 20,
                    padding: '3px 12px', fontSize: 12, fontWeight: 600 }}>{a}</span>
                ))}
              </div>
            </div>
          )}

          {/* ── Map Preview ───────────────────────────────────────────────── */}
          {acc.latitude && acc.longitude && (
            <div style={{ marginTop: 16 }}>
              <span style={{ color: '#6b7280', fontSize: 14, display: 'block', marginBottom: 6 }}>
                Location Map
              </span>
              <div
                onClick={() => {
                  const url = `https://www.google.com/maps/dir/?api=1&destination=${acc.latitude},${acc.longitude}`;
                  window.open(url, '_blank', 'noopener,noreferrer');
                }}
                title="Tap to open Google Maps navigation"
                style={{ position: 'relative', cursor: 'pointer', borderRadius: 10, overflow: 'hidden',
                  border: '2px solid #6b9976', boxShadow: '0 2px 8px rgba(0,0,0,0.12)' }}
              >
                <iframe
                  title="accommodation-map"
                  src={`https://www.openstreetmap.org/export/embed.html?bbox=${acc.longitude - 0.015},${acc.latitude - 0.015},${acc.longitude + 0.015},${acc.latitude + 0.015}&layer=mapnik&marker=${acc.latitude},${acc.longitude}`}
                  style={{ width: '100%', height: 200, border: 0, display: 'block', pointerEvents: 'none' }}
                />
                {/* Transparent overlay so the whole tile is clickable */}
                <div style={{ position: 'absolute', inset: 0 }} />
                <div style={{ position: 'absolute', bottom: 8, right: 8, background: 'rgba(255,255,255,0.92)',
                  borderRadius: 6, padding: '4px 10px', fontSize: 12, fontWeight: 600, color: '#1a56db',
                  boxShadow: '0 1px 4px rgba(0,0,0,0.15)' }}>
                  Tap to navigate ↗
                </div>
              </div>
            </div>
          )}
        </div>

        <div className="form-actions" style={{ marginTop: 20 }}>
          <button className="cancel-btn" onClick={onClose}>Close</button>
        </div>
      </div>
    </div>
  );
};

export default ViewAccommodationModal;
