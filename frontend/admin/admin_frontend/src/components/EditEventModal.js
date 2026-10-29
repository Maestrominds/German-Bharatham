import React, { useState, useEffect } from 'react';
import { X } from 'lucide-react';
import API_URL from '../config';

const BASE = API_URL;

const CATEGORIES = [
  { value: 'festivals', label: 'Festivals & Celebrations' },
  { value: 'screenings', label: 'Movies & Screenings' },
  { value: 'standup', label: 'Standup Comedy' },
  { value: 'concerts', label: 'Concerts & Music' },
  { value: 'workshops', label: 'Workshops & Masterclasses' },
  { value: 'networking', label: 'Professional & Networking' },
  { value: 'sports', label: 'Sports & Fitness' },
  { value: 'kids', label: 'Kids & Family' },
  { value: 'food', label: 'Food & Pop-ups' },
  { value: 'spiritual', label: 'Spiritual & Community' },
  { value: 'other', label: 'Other' },
];

const FORMATS = [
  { value: 'one_day', label: 'One-Day Event' },
  { value: 'multi_day', label: 'Multi-Day Festival' },
  { value: 'course', label: 'Course / Multi-Week' },
  { value: 'workshop', label: 'Single Workshop' },
  { value: 'screening', label: 'Movie Screening' },
  { value: 'deadline', label: 'Deadline / Application Close' },
];

