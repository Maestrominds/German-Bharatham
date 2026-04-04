import React, { useState } from 'react';
import { X } from 'lucide-react';
import API_URL from '../config';

const BASE = API_URL;
const DEFAULT_AMENITIES = ['WiFi', 'Parking', 'Balcony', 'Garden', 'Elevator'];

const EditAccommodationModal = ({ accommodation: acc, onClose, onSuccess }) => {
  // Resolve existing amenities from object or array
  const resolveAmenities = () => {
    if (!acc) return [];
    if (Array.isArray(acc.amenities)) return acc.amenities;
    if (acc.amenities && typeof acc.amenities === 'object') {
      return Object.entries(acc.amenities)
        .filter(([, v]) => v)
        .map(([k]) => k.replace(/([A-Z])/g, ' $1').replace(/^./, s => s.toUpperCase()));
    }
    return [];
  };

  const [form, setForm] = useState({
    title:        acc?.title || '',
    propertyType: acc?.propertyType || 'Apartment',
    location:     [acc?.city, acc?.area].filter(Boolean).join(', '),
    contact:      acc?.contactPhone || '',
    description:  acc?.description || '',
    price:        String(acc?.rentDetails?.warmRent || acc?.rentDetails?.coldRent || ''),
    status:       (s => s === 'disabled' ? 'inactive' : s || 'active')(acc?.status),
  });

  const [selectedAmenities, setSelectedAmenities] = useState(resolveAmenities);
  const [customAmenity, setCustomAmenity]         = useState('');
  const [images, setImages]                       = useState(acc?.media?.images || []);
  const [submitting, setSubmitting]               = useState(false);

  if (!acc) return null;

  const handleChange = e => setForm(p => ({ ...p, [e.target.name]: e.target.value }));

  const toggleAmenity = a =>
    setSelectedAmenities(prev =>
      prev.includes(a) ? prev.filter(x => x !== a) : [...prev, a]
    );

  const addCustom = () => {
    const t = customAmenity.trim();
    if (t && !selectedAmenities.includes(t)) {
      setSelectedAmenities(p => [...p, t]);
      setCustomAmenity('');
    }
  };

  const handleFileAdd = e => {
    const valid = Array.from(e.target.files).filter(f =>
      ['image/png', 'image/jpeg', 'image/jpg'].includes(f.type)
    );
    if (valid.length !== e.target.files.length) alert('Only JPG, JPEG, PNG files are allowed.');
    valid.forEach(f => {
      const r = new FileReader();
      r.onloadend = () => setImages(p => [...p, r.result]);
      r.readAsDataURL(f);
    });
    e.target.value = '';
  };

  const removeImage = idx => setImages(p => p.filter((_, i) => i !== idx));

  const validate = () => {
    if (!form.title.trim())       return 'Title is required';
    if (!form.location.trim())    return 'Location is required';
    if (!form.contact.trim())     return 'Contact is required';
    if (!form.description.trim()) return 'Description is required';
    if (!form.price.trim())       return 'Price is required';
    return null;
  };

  const handleSubmit = async () => {
    const err = validate();
    if (err) { alert(err); return; }

    setSubmitting(true);
    try {
      const token = localStorage.getItem('adminToken');
      const cityParts = form.location.split(',').map(s => s.trim());

      const payload = {
        title:        form.title.trim(),
        propertyType: form.propertyType,
        city:         cityParts[0] || form.location.trim(),
        contactPhone: form.contact.trim(),
        description:  form.description.trim(),
        status:       form.status === 'inactive' ? 'disabled' : form.status,
        rentDetails:  { warmRent: parseFloat(form.price) || 0 },
        amenities:    selectedAmenities.reduce((acc, a) => {
          acc[a.toLowerCase().replace(/\s+/g, '_')] = true;
          return acc;
        }, {}),
        media: { images },
        adminControls: { isActive: form.status.toLowerCase() === 'active' },
      };

      const res = await fetch(`${BASE}/api/accommodation/admin/${acc._id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        onSuccess && onSuccess();
        onClose();
      } else {
        const d = await res.json().catch(() => ({}));
        alert('Error: ' + (d.message || 'Failed to update'));
      }
    } catch (ex) {
      alert('Error connecting to server: ' + ex.message);
    } finally {
      setSubmitting(false);
    }
  };

  const allAmenityOptions = [
    ...DEFAULT_AMENITIES,
    ...selectedAmenities.filter(a => !DEFAULT_AMENITIES.includes(a)),
  ];

  return (
    <div className="modal-overlay">
      <div className="modal-content modal-large" style={{ maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <h2>Edit Accommodation</h2>
          <button className="close-btn" onClick={onClose}><X size={22} /></button>
        </div>

        <div className="add-listing-form">
          {/* Title + Property Type */}
          <div className="form-row">
            <div className="form-group">
              <label>Title <span style={{ color: 'red' }}>*</span></label>
              <input name="title" value={form.title} onChange={handleChange} placeholder="Room" />
            </div>
            <div className="form-group">
              <label>Property Type <span style={{ color: 'red' }}>*</span></label>
              <select name="propertyType" value={form.propertyType} onChange={handleChange}>
                <option value="Apartment">Apartment</option>
                <option value="Shared Room">Shared Room</option>
                <option value="Temporary Stays">Temporary Stays</option>
              </select>
            </div>
          </div>

          {/* Location + Contact */}
          <div className="form-row">
            <div className="form-group">
              <label>Location <span style={{ color: 'red' }}>*</span></label>
              <input name="location" value={form.location} onChange={handleChange} placeholder="Munich" />
            </div>
            <div className="form-group">
              <label>Contact <span style={{ color: 'red' }}>*</span></label>
              <input name="contact" value={form.contact} onChange={handleChange} placeholder="+49 52148 765397" />
            </div>
          </div>

          {/* Description */}
          <div className="form-group">
            <label>Description <span style={{ color: 'red' }}>*</span></label>
            <textarea name="description" rows={3} value={form.description} onChange={handleChange} placeholder="Enter Description" />
          </div>

          {/* Price + Status */}
          <div className="form-row">
            <div className="form-group">
              <label>Price <span style={{ color: 'red' }}>*</span></label>
              <input name="price" value={form.price} onChange={handleChange} placeholder="€1,000/month" />
            </div>
            <div className="form-group">
              <label>Status</label>
              <select name="status" value={form.status} onChange={handleChange}>
                <option value="active">Active</option>
                <option value="pending">Pending</option>
                <option value="inactive">Inactive</option>
              </select>
            </div>
          </div>

          {/* Amenities */}
          <div className="form-group">
            <label>Amenities</label>
            <p style={{ fontSize: 12, color: '#6b7280', margin: '0 0 8px' }}>Enter any Amenities or Choose Below</p>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 10 }}>
              {allAmenityOptions.map(a => (
                <button key={a} type="button" onClick={() => toggleAmenity(a)}
                  style={{ padding: '5px 14px', borderRadius: 20, fontSize: 13, cursor: 'pointer',
                    border: '1px solid #6b9976',
                    background: selectedAmenities.includes(a) ? '#6b9976' : '#fff',
                    color: selectedAmenities.includes(a) ? '#fff' : '#374151',
                    fontWeight: 500 }}>
                  {a}
                </button>
              ))}
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <input value={customAmenity} onChange={e => setCustomAmenity(e.target.value)}
                placeholder="Type custom amenity…" style={{ flex: 1 }}
                onKeyDown={e => { if (e.key === 'Enter') { e.preventDefault(); addCustom(); } }} />
              <button type="button" onClick={addCustom}
                style={{ padding: '7px 14px', background: '#6b9976', color: '#fff',
                  border: 'none', borderRadius: 6, cursor: 'pointer', fontWeight: 600 }}>
                Add
              </button>
            </div>
          </div>

          {/* Photos */}
          <div className="form-group">
            <label>
              Photos{' '}
              <span style={{ color: '#6b7280', fontSize: 12 }}>(JPG, JPEG, PNG — optional)</span>
            </label>
            <input type="file" accept=".jpg,.jpeg,.png,image/jpeg,image/png" multiple onChange={handleFileAdd} />
            {images.length > 0 && (
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 8 }}>
                {images.map((src, i) => (
                  <div key={i} style={{ position: 'relative' }}>
                    <img src={src} alt={`img-${i}`}
                      style={{ width: 80, height: 65, objectFit: 'cover', borderRadius: 6, border: '2px solid #6b9976' }} />
                    <button type="button" onClick={() => removeImage(i)}
                      style={{ position: 'absolute', top: -6, right: -6, background: '#ef4444', color: '#fff',
                        border: 'none', borderRadius: '50%', width: 18, height: 18, fontSize: 11,
                        cursor: 'pointer', padding: 0, lineHeight: '18px', textAlign: 'center' }}>✕</button>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="form-actions">
            <button type="button" className="cancel-btn" onClick={onClose} disabled={submitting}>Cancel</button>
            <button type="button" className="create-btn" onClick={handleSubmit} disabled={submitting}>
              {submitting ? 'Saving…' : 'Save Changes'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EditAccommodationModal;
