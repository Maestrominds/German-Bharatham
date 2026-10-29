import React, { useEffect, useState } from 'react';
import { X } from 'lucide-react';
import API_URL from '../config';

const REQ = <span style={{ color: 'red' }}>*</span>;

// ── helpers ──────────────────────────────────────────────────────────────────

const ImageUpload = ({ images, onChange }) => (
  <div className="form-group">
    <label>Photos <span style={{ color: '#6b7280', fontSize: 12 }}>(Optional - JPG, JPEG, PNG)</span></label>
    <input type="file" accept="image/*" multiple onChange={e => {
      const valid = Array.from(e.target.files).filter(f => /^image\//.test(f.type));
      if (valid.length !== e.target.files.length) alert('Only image files are allowed.');
      valid.forEach(f => {
        const r = new FileReader();
        r.onloadend = () => onChange(prev => [...prev, r.result]);
        r.readAsDataURL(f);
      });
      e.target.value = '';
    }} />
    {images.length > 0 && (
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 6 }}>
        {images.map((img, i) => (
          <div key={i} style={{ position: 'relative' }}>
            <img src={img} alt={`up-${i}`} style={{ width: 80, height: 65, objectFit: 'cover', borderRadius: 6, border: '2px solid #6b9976' }} />
            <button type="button" onClick={() => onChange(prev => prev.filter((_, x) => x !== i))}
              style={{ position: 'absolute', top: -6, right: -6, background: '#ef4444', color: '#fff', border: 'none', borderRadius: '50%', width: 18, height: 18, fontSize: 11, cursor: 'pointer', padding: 0, lineHeight: '18px', textAlign: 'center' }}>✕</button>
          </div>
        ))}
      </div>
    )}
  </div>
);

const ChipsInput = ({ label, options, selected, onToggle, onTypeAdd }) => {
  const [typed, setTyped] = useState('');
  return (
    <div className="form-group">
      <label>{label}</label>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 6 }}>
        {options.map(o => (
          <button key={o} type="button" onClick={() => onToggle(o)}
            style={{ padding: '4px 12px', borderRadius: 20, fontSize: 13, border: '1px solid #6b9976', background: selected.includes(o) ? '#6b9976' : '#fff', color: selected.includes(o) ? '#fff' : '#374151', cursor: 'pointer' }}>
            {o}
          </button>
        ))}
      </div>
      {onTypeAdd && (
        <div style={{ display: 'flex', gap: 6 }}>
          <input value={typed} onChange={e => setTyped(e.target.value)} placeholder="Type custom…" style={{ flex: 1 }} onKeyDown={e => { if (e.key === 'Enter') { e.preventDefault(); if (typed.trim()) { onTypeAdd(typed.trim()); setTyped(''); } } }} />
          <button type="button" onClick={() => { if (typed.trim()) { onTypeAdd(typed.trim()); setTyped(''); } }} style={{ padding: '6px 12px', background: '#6b9976', color: '#fff', border: 'none', borderRadius: 6, cursor: 'pointer' }}>Add</button>
        </div>
      )}
    </div>
  );
};

// ── Category forms ────────────────────────────────────────────────────────────