const EditEventModal = ({ event, onClose, onSuccess }) => {
  const [form, setForm] = useState({
    title: '',
    format: 'one_day',
    category: 'festivals',
    shortDescription: '',
    city: '',
    venue: '',
    address: '',
    isOnline: false,
    onlineLink: '',
    organizer: '',
    contact: '',
    startsAt: '',
    endsAt: '',
    timeText: '',
    priceType: 'paid',
    price: '',
    priceText: '',
    ticketUrl: '',
    familyFriendly: false,
    description: '',
    status: 'active',
  });

  const [images, setImages] = useState([]);
  const [previews, setPreviews] = useState([]);
  const [existingImages, setExistingImages] = useState([]);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (event) {
      const formatDt = (d) => {
        if (!d) return '';
        try {
          const dt = new Date(d);
          const pad = (n) => String(n).padStart(2, '0');
          return `${dt.getFullYear()}-${pad(dt.getMonth() + 1)}-${pad(dt.getDate())}T${pad(dt.getHours())}:${pad(dt.getMinutes())}`;
        } catch {
          return '';
        }
      };

      setForm({
        title: event.title || '',
        format: event.format || 'one_day',
        category: event.category || 'festivals',
        shortDescription: event.shortDescription || event.short_description || '',
        city: event.city || '',
        venue: event.venue || '',
        address: event.address || '',
        isOnline: !!(event.isOnline || event.is_online),
        onlineLink: event.onlineLink || '',
        organizer: event.organizer || '',
        contact: event.contact || '',
        startsAt: formatDt(event.startsAt || event.start_date),
        endsAt: formatDt(event.endsAt || event.end_date),
        timeText: event.timeText || event.time_text || '',
        priceType: event.priceType || event.price_type || 'paid',
        price: event.price || 'Free',
        priceText: event.priceText || event.price_text || event.price || '',
        ticketUrl: event.ticketUrl || event.externalUrl || event.onlineLink || '',
        familyFriendly: !!(event.familyFriendly || event.family_friendly),
        description: event.description || '',
        status: String(event.status || 'active').toLowerCase(),
      });
      setExistingImages(Array.isArray(event.images) ? event.images : []);
    }
  }, [event]);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm((p) => ({
      ...p,
      [name]: type === 'checkbox' ? checked : value,
    }));
  };

  const handleImageUpload = (e) => {
    const files = Array.from(e.target.files).filter((f) =>
      /^image\//.test(f.type)
    );
    if (files.length !== e.target.files.length) {
      alert('Only image files are allowed.');
    }
    setImages(files);
    setPreviews(files.map((f) => URL.createObjectURL(f)));
    e.target.value = '';
  };

  const removeNewImage = (idx) => {
    setImages((p) => p.filter((_, i) => i !== idx));
    setPreviews((p) => p.filter((_, i) => i !== idx));
  };

  const removeExistingImage = (idx) => {
    setExistingImages((p) => p.filter((_, i) => i !== idx));
  };

  const handleSubmit = async () => {
    if (!form.title.trim()) {
      alert('Event title is required.');
      return;
    }
    setSubmitting(true);
    try {
      const token = localStorage.getItem('adminToken');
      const formData = new FormData();

      images.forEach((file) => formData.append('images', file));

      formData.append('title', form.title.trim());
      formData.append('format', form.format);
      formData.append('category', form.category);
      if (form.shortDescription) formData.append('shortDescription', form.shortDescription.trim());
      formData.append('city', form.isOnline ? 'Online' : form.city.trim());
      if (!form.isOnline && form.venue) formData.append('venue', form.venue.trim());
      if (!form.isOnline && form.address) formData.append('address', form.address.trim());
      formData.append('isOnline', String(form.isOnline));
      if (form.isOnline && form.onlineLink) formData.append('onlineLink', form.onlineLink.trim());

      formData.append('organizer', form.organizer.trim());
      formData.append('contact', form.contact.trim());
      if (form.startsAt) formData.append('startsAt', form.startsAt);
      if (form.endsAt) formData.append('endsAt', form.endsAt);
      if (form.timeText) formData.append('timeText', form.timeText.trim());

      formData.append('priceType', form.priceType);
      const displayPrice = form.priceText?.trim() || form.price?.trim() || (form.priceType === 'free' ? 'Free' : '');
      formData.append('price', displayPrice);
      formData.append('priceText', displayPrice);

      const tUrl = form.ticketUrl.trim();
      formData.append('ticketUrl', tUrl);
      formData.append('externalUrl', tUrl);

      formData.append('familyFriendly', String(form.familyFriendly));
      formData.append('description', form.description.trim());
      formData.append('status', form.status);

      const res = await fetch(`${BASE}/api/events/admin/${event._id || event.id}`, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${token}` },
        body: formData,
      });

      if (res.ok) {
        onSuccess();
        onClose();
      } else {
        const d = await res.json().catch(() => ({}));
        alert(d.message || 'Failed to update event');
      }
    } catch (e) {
      alert('Error: ' + e.message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content" style={{ maxWidth: 660, maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <h2>Edit Event</h2>
          <button className="close-btn" onClick={onClose}>
            <X size={22} />
          </button>
        </div>

        <div className="add-listing-form">
          <div className="form-group">
            <label>
              Event Title <span style={{ color: 'red' }}>*</span>
            </label>
            <input
              name="title"
              value={form.title}
              onChange={handleChange}
              required
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Event Format</label>
              <select name="format" value={form.format} onChange={handleChange}>
                {FORMATS.map((f) => (
                  <option key={f.value} value={f.value}>{f.label}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label>Event Category</label>
              <select name="category" value={form.category} onChange={handleChange}>
                {CATEGORIES.map((c) => (
                  <option key={c.value} value={c.value}>{c.label}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="form-group">
            <label>Short Description (max 160 characters) — {form.shortDescription.length}/160</label>
            <input
              name="shortDescription"
              maxLength={160}
              value={form.shortDescription}
              onChange={handleChange}
              placeholder="Single punchy summary line shown on event cards"
            />
          </div>

          <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: 8, margin: '8px 0' }}>
            <input
              type="checkbox"
              id="admin_edit_isOnline"
              name="isOnline"
              checked={form.isOnline}
              onChange={handleChange}
              style={{ width: 16, height: 16, cursor: 'pointer' }}
            />
            <label htmlFor="admin_edit_isOnline" style={{ fontSize: 13, color: '#374151', cursor: 'pointer', margin: 0 }}>
              This is an Online / Virtual Event (available across Germany)
            </label>
          </div>

          {form.isOnline ? (
            <div className="form-group">
              <label>Online Meeting / Stream URL</label>
              <input
                name="onlineLink"
                value={form.onlineLink}
                onChange={handleChange}
                placeholder="https://zoom.us/j/... or Google Meet"
              />
            </div>
          ) : (
            <>
              <div className="form-row">
                <div className="form-group">
                  <label>City <span style={{ color: 'red' }}>*</span></label>
                  <input
                    name="city"
                    value={form.city}
                    onChange={handleChange}
                    placeholder="e.g. Berlin, Munich, Frankfurt"
                  />
                </div>
                <div className="form-group">
                  <label>Venue Name</label>
                  <input
                    name="venue"
                    value={form.venue}
                    onChange={handleChange}
                    placeholder="e.g. Meistersingerhalle"
                  />
                </div>
              </div>
              <div className="form-group">
                <label>Street Address</label>
                <input
                  name="address"
                  value={form.address}
                  onChange={handleChange}
                  placeholder="e.g. Münchener Str. 101, 90478"
                />
              </div>
            </>
          )}

          <div className="form-row">
            <div className="form-group">
              <label>Starts At</label>
              <input
                type="datetime-local"
                name="startsAt"
                value={form.startsAt}
                onChange={handleChange}
              />
            </div>
            <div className="form-group">
              <label>Ends At</label>
              <input
                type="datetime-local"
                name="endsAt"
                value={form.endsAt}
                onChange={handleChange}
              />
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Display Time Text (Optional)</label>
              <input
                name="timeText"
                value={form.timeText}
                onChange={handleChange}
                placeholder="e.g. 18:00 - 22:00 or Every Sat 10:00"
              />
            </div>
            <div className="form-group">
              <label>Price Type</label>
              <select name="priceType" value={form.priceType} onChange={handleChange}>
                <option value="paid">Paid</option>
                <option value="free">Free</option>
                <option value="donation">Donation / Pay what you want</option>
              </select>
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Price Display</label>
              <input
                name="priceText"
                value={form.priceText}
                onChange={handleChange}
                placeholder="e.g. €15 early bird, Free entry"
              />
            </div>
            <div className="form-group">
              <label>Organizer</label>
              <input
                name="organizer"
                value={form.organizer}
                onChange={handleChange}
              />
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Contact Phone / Email</label>
              <input
                name="contact"
                value={form.contact}
                onChange={handleChange}
              />
            </div>
            <div className="form-group">
              <label>Ticket / RSVP URL</label>
              <input
                name="ticketUrl"
                value={form.ticketUrl}
                onChange={handleChange}
              />
            </div>
          </div>

          <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: 8, margin: '8px 0' }}>
            <input
              type="checkbox"
              id="admin_edit_familyFriendly"
              name="familyFriendly"
              checked={form.familyFriendly}
              onChange={handleChange}
              style={{ width: 16, height: 16, cursor: 'pointer' }}
            />
            <label htmlFor="admin_edit_familyFriendly" style={{ fontSize: 13, color: '#374151', cursor: 'pointer', margin: 0 }}>
              Family-Friendly / Kids Welcome
            </label>
          </div>

          <div className="form-group">
            <label>Full Description</label>
            <textarea
              name="description"
              rows={4}
              value={form.description}
              onChange={handleChange}
            />
          </div>

          <div className="form-group">
            <label>Status</label>
            <select
              name="status"
              value={form.status}
              onChange={handleChange}
            >
              <option value="active">Active</option>
              <option value="pending">Pending</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>

          {/* Existing images */}
          {existingImages.length > 0 && (
            <div className="form-group">
              <label>Current Images</label>
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 4 }}>
                {existingImages.map((src, i) => (
                  <div key={i} style={{ position: 'relative' }}>
                    <img
                      src={src}
                      alt="current"
                      style={{ width: 70, height: 70, objectFit: 'cover', borderRadius: 6 }}
                    />
                    <button
                      type="button"
                      onClick={() => removeExistingImage(i)}
                      style={{
                        position: 'absolute',
                        top: -5,
                        right: -5,
                        background: 'red',
                        color: 'white',
                        borderRadius: '50%',
                        width: 18,
                        height: 18,
                        border: 'none',
                        cursor: 'pointer',
                        fontSize: 11,
                      }}
                    >
                      ×
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="form-group">
            <label>Upload New Images (Optional)</label>
            <input
              type="file"
              multiple
              accept="image/*"
              onChange={handleImageUpload}
            />
            {previews.length > 0 && (
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 8 }}>
                {previews.map((src, i) => (
                  <div key={i} style={{ position: 'relative' }}>
                    <img
                      src={src}
                      alt="new-preview"
                      style={{ width: 70, height: 70, objectFit: 'cover', borderRadius: 6 }}
                    />
                    <button
                      type="button"
                      onClick={() => removeNewImage(i)}
                      style={{
                        position: 'absolute',
                        top: -5,
                        right: -5,
                        background: 'red',
                        color: 'white',
                        borderRadius: '50%',
                        width: 18,
                        height: 18,
                        border: 'none',
                        cursor: 'pointer',
                        fontSize: 11,
                      }}
                    >
                      ×
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="form-actions">
            <button className="cancel-btn" onClick={onClose} disabled={submitting}>
              Cancel
            </button>
            <button
              className="create-btn"
              onClick={handleSubmit}
              disabled={submitting}
            >
              {submitting ? 'Saving…' : 'Save Changes'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EditEventModal;