const AccommodationForm = ({ data, set }) => {
  const amenityOpts = ['Balcony','Terrace','Garden','Lift','Parking','Garage','Cellar','Washing Machine','Dishwasher','Kitchen','Pets Allowed','Smoking Allowed','Anmeldung Possible','Student Friendly','Wheelchair Accessible'];
  return (
    <>
      {/* Basic Information */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Basic Information</h4>
        <div className="form-row">
          <div className="form-group">
            <label>Title {REQ}</label>
            <input value={data.title} onChange={e => set(p => ({...p, title: e.target.value}))} placeholder="Cozy 2-Bedroom Apartment" />
          </div>
          <div className="form-group">
            <label>Property Type {REQ}</label>
            <select value={data.propertyType} onChange={e => set(p => ({...p, propertyType: e.target.value}))}>
              <option value="apartment">Apartment</option>
              <option value="temporary_stays">Temporary Stays</option>
              <option value="shared_rooms">Shared Rooms</option>
            </select>
          </div>
        </div>
      </div>

      {/* Location Details */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>📍 Location Details</h4>
        <div className="form-row">
          <div className="form-group">
            <label>City {REQ}</label>
            <input value={data.city} onChange={e => set(p => ({...p, city: e.target.value}))} placeholder="Munich" />
          </div>
          <div className="form-group">
            <label>Postal Code {REQ}</label>
            <input value={data.postalCode} onChange={e => { e.target.value = e.target.value.replace(/[^0-9]/g, ''); set(p => ({...p, postalCode: e.target.value}))}} placeholder="80331" />
          </div>
        </div>
        <div className="form-row">
          <div className="form-group">
            <label>Area {REQ}</label>
            <input value={data.area} onChange={e => set(p => ({...p, area: e.target.value}))} placeholder="Schwabing" />
          </div>
          <div className="form-group">
            <label>Address {REQ}</label>
            <input value={data.address} onChange={e => set(p => ({...p, address: e.target.value}))} placeholder="Leopoldstraße 1" />
          </div>
        </div>
      </div>

      {/* Contact & Description */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>📞 Contact & Description</h4>
        <div className="form-group">
          <label>Contact Phone {REQ}</label>
          <input value={data.contactPhone} onChange={e => { e.target.value = e.target.value.replace(/[^0-9]/g, ''); set(p => ({...p, contactPhone: e.target.value}))}} placeholder="491701234567" />
        </div>
        <div className="form-group">
          <label>Description {REQ}</label>
          <textarea value={data.description} onChange={e => set(p => ({...p, description: e.target.value}))} rows={3} placeholder="Detailed description…" />
        </div>
        <div className="form-group">
          <label>Link / Website <span style={{ color: '#6b7280', fontSize: 12 }}>(Optional)</span></label>
          <input value={data.link || data.externalUrl || data.website || ''} onChange={e => set(p => ({...p, link: e.target.value, externalUrl: e.target.value, website: e.target.value}))} placeholder="https://..." />
        </div>
      </div>

      {/* Pricing */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>💶 Pricing</h4>
        <div className="form-row">
          <div className="form-group">
            <label>Cold Rent (€) {REQ}</label>
            <input type="number" value={data.coldRent} onChange={e => set(p => ({...p, coldRent: e.target.value}))} placeholder="800" />
          </div>
          <div className="form-group">
            <label>Warm Rent (€) {REQ}</label>
            <input type="number" value={data.warmRent} onChange={e => set(p => ({...p, warmRent: e.target.value}))} placeholder="1000" />
          </div>
          <div className="form-group">
            <label>Deposit (€) {REQ}</label>
            <input type="number" value={data.deposit} onChange={e => set(p => ({...p, deposit: e.target.value}))} placeholder="2400" />
          </div>
        </div>
      </div>

      {/* Property Details */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>🏠 Property Details</h4>
        <div className="form-row">
          <div className="form-group">
            <label>Size (sqm) {REQ}</label>
            <input type="number" value={data.sizeSqm} onChange={e => set(p => ({...p, sizeSqm: e.target.value}))} placeholder="50" />
          </div>
          <div className="form-group">
            <label>Bedrooms {REQ}</label>
            <input type="number" value={data.bedrooms} onChange={e => set(p => ({...p, bedrooms: e.target.value}))} placeholder="2" />
          </div>
          <div className="form-group">
            <label>Bathrooms {REQ}</label>
            <input type="number" value={data.bathrooms} onChange={e => set(p => ({...p, bathrooms: e.target.value}))} placeholder="1" />
          </div>
        </div>
      </div>

      {/* Amenities */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Amenities</h4>
        <ChipsInput label="Amenities (select or toggle)" options={amenityOpts}
          selected={data.amenities}
          onToggle={a => set(p => ({ ...p, amenities: p.amenities.includes(a) ? p.amenities.filter(x => x !== a) : [...p.amenities, a] }))}
        />
      </div>

      {/* Images */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>📷 Images</h4>
        <ImageUpload images={data.images} onChange={fn => set(p => ({ ...p, images: fn(p.images) }))} />
      </div>
    </>
  );
};

const JobsForm = ({ data, set }) => {
  return (
    <>
      {/* Basic Information */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Basic Information</h4>
        <div className="form-row">
          <div className="form-group">
            <label>Title {REQ}</label>
            <input value={data.title} onChange={e => set(p => ({...p, title: e.target.value}))} placeholder="Job Title" />
          </div>
          <div className="form-group">
            <label>Location {REQ}</label>
            <input value={data.location} onChange={e => set(p => ({...p, location: e.target.value}))} placeholder="Munich" />
          </div>
        </div>
        <div className="form-row">
          <div className="form-group">
            <label>Contact Details</label>
            <input value={data.contact} onChange={e => set(p => ({...p, contact: e.target.value}))} placeholder="Email or Phone number" />
          </div>
        </div>
      </div>

      {/* Description */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Description</h4>
        <div className="form-group">
          <label>Description {REQ}</label>
          <textarea value={data.description} onChange={e => set(p => ({...p, description: e.target.value}))} rows={3} placeholder="Enter Description" />
        </div>
      </div>

      {/* Job Details */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>💼 Job Details</h4>
        <div className="form-row">
          <div className="form-group">
            <label>Country</label>
            <input value={data.country || 'Germany'} onChange={e => set(p => ({...p, country: e.target.value}))} placeholder="Germany" />
          </div>
          <div className="form-group">
            <label>Field / Domain</label>
            <input value={data.domain || ''} onChange={e => set(p => ({...p, domain: e.target.value}))} placeholder="e.g. IT / Technology, Healthcare, Engineering" />
          </div>
        </div>
        <div className="form-row">
          <div className="form-group">
            <label>Salary</label>
            <input value={data.salary} onChange={e => set(p => ({...p, salary: e.target.value}))} placeholder="€3,000/month" />
          </div>
        </div>
        <div className="form-row">
          <div className="form-group">
            <label>Company Name {REQ}</label>
            <input value={data.companyName} onChange={e => set(p => ({...p, companyName: e.target.value}))} placeholder="Company Name" />
          </div>
          <div className="form-group">
            <label>Company Logo {REQ}</label>
            <input type="file" onChange={(e) => {
              const file = e.target.files[0];
              if (file) {
                // Handle file upload here
                const reader = new FileReader();
                reader.onloadend = () => {
                  set(p => ({...p, companyLogo: reader.result}));
                };
                reader.readAsDataURL(file);
              }
            }} />
          </div>
        </div>
        <div className="form-row">
          <div className="form-group">
            <label>Type {REQ}</label>
            <select value={data.type} onChange={e => set(p => ({...p, type: e.target.value}))}>
              <option>Full Time</option>
              <option>Part Time</option>
              <option>Contract</option>
              <option>Internship</option>
              <option>Freelance</option>
            </select>
          </div>
        </div>
      </div>

      {/* Requirements & Benefits */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Requirements & Benefits</h4>
        <div className="form-group">
          <label>Requirements {REQ}</label>
          <textarea value={data.requirements} onChange={e => set(p => ({...p, requirements: e.target.value}))} rows={3} placeholder="Enter skills and qualifications (comma-separated)" />
        </div>
        <div className="form-group">
          <label>Benefits {REQ}</label>
          <textarea value={data.benefits} onChange={e => set(p => ({...p, benefits: e.target.value}))} rows={3} placeholder="Enter job benefits (comma-separated)" />
        </div>
      </div>

      {/* Application */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>📝 Application</h4>
        <div className="form-group">
          <label>Apply URL {REQ}</label>
          <input value={data.applyUrl} onChange={e => set(p => ({...p, applyUrl: e.target.value}))} placeholder="https://company.com/apply" />
        </div>
      </div>
    </>
  );
};

const ServicesForm = ({ data, set }) => {
  const serviceTypes = ['Immigration', 'Legal', 'Financial', 'Tax', 'Consultation', 'Home Services', 'Tuition & Coaching', 'IT Services', 'Education', 'Relocation', 'Translation', 'Other'];
  return (
    <>
      <div className="form-row">
        <div className="form-group">
          <label>Service Name {REQ}</label>
          <input value={data.serviceName} onChange={e => set(p => ({...p, serviceName: e.target.value}))} placeholder="Visa Consultation" />
        </div>
        <div className="form-group">
          <label>Provider Name {REQ}</label>
          <input value={data.providerName} onChange={e => set(p => ({...p, providerName: e.target.value}))} placeholder="Max Mustermann" />
        </div>
      </div>
      <div className="form-row">
        <div className="form-group">
          <label>City {REQ}</label>
          <input value={data.city} onChange={e => set(p => ({...p, city: e.target.value}))} placeholder="Munich" />
        </div>
        <div className="form-group">
          <label>Postal Code {REQ}</label>
          <input value={data.postalCode} onChange={e => set(p => ({...p, postalCode: e.target.value}))} placeholder="80331" />
        </div>
      </div>
      <div className="form-row">
        <div className="form-group">
          <label>Area {REQ}</label>
          <input value={data.area} onChange={e => set(p => ({...p, area: e.target.value}))} placeholder="Maxvorstadt" />
        </div>
        <div className="form-group">
          <label>Address {REQ}</label>
          <input value={data.address} onChange={e => set(p => ({...p, address: e.target.value}))} placeholder="Street, No." />
        </div>
      </div>
      <div className="form-row">
        <div className="form-group">
          <label>Contact Phone {REQ}</label>
          <input value={data.contactPhone} onChange={e => { e.target.value = e.target.value.replace(/[^0-9]/g, ''); set(p => ({...p, contactPhone: e.target.value}))}} placeholder="491701234567" />
        </div>
        <div className="form-group">
          <label>Price Range {REQ}</label>
          <select value={data.priceRange} onChange={e => set(p => ({...p, priceRange: e.target.value}))}>
            <option value="€">€ (Low)</option>
            <option value="€€">€€ (Medium)</option>
            <option value="€€€">€€€ (Premium)</option>
            <option value="€€€€">€€€€ (Luxury)</option>
          </select>
        </div>
      </div>

      <div className="form-row">
        <div className="form-group">
          <label>WhatsApp {REQ}</label>
          <input value={data.whatsapp} onChange={e => { e.target.value = e.target.value.replace(/[^0-9]/g, ''); set(p => ({...p, whatsapp: e.target.value}))}} placeholder="491701234567" />
        </div>
        <div className="form-group">
          <label>Email {REQ}</label>
          <input value={data.email} onChange={e => set(p => ({...p, email: e.target.value}))} placeholder="name@example.com" />
        </div>
      </div>

      <div className="form-row">
        <div className="form-group">
          <label>Website {REQ}</label>
          <input value={data.website} onChange={e => set(p => ({...p, website: e.target.value}))} placeholder="https://example.com" />
        </div>
        <div className="form-group">
          <label>Latitude {REQ}</label>
          <input value={data.latitude} onChange={e => set(p => ({...p, latitude: e.target.value}))} placeholder="48.137154" />
        </div>
      </div>

      <div className="form-row">
        <div className="form-group">
          <label>Longitude {REQ}</label>
          <input value={data.longitude} onChange={e => set(p => ({...p, longitude: e.target.value}))} placeholder="11.576124" />
        </div>
        <div className="form-group" />
      </div>
      <div className="form-group">
        <label>Service Type</label>
        <select value={data.serviceType} onChange={e => set(p => ({...p, serviceType: e.target.value}))}>
          <option value="">— select —</option>
          {serviceTypes.map(t => <option key={t}>{t}</option>)}
        </select>
      </div>
      <div className="form-group">
        <label>Description {REQ}</label>
        <textarea value={data.description} onChange={e => set(p => ({...p, description: e.target.value}))} rows={3} placeholder="What you offer…" />
      </div>

      <div className="form-group">
        <label>Services Offered {REQ}</label>
        <textarea
          value={data.amenitiesText}
          onChange={e => set(p => ({ ...p, amenitiesText: e.target.value }))}
          rows={3}
          placeholder="Accommodation search assistance, Moving & settling support, Temporary housing arrangement"
        />
        <div style={{ fontSize: 12, color: '#6b7280', marginTop: 6 }}>
          Enter as comma-separated values (or one per line).
        </div>
      </div>

      <ImageUpload images={data.images} onChange={fn => set(p => ({ ...p, images: fn(p.images) }))} />
    </>
  );
};

const SecondHandStoreForm = ({ data, set }) => {
  return (
    <>
      {/* Basic Information */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Basic Information</h4>
        <div className="form-group">
          <label>Title {REQ}</label>
          <input value={data.title} onChange={e => set(p => ({...p, title: e.target.value}))} placeholder="Product Title" />
        </div>
        <div className="form-group">
          <label>Description {REQ}</label>
          <textarea value={data.description} onChange={e => set(p => ({...p, description: e.target.value}))} rows={3} placeholder="Detailed description of the item…" />
        </div>
        <div className="form-group">
          <label>Price</label>
          <input value={data.price} onChange={e => set(p => ({...p, price: e.target.value}))} placeholder="€50" />
        </div>
      </div>

      {/* Contact Details */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Contact Details</h4>
        <div className="form-row">
          <div className="form-group">
            <label>Contact Phone</label>
            <input value={data.contactPhone} onChange={e => set(p => ({...p, contactPhone: e.target.value}))} placeholder="Phone number" />
          </div>
          <div className="form-group">
            <label>Contact Email</label>
            <input value={data.contactEmail} onChange={e => set(p => ({...p, contactEmail: e.target.value}))} placeholder="Email address" />
          </div>
        </div>
      </div>

      {/* Delivery */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Delivery</h4>
        <div className="form-group">
          <label>Delivery Option</label>
          <select value={data.deliveryOption} onChange={e => set(p => ({...p, deliveryOption: e.target.value}))}>
            <option value="">— select —</option>
            <option value="Shipping Possible">Shipping Possible</option>
            <option value="Pickup only">Pickup only</option>
          </select>
        </div>
      </div>

      {/* External Link */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Link</h4>
        <div className="form-group">
          <label>Link / Website <span style={{ color: '#6b7280', fontSize: 12 }}>(Optional)</span></label>
          <input value={data.link || data.externalUrl || ''} onChange={e => set(p => ({...p, link: e.target.value, externalUrl: e.target.value}))} placeholder="https://..." />
        </div>
      </div>

      {/* Images */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>📷 Images (Max 5)</h4>
        <ImageUpload images={data.images} onChange={fn => {
          set(p => {
            const nextImages = fn(p.images);
            if (nextImages.length > 5) {
              alert("You can only upload a maximum of 5 images for Second Hand Store.");
              return p;
            }
            return { ...p, images: nextImages };
          });
        }} />
      </div>
    </>
  );
};

const EVENT_CATEGORIES = [
  { value: 'festivals', label: 'Festivals & Celebrations' },
  { value: 'movies', label: 'Movies & Screenings' },
  { value: 'performing_arts', label: 'Music, Dance & Theatre' },
  { value: 'classes', label: 'Classes & Workshops' },
  { value: 'food', label: 'Food Events' },
  { value: 'markets', label: 'Melas & Markets' },
  { value: 'sports', label: 'Sports & Outdoors' },
  { value: 'meetups', label: 'Meetups & Networking' },
  { value: 'religious', label: 'Religious & Spiritual' },
  { value: 'contests', label: 'Contests & Calls' },
];

const EVENT_FORMATS = [
  { value: 'one_day', label: 'One-day Event (Festival, Concert, Meetup)' },
  { value: 'multi_day', label: 'Multi-day (3-day mela or festival)' },
  { value: 'course', label: 'Course / Class (Weekly classes, ongoing)' },
  { value: 'workshop', label: 'Workshop (1–3 sessions, required)' },
  { value: 'screening', label: 'Movie Screening (Cinema showtimes)' },
  { value: 'deadline', label: 'Deadline (Contest, Call for entries)' },
];

const WEEKDAYS = [
  { id: 1, label: 'Mon' },
  { id: 2, label: 'Tue' },
  { id: 3, label: 'Wed' },
  { id: 4, label: 'Thu' },
  { id: 5, label: 'Fri' },
  { id: 6, label: 'Sat' },
  { id: 7, label: 'Sun' },
];

const EventsForm = ({ data, set }) => {
  const format = data.format || 'one_day';
  const isOnline = !!data.isOnline;
  const sessions = Array.isArray(data.sessions) ? data.sessions : [];
  const daysOfWeek = Array.isArray(data.daysOfWeek) ? data.daysOfWeek : [];

  const handleAddSession = () => {
    set(p => ({
      ...p,
      sessions: [
        ...(Array.isArray(p.sessions) ? p.sessions : []),
        { date: p.startsAt ? p.startsAt.split('T')[0] : '', time: '', label: '', address: '', language: 'Tamil', subtitles: 'English', link: '' },
      ],
    }));
  };

  const handleUpdateSession = (index, field, val) => {
    set(p => {
      const copy = [...(Array.isArray(p.sessions) ? p.sessions : [])];
      copy[index] = { ...copy[index], [field]: val };
      return { ...p, sessions: copy };
    });
  };

  const handleRemoveSession = (index) => {
    set(p => ({
      ...p,
      sessions: (Array.isArray(p.sessions) ? p.sessions : []).filter((_, i) => i !== index),
    }));
  };

  const toggleDayOfWeek = (dayId) => {
    set(p => {
      const current = Array.isArray(p.daysOfWeek) ? p.daysOfWeek : [];
      const updated = current.includes(dayId) ? current.filter(d => d !== dayId) : [...current, dayId];
      return { ...p, daysOfWeek: updated.sort() };
    });
  };

  return (
    <>
      {/* 1. Format Selection */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>1. Event Format</h4>
        <div className="form-group">
          <label>Select Format {REQ}</label>
          <select
            value={format}
            onChange={e => {
              const newFmt = e.target.value;
              set(p => ({
                ...p,
                format: newFmt,
                category: newFmt === 'screening' ? 'movies' : (newFmt === 'course' ? 'classes' : (newFmt === 'deadline' ? 'contests' : p.category)),
              }));
            }}
          >
            {EVENT_FORMATS.map(f => (
              <option key={f.value} value={f.value}>{f.label}</option>
            ))}
          </select>
        </div>
      </div>

      {/* 2. Basic Information */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>2. Basic Information</h4>
        <div className="form-row">
          <div className="form-group">
            <label>Event Title {REQ}</label>
            <input value={data.title} onChange={e => set(p => ({ ...p, title: e.target.value }))} placeholder="Deepavali 2026 or Jailer 2" />
          </div>
          <div className="form-group">
            <label>Category {REQ}</label>
            <select value={data.category} onChange={e => set(p => ({ ...p, category: e.target.value }))}>
              {EVENT_CATEGORIES.map(c => (
                <option key={c.value} value={c.value}>{c.label}</option>
              ))}
            </select>
          </div>
        </div>

        <div className="form-row">
          <div className="form-group">
            <label>Short Description (Card text, ≤160 chars)</label>
            <input
              maxLength={160}
              value={data.shortDescription || ''}
              onChange={e => set(p => ({ ...p, shortDescription: e.target.value }))}
              placeholder="Quick one-line summary displayed on event cards"
            />
          </div>
          <div className="form-group">
            <label>Languages (comma separated)</label>
            <input
              value={Array.isArray(data.languages) ? data.languages.join(', ') : (data.languages || '')}
              onChange={e => set(p => ({ ...p, languages: e.target.value.split(',').map(s => s.trim()).filter(Boolean) }))}
              placeholder="Tamil, English, Hindi"
            />
          </div>
        </div>
      </div>

      {/* 3. Date & Time (Changes dynamically based on format) */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>3. Date & Schedule</h4>
        
        {format === 'one_day' && (
          <div className="form-row">
            <div className="form-group">
              <label>Event Date {REQ}</label>
              <input
                type="date"
                value={data.startsAt ? data.startsAt.split('T')[0] : ''}
                onChange={e => {
                  const val = e.target.value;
                  set(p => ({ ...p, startsAt: val ? `${val}T10:00:00` : '', endsAt: val ? `${val}T23:59:59` : '' }));
                }}
              />
            </div>
            <div className="form-group">
              <label>Time Text (Card label)</label>
              <input
                value={data.timeText || ''}
                onChange={e => set(p => ({ ...p, timeText: e.target.value }))}
                placeholder='e.g. "from 11:30" or "10:00–14:00"'
              />
            </div>
          </div>
        )}

        {(format === 'multi_day' || format === 'workshop') && (
          <div className="form-row">
            <div className="form-group">
              <label>Start Date {REQ}</label>
              <input
                type="date"
                value={data.startsAt ? data.startsAt.split('T')[0] : ''}
                onChange={e => set(p => ({ ...p, startsAt: e.target.value ? `${e.target.value}T10:00:00` : '' }))}
              />
            </div>
            <div className="form-group">
              <label>End Date {REQ}</label>
              <input
                type="date"
                value={data.endsAt ? data.endsAt.split('T')[0] : ''}
                onChange={e => set(p => ({ ...p, endsAt: e.target.value ? `${e.target.value}T22:00:00` : '' }))}
              />
            </div>
          </div>
        )}

        {format === 'deadline' && (
          <div className="form-row">
            <div className="form-group">
              <label>Opens Date</label>
              <input
                type="date"
                value={data.startsAt ? data.startsAt.split('T')[0] : ''}
                onChange={e => set(p => ({ ...p, startsAt: e.target.value ? `${e.target.value}T00:00:00` : '' }))}
              />
            </div>
            <div className="form-group">
              <label>Submission Deadline (Closes) {REQ}</label>
              <input
                type="date"
                value={data.endsAt ? data.endsAt.split('T')[0] : ''}
                onChange={e => set(p => ({ ...p, endsAt: e.target.value ? `${e.target.value}T23:59:59` : '' }))}
              />
            </div>
          </div>
        )}

        {format === 'course' && (
          <>
            <div className="form-row">
              <div className="form-group">
                <label>Course Start Date {REQ}</label>
                <input
                  type="date"
                  value={data.startsAt ? data.startsAt.split('T')[0] : ''}
                  onChange={e => {
                    const startVal = e.target.value;
                    set(p => {
                      if (!startVal) return { ...p, startsAt: '', endsAt: '' };
                      const s = new Date(startVal);
                      const e90 = new Date(s.getTime() + 90 * 24 * 60 * 60 * 1000);
                      return {
                        ...p,
                        startsAt: `${startVal}T10:00:00`,
                        endsAt: p.ongoing ? e90.toISOString().split('T')[0] + 'T23:59:59' : p.endsAt,
                      };
                    });
                  }}
                />
              </div>
              <div className="form-group" style={{ display: 'flex', alignItems: 'center', marginTop: 24 }}>
                <label style={{ cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 8 }}>
                  <input
                    type="checkbox"
                    checked={!!data.ongoing}
                    onChange={e => {
                      const ongoingVal = e.target.checked;
                      set(p => {
                        let ends = p.endsAt;
                        if (ongoingVal && p.startsAt) {
                          const s = new Date(p.startsAt);
                          ends = new Date(s.getTime() + 90 * 24 * 60 * 60 * 1000).toISOString().split('T')[0] + 'T23:59:59';
                        }
                        return { ...p, ongoing: ongoingVal, endsAt: ends };
                      });
                    }}
                  />
                  <span>Ongoing course (Join anytime, +90 days)</span>
                </label>
              </div>
            </div>

            <div className="form-group" style={{ marginBottom: 16 }}>
              <label>Days of Week Class Meets</label>
              <div style={{ display: 'flex', gap: 8, marginTop: 6 }}>
                {WEEKDAYS.map(w => (
                  <button
                    key={w.id}
                    type="button"
                    onClick={() => toggleDayOfWeek(w.id)}
                    style={{
                      padding: '6px 12px',
                      borderRadius: 8,
                      border: '1px solid #cbd5e1',
                      background: daysOfWeek.includes(w.id) ? '#2d5a3d' : '#f8fafc',
                      color: daysOfWeek.includes(w.id) ? '#fff' : '#334155',
                      fontWeight: daysOfWeek.includes(w.id) ? 700 : 500,
                      cursor: 'pointer',
                    }}
                  >
                    {w.label}
                  </button>
                ))}
              </div>
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Level</label>
                <select value={data.level || 'all'} onChange={e => set(p => ({ ...p, level: e.target.value }))}>
                  <option value="all">All Levels</option>
                  <option value="beginner">Beginner</option>
                  <option value="intermediate">Intermediate</option>
                  <option value="advanced">Advanced</option>
                </select>
              </div>
              <div className="form-group">
                <label>Age Group</label>
                <select value={data.ageGroup || 'all'} onChange={e => set(p => ({ ...p, ageGroup: e.target.value }))}>
                  <option value="all">All Ages</option>
                  <option value="kids">Kids</option>
                  <option value="teens">Teens</option>
                  <option value="adults">Adults</option>
                </select>
              </div>
            </div>
          </>
        )}

        {format === 'screening' && (
          <div className="form-row">
            <div className="form-group">
              <label>Run Start Date</label>
              <input
                type="date"
                value={data.startsAt ? data.startsAt.split('T')[0] : ''}
                onChange={e => set(p => ({ ...p, startsAt: e.target.value ? `${e.target.value}T10:00:00` : '' }))}
              />
            </div>
            <div className="form-group">
              <label>Run End Date</label>
              <input
                type="date"
                value={data.endsAt ? data.endsAt.split('T')[0] : ''}
                onChange={e => set(p => ({ ...p, endsAt: e.target.value ? `${e.target.value}T23:59:59` : '' }))}
              />
            </div>
          </div>
        )}
      </div>

      {/* 4. Sessions / Showtimes Repeater */}
      <div style={{ marginBottom: 20 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', margin: 0 }}>
            {format === 'screening' ? '🎬 Cinema Showtimes Table' : '🕒 Time Slots / Sessions (Optional)'}
          </h4>
          <button
            type="button"
            onClick={handleAddSession}
            style={{
              padding: '6px 12px',
              borderRadius: 8,
              border: 'none',
              background: '#e6f4ea',
              color: '#137333',
              fontWeight: 600,
              fontSize: 13,
              cursor: 'pointer',
            }}
          >
            + Add {format === 'screening' ? 'Cinema Show' : 'Time Slot'}
          </button>
        </div>

        {sessions.length === 0 ? (
          <p style={{ fontSize: 13, color: '#64748b', fontStyle: 'italic', margin: 0 }}>
            {format === 'screening'
              ? 'Click "+ Add Cinema Show" to list cinemas, showtimes, languages, and booking links.'
              : 'No separate time slots added. Click "+ Add Time Slot" if your event has multiple booking slots.'}
          </p>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {sessions.map((sess, idx) => (
              <div
                key={idx}
                style={{
                  background: '#f8fafc',
                  border: '1px solid #e2e8f0',
                  borderRadius: 10,
                  padding: 12,
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                  <span style={{ fontWeight: 700, fontSize: 13, color: '#1e293b' }}>
                    #{idx + 1} {sess.label || (format === 'screening' ? 'Cinema Name' : 'Slot')}
                  </span>
                  <button
                    type="button"
                    onClick={() => handleRemoveSession(idx)}
                    style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', fontSize: 12, fontWeight: 600 }}
                  >
                    Remove
                  </button>
                </div>
                <div className="form-row">
                  <div className="form-group">
                    <label style={{ fontSize: 12 }}>{format === 'screening' ? 'Cinema Name' : 'Slot Name'}</label>
                    <input
                      style={{ fontSize: 13, padding: 8 }}
                      value={sess.label || ''}
                      onChange={e => handleUpdateSession(idx, 'label', e.target.value)}
                      placeholder={format === 'screening' ? 'Mathäser Filmpalast' : 'Slot 1'}
                    />
                  </div>
                  <div className="form-group">
                    <label style={{ fontSize: 12 }}>Date & Time</label>
                    <div style={{ display: 'flex', gap: 6 }}>
                      <input
                        type="date"
                        style={{ fontSize: 13, padding: 8, flex: 1 }}
                        value={sess.date || ''}
                        onChange={e => handleUpdateSession(idx, 'date', e.target.value)}
                      />
                      <input
                        style={{ fontSize: 13, padding: 8, width: 85 }}
                        value={sess.time || ''}
                        onChange={e => handleUpdateSession(idx, 'time', e.target.value)}
                        placeholder="20:30"
                      />
                    </div>
                  </div>
                </div>
                <div className="form-row">
                  <div className="form-group">
                    <label style={{ fontSize: 12 }}>Address</label>
                    <input
                      style={{ fontSize: 13, padding: 8 }}
                      value={sess.address || ''}
                      onChange={e => handleUpdateSession(idx, 'address', e.target.value)}
                      placeholder="Bayerstr. 3-5, 80335 München"
                    />
                  </div>
                  <div className="form-group">
                    <label style={{ fontSize: 12 }}>Language & Subtitles</label>
                    <div style={{ display: 'flex', gap: 6 }}>
                      <input
                        style={{ fontSize: 13, padding: 8, flex: 1 }}
                        value={sess.language || ''}
                        onChange={e => handleUpdateSession(idx, 'language', e.target.value)}
                        placeholder="Tamil"
                      />
                      <input
                        style={{ fontSize: 13, padding: 8, flex: 1 }}
                        value={sess.subtitles || ''}
                        onChange={e => handleUpdateSession(idx, 'subtitles', e.target.value)}
                        placeholder="English"
                      />
                    </div>
                  </div>
                </div>
                <div className="form-group">
                  <label style={{ fontSize: 12 }}>Booking / Ticket Link</label>
                  <input
                    style={{ fontSize: 13, padding: 8 }}
                    value={sess.link || ''}
                    onChange={e => handleUpdateSession(idx, 'link', e.target.value)}
                    placeholder="https://cinema-booking.de/..."
                  />
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* 5. Location / Venue */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>5. Location</h4>
        <div style={{ marginBottom: 10 }}>
          <label style={{ cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 8 }}>
            <input
              type="checkbox"
              checked={isOnline}
              onChange={e => set(p => ({ ...p, isOnline: e.target.checked }))}
            />
            <span>This is an Online Event / Contest (Zoom, YouTube, Instagram)</span>
          </label>
        </div>

        {isOnline ? (
          <div className="form-group">
            <label>Online Meeting / Contest Link {REQ}</label>
            <input
              value={data.onlineLink || ''}
              onChange={e => set(p => ({ ...p, onlineLink: e.target.value }))}
              placeholder="https://zoom.us/j/... or https://instagram.com/reel/..."
            />
          </div>
        ) : (
          <>
            <div className="form-row">
              <div className="form-group">
                <label>City {REQ}</label>
                <input value={data.city} onChange={e => set(p => ({ ...p, city: e.target.value }))} placeholder="Munich" />
              </div>
              <div className="form-group">
                <label>Venue / Hall Name</label>
                <input value={data.venue} onChange={e => set(p => ({ ...p, venue: e.target.value }))} placeholder="Stadt. Willi-Graf-Gymnasium" />
              </div>
            </div>
            <div className="form-group">
              <label>Full Address</label>
              <input value={data.address || ''} onChange={e => set(p => ({ ...p, address: e.target.value }))} placeholder="Borschtallee 26, 80804 München" />
            </div>
          </>
        )}
      </div>

      {/* 6. Organizer & Contact */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>6. Organizer & Contact</h4>
        <div className="form-row">
          <div className="form-group">
            <label>Organizer Name {REQ}</label>
            <input value={data.organizer} onChange={e => set(p => ({ ...p, organizer: e.target.value }))} placeholder="Munich Tamil Kudumbam e.V." />
          </div>
          <div className="form-group">
            <label>Contact (WhatsApp / Phone / Email)</label>
            <input value={data.contact} onChange={e => set(p => ({ ...p, contact: e.target.value }))} placeholder="+49 176... or info@..." />
          </div>
        </div>
      </div>

      {/* 7. Pricing & Registration */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>7. Pricing & Registration</h4>
        <div className="form-row">
          <div className="form-group">
            <label>Price Type</label>
            <select value={data.priceType || 'paid'} onChange={e => set(p => ({ ...p, priceType: e.target.value }))}>
              <option value="paid">Paid</option>
              <option value="free">Free Admission</option>
              <option value="donation">Donation / Pay What You Want</option>
            </select>
          </div>
          <div className="form-group">
            <label>Price Text (e.g. "€15, kids free")</label>
            <input value={data.priceText || data.price || ''} onChange={e => set(p => ({ ...p, priceText: e.target.value, price: e.target.value }))} placeholder="€15, kids free" />
          </div>
        </div>
        <div className="form-group">
          <label>Registration / Ticket URL</label>
          <input value={data.ticketUrl} onChange={e => set(p => ({ ...p, ticketUrl: e.target.value }))} placeholder="https://events.example.de/register" />
        </div>
        <div style={{ marginTop: 8 }}>
          <label style={{ cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 8 }}>
            <input
              type="checkbox"
              checked={!!data.familyFriendly}
              onChange={e => set(p => ({ ...p, familyFriendly: e.target.checked }))}
            />
            <span>Family Friendly Event (Suitable for children and families)</span>
          </label>
        </div>
      </div>

      {/* 8. Description */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>8. Full Details</h4>
        <div className="form-group">
          <label>Description</label>
          <textarea value={data.description} onChange={e => set(p => ({ ...p, description: e.target.value }))} rows={4} placeholder="Full event schedule, instructions, performer line-ups..." />
        </div>
      </div>

      {/* 9. Photos */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>📷 Flyer / Poster (Portrait 4:5 recommended)</h4>
        <ImageUpload images={data.images} onChange={fn => set(p => ({ ...p, images: fn(p.images) }))} />
      </div>
    </>
  );
};

// ── Main modal ────────────────────────────────────────────────────────────────

const DEFAULTS = {
  Accommodation: { title:'', propertyType:'apartment', city:'', area:'', postalCode:'', address:'', contactPhone:'', description:'', link:'', coldRent:'', warmRent:'', deposit:'', sizeSqm:'', bedrooms:'', bathrooms:'', amenities:[], images:[], status:'pending' },
  Jobs: { title:'', location:'', contact:'', country:'Germany', domain:'', description:'', salary:'', status:'Pending', companyName:'', companyLogo:'', type:'Full Time', requirements:'', benefits:'', applyUrl:'' },
  Services: { serviceName:'', providerName:'', serviceType:'', city:'', area:'', postalCode:'', address:'', contactPhone:'', whatsapp:'', email:'', website:'', latitude:'', longitude:'', description:'', priceRange:'', amenitiesText:'', images:[], status:'pending' },
  'Second Hand Store': { title:'', description:'', price:'', contactPhone:'', contactEmail:'', deliveryOption:'', link:'', images:[], status:'Pending' },
  Events: {
    title: '',
    category: 'festivals',
    format: 'one_day',
    city: '',
    venue: '',
    address: '',
    isOnline: false,
    onlineLink: '',
    organizer: '',
    contact: '',
    timeText: '',
    startsAt: '',
    endsAt: '',
    price: '',
    priceType: 'paid',
    priceText: '',
    ticketUrl: '',
    shortDescription: '',
    description: '',
    images: [],
    languages: ['Tamil', 'English'],
    familyFriendly: false,
    daysOfWeek: [],
    ongoing: false,
    level: 'all',
    ageGroup: 'all',
    sessions: [],
    subtitles: 'none',
    status: 'Active',
  },
};

const CATEGORY_LABELS = ['Accommodation', 'Jobs', 'Services', 'Second Hand Store', 'Events'];
const normalizeStatus = (value, fallback = 'Pending') => {
  const raw = String(value || '').trim().toLowerCase();
  if (raw === 'active') return 'Active';
  if (raw === 'pending') return 'Pending';
  if (raw === 'inactive' || raw === 'disabled') return 'Inactive';
  return fallback;
};

const validate = (category, data) => {
  if (category === 'Accommodation') {
    if (!data.coldRent) return 'Cold Rent is required';
    if (!data.warmRent) return 'Warm Rent is required';
    if (!data.deposit) return 'Deposit is required';
    if (!data.sizeSqm) return 'Size (sqm) is required';
    if (!data.bedrooms) return 'Bedrooms is required';
    if (!data.bathrooms) return 'Bathrooms is required';
  }

  if (category === 'Jobs') {
  }
  if (category === 'Services') {
    const amenities = (data.amenitiesText ?? '')
      .toString()
      .split(/[,;\n]/)
      .map(s => s.trim())
      .filter(Boolean);
    if (amenities.length === 0) return 'Services Offered is required';
  }
  if (category === 'Second Hand Store') {
    if (!data.title?.trim()) return 'Title is required';
    if (!data.description?.trim()) return 'Description is required';
  }
  if (category === 'Events') {
    if (!data.title?.trim()) return 'Event title is required';
    if (!data.city?.trim()) return 'Event city is required';
  }
  return null;
};

const buildPayload = (category, data) => {
  if (category === 'Accommodation') {
    return {
      title: data.title?.trim(),
      propertyType: data.propertyType,
      city: data.city?.trim(),
      state: data.area?.trim() || null,
      zipCode: data.postalCode?.trim() || null,
      address: data.address?.trim() || null,
      contactPhone: data.contactPhone?.trim(),
      description: data.description?.trim() || null,
      website: data.link?.trim() || data.externalUrl?.trim() || data.website?.trim() || null,
      externalUrl: data.link?.trim() || data.externalUrl?.trim() || data.website?.trim() || null,
      status: data.status,
      rentDetails: { coldRent: +data.coldRent, warmRent: +data.warmRent, deposit: +data.deposit },
      propertyDetails: { sizeSqm: +data.sizeSqm, bedrooms: +data.bedrooms, bathrooms: +data.bathrooms },
      amenities: data.amenities.reduce((a, k) => {
        const key = k.replace(/ ([A-Z])/g, (_, c) => c.toLowerCase()).replace(/^./, c => c.toLowerCase()).replace(/ /g, '');
        a[key] = true; return a;
      }, {}),
      media: { images: data.images || [] },
      images: data.images || [],
      adminControls: { isActive: data.status === 'active' },
    };
  }

  if (category === 'Jobs') {
    const location = data.location?.trim() || '';
    const company = data.companyName?.trim() || '';
    const status = normalizeStatus(data.status, 'Pending');

    return {
      title: data.title?.trim(),
      location,
      city: location,
      country: data.country?.trim() || 'Germany',
      domain: data.domain?.trim() || null,
      contact: data.contact?.trim() || null,
      phone: data.contact?.trim() || null,
      description: data.description?.trim() || null,
      salary: data.salary?.trim() || null,
      status,
      company,
      companyName: company || null,
      companyLogo: data.companyLogo || null,
      jobType: data.type || 'Full Time',
      type: data.type || 'Full Time',
      requirements: data.requirements?.trim() || null,
      benefits: data.benefits?.trim() || null,
      applyUrl: data.applyUrl?.trim() || null,
    };
  }
  if (category === 'Services') {
    const lat = parseFloat(data.latitude);
    const lon = parseFloat(data.longitude);

    const amenities = (data.amenitiesText || '')
      .split(/[,;\n]/)
      .map(s => s.trim())
      .filter(Boolean);

    const serviceName = data.serviceName?.trim();
    const providerName = data.providerName?.trim();
    const contactPhone = data.contactPhone?.trim();
    const images = data.images || [];

    return {
      // Canonical fields (preferred by newer clients)
      title: serviceName,
      providerName,
      phone: contactPhone,
      whatsapp: data.whatsapp?.trim() || null,
      email: data.email?.trim() || null,
      website: data.website?.trim() || null,
      latitude: Number.isFinite(lat) ? lat : null,
      longitude: Number.isFinite(lon) ? lon : null,
      images,
      amenities,

      // Legacy fields (still used by some routes/UI)
      serviceName,
      serviceType: data.serviceType || null,
      city: data.city?.trim(),
      area: data.area?.trim() || null,
      postalCode: data.postalCode?.trim(),
      address: data.address?.trim() || null,
      contactPhone,
      description: data.description?.trim() || null,
      priceRange: data.priceRange?.trim() || null,
      media: { images },
      status: data.status,
    };
  }
  if (category === 'Second Hand Store') {
    return {
      title: data.title?.trim(),
      description: data.description?.trim() || null,
      price: data.price?.trim() || null,
      contactPhone: data.contactPhone?.trim() || null,
      contactEmail: data.contactEmail?.trim() || null,
      deliveryOption: data.deliveryOption?.trim() || null,
      externalUrl: data.link?.trim() || data.externalUrl?.trim() || null,
      images: data.images || [],
      status: normalizeStatus(data.status, 'Pending'),
    };
  }
  if (category === 'Events') {
    const format = data.format || 'one_day';
    let endsAt = data.endsAt;
    if (format === 'one_day' && data.startsAt && !endsAt) {
      endsAt = data.startsAt;
    }
    return {
      title: data.title?.trim(),
      category: data.category || 'festivals',
      format,
      city: data.city?.trim() || null,
      venue: data.venue?.trim() || null,
      address: data.address?.trim() || null,
      isOnline: !!data.isOnline,
      onlineLink: data.onlineLink?.trim() || null,
      organizer: data.organizer?.trim() || null,
      contact: data.contact?.trim() || null,
      timeText: data.timeText?.trim() || null,
      startsAt: data.startsAt ? new Date(data.startsAt).toISOString() : null,
      endsAt: endsAt ? new Date(endsAt).toISOString() : null,
      price: data.price?.trim() || null,
      priceType: data.priceType || 'paid',
      priceText: data.priceText?.trim() || data.price?.trim() || null,
      ticketUrl: data.ticketUrl?.trim() || null,
      externalUrl: data.ticketUrl?.trim() || null,
      shortDescription: data.shortDescription?.trim() || null,
      description: data.description?.trim() || null,
      images: data.images || [],
      languages: Array.isArray(data.languages) ? data.languages : [],
      familyFriendly: !!data.familyFriendly,
      daysOfWeek: Array.isArray(data.daysOfWeek) ? data.daysOfWeek : [],
      ongoing: !!data.ongoing,
      level: data.level || null,
      ageGroup: data.ageGroup || null,
      sessions: Array.isArray(data.sessions) ? data.sessions : null,
      subtitles: data.subtitles || null,
      status: normalizeStatus(data.status, 'Active'),
    };
  }
};

const API_MAP = {
  Accommodation: `${API_URL}/api/accommodation/admin`,
  Jobs: `${API_URL}/api/jobs/admin`,
  Services: `${API_URL}/api/services/admin`,
  'Second Hand Store': `${API_URL}/api/second-hand/admin`,
  Events: `${API_URL}/api/events/admin`,
};

const LOCAL_JOBS_API = `${API_URL}/api/jobs/admin`;

const mapItemToFormData = (category, item) => {
  if (!item) return DEFAULTS[category];

  if (category === 'Accommodation') {
    return {
      ...DEFAULTS.Accommodation,
      ...item,
      link: item.externalUrl || item.website || '',
    };
  }
  if (category === 'Jobs') {
    const status = normalizeStatus(item.status, 'Pending');

    return {
      ...DEFAULTS.Jobs,
      title: item.title || item.jobTitle || '',
      location: item.location || item.city || '',
      country: item.country || 'Germany',
      domain: item.domain || '',
      contact: item.contact || item.contactPhone || item.phone || '',
      description: item.description || '',
      salary: item.salary || '',
      status,
      companyName: item.companyName || item.company || '',
      companyLogo: item.companyLogo || '',
      type: item.jobType || item.type || 'Full Time',
      requirements: Array.isArray(item.requirements) ? item.requirements.join(', ') : (item.requirements || ''),
      benefits: Array.isArray(item.benefits) ? item.benefits.join(', ') : (item.benefits || ''),
      applyUrl: item.applyUrl || '',
    };
  }
  if (category === 'Second Hand Store') {
    return {
      ...DEFAULTS['Second Hand Store'],
      title: item.title || '',
      description: item.description || '',
      price: item.price || '',
      contactPhone: item.contactPhone || '',
      contactEmail: item.contactEmail || '',
      deliveryOption: item.deliveryOption || '',
      link: item.externalUrl || item.website || '',
      images: item.images || [],
      status: normalizeStatus(item.status, 'Pending'),
    };
  }
  if (category === 'Events') {
    return {
      ...DEFAULTS.Events,
      title: item.title || '',
      category: item.category || 'festivals',
      format: item.format || 'one_day',
      city: item.city || '',
      venue: item.venue || '',
      address: item.address || '',
      isOnline: !!item.isOnline,
      onlineLink: item.onlineLink || '',
      organizer: item.organizer || '',
      contact: item.contact || item.contactPhone || '',
      timeText: item.timeText || '',
      startsAt: item.startsAt ? String(item.startsAt).slice(0, 16) : '',
      endsAt: item.endsAt ? String(item.endsAt).slice(0, 16) : '',
      price: item.price || '',
      priceType: item.priceType || 'paid',
      priceText: item.priceText || item.price || '',
      ticketUrl: item.ticketUrl || item.externalUrl || '',
      shortDescription: item.shortDescription || '',
      description: item.description || '',
      images: item.images || [],
      languages: Array.isArray(item.languages) ? item.languages : [],
      familyFriendly: !!item.familyFriendly,
      daysOfWeek: Array.isArray(item.daysOfWeek) ? item.daysOfWeek : [],
      ongoing: !!item.ongoing,
      level: item.level || 'all',
      ageGroup: item.ageGroup || 'all',
      sessions: Array.isArray(item.sessions) ? item.sessions : [],
      subtitles: item.subtitles || 'none',
      status: normalizeStatus(item.status, 'Active'),
    };
  }

  return DEFAULTS[category];
};

const AddListingModal = ({ onClose, onSuccess, defaultCategory, lockCategory, editItem = null }) => {
  const initialCategory = defaultCategory || 'Accommodation';
  const [category, setCategory] = useState(initialCategory);
  const [formData, setFormData] = useState(editItem ? mapItemToFormData(initialCategory, editItem) : DEFAULTS[initialCategory]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    const cat = defaultCategory || 'Accommodation';
    setCategory(cat);
    setFormData(editItem ? mapItemToFormData(cat, editItem) : DEFAULTS[cat]);
  }, [defaultCategory, editItem]);

  const handleCategoryChange = (cat) => {
    setCategory(cat);
    setFormData(editItem ? mapItemToFormData(cat, editItem) : DEFAULTS[cat]);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const err = validate(category, formData);
    if (err) { alert(err); return; }
    setIsSubmitting(true);
    try {
      const token = localStorage.getItem('adminToken');

      const payload = buildPayload(category, formData);
      if (category === 'Jobs' || category === 'Second Hand Store') {
        payload.status = editItem
          ? normalizeStatus(payload.status || formData.status, 'Pending')
          : 'Pending';
      }

      const method = editItem ? 'PUT' : 'POST';
      const primaryUrl = editItem ? `${API_MAP[category]}/${editItem._id}` : API_MAP[category];
      const fallbackUrl = editItem ? `${LOCAL_JOBS_API}/${editItem._id}` : LOCAL_JOBS_API;

      const sendRequest = async (url, requestPayload) => {
        try {
          const response = await fetch(url, {
            method,
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify(requestPayload),
          });

          const raw = await response.text();
          let body = null;
          try {
            body = raw ? JSON.parse(raw) : null;
          } catch (_) {
            body = raw ? { message: raw } : null;
          }

          return {
            ok: response.ok,
            status: response.status,
            message: (body?.message || '').toString(),
          };
        } catch (error) {
          return {
            ok: false,
            status: 0,
            message: error?.message || 'Network error',
          };
        }
      };

      let result = await sendRequest(primaryUrl, payload);
      let bestErrorMessage = result.message;

      if (!result.ok && category === 'Jobs') {
        const isPendingEnumError =
          result.message.includes('status') &&
          result.message.includes('pending') &&
          result.message.includes('valid enum value');

        if (isPendingEnumError) {
          // Retry 1: explicit canonical Pending
          result = await sendRequest(primaryUrl, { ...payload, status: 'Pending' });
          if (result.message) bestErrorMessage = result.message;

          // Retry 2: omit status and let backend default apply
          if (!result.ok) {
            const { status, ...withoutStatus } = payload;
            result = await sendRequest(primaryUrl, withoutStatus);
            if (result.message) bestErrorMessage = result.message;
          }

          // Retry 3: local fallback backend (if remote still rejects)
          if (!result.ok) {
            const { status, ...withoutStatus } = payload;
            const fallbackResult = await sendRequest(fallbackUrl, withoutStatus);
            if (fallbackResult.ok) {
              result = fallbackResult;
            } else if (
              fallbackResult.message &&
              !fallbackResult.message.toLowerCase().includes('failed to fetch') &&
              !fallbackResult.message.toLowerCase().includes('network error')
            ) {
              result = fallbackResult;
              bestErrorMessage = fallbackResult.message;
            }
          }
        }
      }

      if (result.ok) {
        alert(editItem ? `${category} listing updated successfully.` : `${category} listing submitted for review (Pending).`);
        onSuccess && onSuccess(category);
        onClose();
      } else {
        alert('Error: ' + (bestErrorMessage || result.message || 'Request failed'));
      }
    } catch (ex) {
      alert('Error connecting to server: ' + ex.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content modal-large" style={{ minHeight: 520, maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <h2>
            {editItem
              ? `Edit ${category} Listing`
              : (lockCategory && defaultCategory === 'Jobs' ? 'Add New Job' : 'Add New Listing')}
          </h2>
          <button className="close-btn" onClick={onClose}><X size={24} /></button>
        </div>

        {/* Category selector - only show if not locked */}
        {!lockCategory && (
          <div style={{ display: 'flex', gap: 8, marginBottom: 20, flexWrap: 'wrap' }}>
            {CATEGORY_LABELS.map(c => (
              <button key={c} type="button" onClick={() => handleCategoryChange(c)}
                style={{ padding: '6px 16px', borderRadius: 20, border: '2px solid #6b9976', background: category === c ? '#6b9976' : '#fff', color: category === c ? '#fff' : '#374151', fontWeight: 600, cursor: 'pointer', fontSize: 13 }}>
                {c === 'Accommodation' ? '🏠' : c === 'Jobs' ? '💼' : c === 'Second Hand Store' ? '🛍️' : c === 'Events' ? '🎉' : '🔧'} {c}
              </button>
            ))}
          </div>
        )}

        <form onSubmit={handleSubmit} className="add-listing-form" key={category}>
          {category === 'Accommodation' && <AccommodationForm key="accommodation" data={formData} set={setFormData} />}
          {category === 'Jobs' && <JobsForm key="jobs" data={formData} set={setFormData} />}
          {category === 'Services' && <ServicesForm key="services" data={formData} set={setFormData} />}
          {category === 'Second Hand Store' && <SecondHandStoreForm key="secondhand" data={formData} set={setFormData} />}
          {category === 'Events' && <EventsForm key="events" data={formData} set={setFormData} />}

          {/* Status */}
          <div className="form-group" style={{ marginTop: 8 }}>
            <label>Status</label>
            {editItem ? (
              category === 'Jobs' || category === 'Second Hand Store' || category === 'Events' ? (
                <select value={normalizeStatus(formData.status, 'Pending')} onChange={e => setFormData(p => ({ ...p, status: e.target.value }))}>
                  <option value="Active">Active</option>
                  <option value="Pending">Pending</option>
                  <option value="Inactive">Inactive</option>
                </select>
              ) : (
                <select value={formData.status || 'pending'} onChange={e => setFormData(p => ({ ...p, status: e.target.value }))}>
                  <option value="active">Active</option>
                  <option value="pending">Pending</option>
                  <option value="disabled">Inactive</option>
                </select>
              )
            ) : (
              <>
                {category === 'Jobs' || category === 'Second Hand Store' || category === 'Events' ? (
                  <select value={'Pending'} disabled>
                    <option value="Pending">Pending</option>
                  </select>
                ) : (
                  <select value={'pending'} disabled>
                    <option value="pending">Pending</option>
                  </select>
                )}
                <div style={{ fontSize: 12, color: '#6b7280', marginTop: 6 }}>
                  New listings are reviewed in Content Moderation before going live.
                </div>
              </>
            )}
          </div>

          <div className="form-actions">
            <button type="button" className="cancel-btn" onClick={onClose} disabled={isSubmitting}>Cancel</button>
            <button type="submit" className="create-btn" disabled={isSubmitting}>
              {isSubmitting ? (editItem ? 'Saving…' : 'Creating…') : (editItem ? 'Save Changes' : 'Create Listing')}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AddListingModal;

