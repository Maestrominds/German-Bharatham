import React, { useEffect, useState } from 'react';
import { X } from 'lucide-react';
import API_URL from '../config';

const REQ = <span style={{ color: 'red' }}>*</span>;

// ── helpers ──────────────────────────────────────────────────────────────────

const ImageUpload = ({ images, onChange }) => (
  <div className="form-group">
    <label>Photos <span style={{ color: 'red' }}>*</span> <span style={{ color: '#6b7280', fontSize: 12 }}>(JPG, JPEG, PNG — at least 1 required)</span></label>
    <input type="file" accept=".jpg,.jpeg,.png,image/jpeg,image/png" multiple onChange={e => {
      const valid = Array.from(e.target.files).filter(f => /\.(jpg|jpeg|png)$/i.test(f.name));
      if (valid.length !== e.target.files.length) alert('Only JPG, JPEG, and PNG files are allowed.');
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
            <input value={data.postalCode} onChange={e => set(p => ({...p, postalCode: e.target.value}))} placeholder="80331" />
          </div>
        </div>
        <div className="form-row">
          <div className="form-group">
            <label>Area</label>
            <input value={data.area} onChange={e => set(p => ({...p, area: e.target.value}))} placeholder="Schwabing" />
          </div>
          <div className="form-group">
            <label>Address</label>
            <input value={data.address} onChange={e => set(p => ({...p, address: e.target.value}))} placeholder="Leopoldstraße 1" />
          </div>
        </div>
      </div>

      {/* Contact & Description */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>📞 Contact & Description</h4>
        <div className="form-group">
          <label>Contact Phone {REQ}</label>
          <input value={data.contactPhone} onChange={e => set(p => ({...p, contactPhone: e.target.value}))} placeholder="+49 170 1234567" />
        </div>
        <div className="form-group">
          <label>Description {REQ}</label>
          <textarea value={data.description} onChange={e => set(p => ({...p, description: e.target.value}))} rows={3} placeholder="Detailed description…" />
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
        <ChipsInput label="Amenities (select or type)" options={amenityOpts}
          selected={data.amenities}
          onToggle={a => set(p => ({ ...p, amenities: p.amenities.includes(a) ? p.amenities.filter(x => x !== a) : [...p.amenities, a] }))}
          onTypeAdd={a => set(p => ({ ...p, amenities: p.amenities.includes(a) ? p.amenities : [...p.amenities, a] }))}
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

const FoodForm = ({ data, set }) => {
  const [cuisineInput, setCuisineInput] = React.useState('');
  const [specialtyInput, setSpecialtyInput] = React.useState('');
  
  const handleAddCuisine = (e) => {
    e.preventDefault();
    if (cuisineInput.trim() && !data.cuisine.includes(cuisineInput.trim())) {
      set(p => ({ ...p, cuisine: [...p.cuisine, cuisineInput.trim()] }));
      setCuisineInput('');
    }
  };

  const handleRemoveCuisine = (cuisine) => {
    set(p => ({ ...p, cuisine: p.cuisine.filter(c => c !== cuisine) }));
  };

  const handleAddSpecialty = (e) => {
    e.preventDefault();
    if (specialtyInput.trim() && !data.specialties.includes(specialtyInput.trim())) {
      set(p => ({ ...p, specialties: [...p.specialties, specialtyInput.trim()] }));
      setSpecialtyInput('');
    }
  };

  const handleRemoveSpecialty = (specialty) => {
    set(p => ({ ...p, specialties: p.specialties.filter(s => s !== specialty) }));
  };

  return (
    <>
      {/* Basic Information */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Basic Information</h4>
        <div className="form-row">
          <div className="form-group">
            <label>Name {REQ}</label>
            <input value={data.title} onChange={e => set(p => ({...p, title: e.target.value}))} placeholder="Restaurant or Grocery Store name" />
          </div>
          <div className="form-group">
            <label>Category {REQ}</label>
            <select value={data.subCategory} onChange={e => set(p => ({...p, subCategory: e.target.value}))}>
              <option value="Restaurant">Restaurant</option>
              <option value="Grocery Store">Grocery Store</option>
              <option value="Bakery">Bakery</option>
              <option value="Cafe">Cafe</option>
              <option value="Supermarket">Supermarket</option>
              <option value="Food Truck">Food Truck</option>
              <option value="Deli">Deli</option>
            </select>
          </div>
        </div>
        <div className="form-row">
          <div className="form-group">
            <label>Type</label>
            <input value={data.type} onChange={e => set(p => ({...p, type: e.target.value}))} placeholder="e.g., Indian, Italian, Organic, Veg/Non-Veg" />
          </div>
          <div className="form-group">
            <label>Price Range</label>
            <select value={data.priceRange} onChange={e => set(p => ({...p, priceRange: e.target.value}))}>
              <option value="$">$ - Budget Friendly</option>
              <option value="$$">$$ - Moderate</option>
              <option value="$$$">$$$ - Expensive</option>
              <option value="$$$$">$$$$ - Very Expensive</option>
            </select>
          </div>
        </div>
      </div>

      {/* Location Details */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>📍 Location Details</h4>
        <div className="form-group">
          <label>Address {REQ}</label>
          <input value={data.address} onChange={e => set(p => ({...p, address: e.target.value}))} placeholder="Street address" />
        </div>
        <div className="form-row">
          <div className="form-group">
            <label>City {REQ}</label>
            <input value={data.city} onChange={e => set(p => ({...p, city: e.target.value}))} placeholder="Munich" />
          </div>
          <div className="form-group">
            <label>State/Region</label>
            <input value={data.state} onChange={e => set(p => ({...p, state: e.target.value}))} placeholder="Bavaria" />
          </div>
          <div className="form-group">
            <label>Zip Code</label>
            <input value={data.zipCode} onChange={e => set(p => ({...p, zipCode: e.target.value}))} placeholder="80331" />
          </div>
        </div>
      </div>

      {/* Contact Information */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>📞 Contact Information</h4>
        <div className="form-row">
          <div className="form-group">
            <label>Phone</label>
            <input value={data.phone} onChange={e => set(p => ({...p, phone: e.target.value}))} placeholder="+49 123 456 7890" />
          </div>
          <div className="form-group">
            <label>Email</label>
            <input type="email" value={data.email} onChange={e => set(p => ({...p, email: e.target.value}))} placeholder="contact@restaurant.com" />
          </div>
        </div>
        <div className="form-group">
          <label>Website</label>
          <input value={data.website} onChange={e => set(p => ({...p, website: e.target.value}))} placeholder="https://www.restaurant.com" />
        </div>
      </div>

      {/* Details */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Details</h4>
        <div className="form-group">
          <label>Description</label>
          <textarea value={data.description} onChange={e => set(p => ({...p, description: e.target.value}))} rows={4} placeholder="Enter a detailed description..." />
        </div>
        <div className="form-group">
          <label>🕐 Opening Hours</label>
          <input value={data.openingHours} onChange={e => set(p => ({...p, openingHours: e.target.value}))} placeholder="e.g., Mon-Fri: 9:00 AM - 10:00 PM, Sat-Sun: 10:00 AM - 11:00 PM" />
        </div>
      </div>

      {/* Cuisine & Specialties */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Cuisine & Specialties</h4>
        <div className="form-group">
          <label>Cuisine Types</label>
          <div style={{ display: 'flex', gap: 6 }}>
            <input 
              value={cuisineInput} 
              onChange={e => setCuisineInput(e.target.value)}
              onKeyPress={e => e.key === 'Enter' && handleAddCuisine(e)}
              placeholder="Add cuisine type (e.g., Indian, Italian)" 
              style={{ flex: 1 }}
            />
            <button type="button" onClick={handleAddCuisine} style={{ padding: '8px 20px', background: '#6b9976', color: '#fff', border: 'none', borderRadius: 6, cursor: 'pointer', fontWeight: 600 }}>Add</button>
          </div>
          {data.cuisine.length > 0 && (
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 8 }}>
              {data.cuisine.map((c, i) => (
                <span key={i} style={{ padding: '4px 10px', background: '#e5e7eb', borderRadius: 16, fontSize: 13, display: 'flex', alignItems: 'center', gap: 4 }}>
                  {c}
                  <button type="button" onClick={() => handleRemoveCuisine(c)} style={{ background: 'none', border: 'none', fontSize: 16, cursor: 'pointer', padding: 0, lineHeight: 1 }}>×</button>
                </span>
              ))}
            </div>
          )}
        </div>
        <div className="form-group">
          <label>Specialties</label>
          <div style={{ display: 'flex', gap: 6 }}>
            <input 
              value={specialtyInput} 
              onChange={e => setSpecialtyInput(e.target.value)}
              onKeyPress={e => e.key === 'Enter' && handleAddSpecialty(e)}
              placeholder="Add specialty item" 
              style={{ flex: 1 }}
            />
            <button type="button" onClick={handleAddSpecialty} style={{ padding: '8px 20px', background: '#6b9976', color: '#fff', border: 'none', borderRadius: 6, cursor: 'pointer', fontWeight: 600 }}>Add</button>
          </div>
          {data.specialties.length > 0 && (
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 8 }}>
              {data.specialties.map((s, i) => (
                <span key={i} style={{ padding: '4px 10px', background: '#e5e7eb', borderRadius: 16, fontSize: 13, display: 'flex', alignItems: 'center', gap: 4 }}>
                  {s}
                  <button type="button" onClick={() => handleRemoveSpecialty(s)} style={{ background: 'none', border: 'none', fontSize: 16, cursor: 'pointer', padding: 0, lineHeight: 1 }}>×</button>
                </span>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Services Available */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Services Available</h4>
        <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
          <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 14 }}>
            <input type="checkbox" checked={data.dineInAvailable} onChange={e => set(p => ({...p, dineInAvailable: e.target.checked}))} />
            <span>Dine-in</span>
          </label>
          <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 14 }}>
            <input type="checkbox" checked={data.deliveryAvailable} onChange={e => set(p => ({...p, deliveryAvailable: e.target.checked}))} />
            <span>Home Delivery</span>
          </label>
          <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 14 }}>
            <input type="checkbox" checked={data.takeoutAvailable} onChange={e => set(p => ({...p, takeoutAvailable: e.target.checked}))} />
            <span>Takeout</span>
          </label>
          <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 14 }}>
            <input type="checkbox" checked={data.cateringAvailable} onChange={e => set(p => ({...p, cateringAvailable: e.target.checked}))} />
            <span>Catering</span>
          </label>
        </div>
      </div>

      {/* Image */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>📤 Image</h4>
        <div className="form-group">
          <label>Image URL</label>
          <input value={data.image || ''} onChange={e => set(p => ({...p, image: e.target.value}))} placeholder="https://example.com/image.jpg" />
          <p style={{ fontSize: 12, color: '#6b7280', marginTop: 4 }}>Enter the URL of the restaurant/store image</p>
          {data.image && (
            <div style={{ marginTop: 8 }}>
              <img src={data.image} alt="Preview" style={{ maxWidth: 200, maxHeight: 150, objectFit: 'cover', borderRadius: 8 }} />
            </div>
          )}
        </div>
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
            <label>Contact</label>
            <input value={data.contact} onChange={e => set(p => ({...p, contact: e.target.value}))} placeholder="+49 52148 765397" />
          </div>
        </div>
      </div>

      {/* Description */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>Description</h4>
        <div className="form-group">
          <label>Description</label>
          <textarea value={data.description} onChange={e => set(p => ({...p, description: e.target.value}))} rows={3} placeholder="Enter Description" />
        </div>
      </div>

      {/* Job Details */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>💼 Job Details</h4>
        <div className="form-row">
          <div className="form-group">
            <label>Salary</label>
            <input value={data.salary} onChange={e => set(p => ({...p, salary: e.target.value}))} placeholder="€3,000/month" />
          </div>
        </div>
        <div className="form-row">
          <div className="form-group">
            <label>Company Name</label>
            <input value={data.companyName} onChange={e => set(p => ({...p, companyName: e.target.value}))} placeholder="Company Name" />
          </div>
          <div className="form-group">
            <label>Company Logo</label>
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
          <label>Requirements</label>
          <textarea value={data.requirements} onChange={e => set(p => ({...p, requirements: e.target.value}))} rows={3} placeholder="Enter required skills and qualifications (comma-separated)" />
        </div>
        <div className="form-group">
          <label>Benefits</label>
          <textarea value={data.benefits} onChange={e => set(p => ({...p, benefits: e.target.value}))} rows={3} placeholder="Enter job benefits (comma-separated)" />
        </div>
      </div>

      {/* Application */}
      <div style={{ marginBottom: 20 }}>
        <h4 style={{ fontSize: 16, fontWeight: 700, color: '#2d5a3d', marginBottom: 12 }}>📝 Application</h4>
        <div className="form-group">
          <label>Apply URL</label>
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
          <label>Area</label>
          <input value={data.area} onChange={e => set(p => ({...p, area: e.target.value}))} placeholder="Maxvorstadt" />
        </div>
        <div className="form-group">
          <label>Address</label>
          <input value={data.address} onChange={e => set(p => ({...p, address: e.target.value}))} placeholder="Street, No." />
        </div>
      </div>
      <div className="form-row">
        <div className="form-group">
          <label>Contact Phone {REQ}</label>
          <input value={data.contactPhone} onChange={e => set(p => ({...p, contactPhone: e.target.value}))} placeholder="+49 170 1234567" />
        </div>
        <div className="form-group">
          <label>Price Range</label>
          <input value={data.priceRange} onChange={e => set(p => ({...p, priceRange: e.target.value}))} placeholder="€50/hour" />
        </div>
      </div>

      <div className="form-row">
        <div className="form-group">
          <label>WhatsApp</label>
          <input value={data.whatsapp} onChange={e => set(p => ({...p, whatsapp: e.target.value}))} placeholder="+49 170 1234567" />
        </div>
        <div className="form-group">
          <label>Email</label>
          <input value={data.email} onChange={e => set(p => ({...p, email: e.target.value}))} placeholder="name@example.com" />
        </div>
      </div>

      <div className="form-row">
        <div className="form-group">
          <label>Website</label>
          <input value={data.website} onChange={e => set(p => ({...p, website: e.target.value}))} placeholder="https://example.com" />
        </div>
        <div className="form-group">
          <label>Latitude</label>
          <input value={data.latitude} onChange={e => set(p => ({...p, latitude: e.target.value}))} placeholder="48.137154" />
        </div>
      </div>

      <div className="form-row">
        <div className="form-group">
          <label>Longitude</label>
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

// ── Main modal ────────────────────────────────────────────────────────────────

const DEFAULTS = {
  Accommodation: { title:'', propertyType:'apartment', city:'', area:'', postalCode:'', address:'', contactPhone:'', description:'', coldRent:'', warmRent:'', deposit:'', sizeSqm:'', bedrooms:'', bathrooms:'', amenities:[], images:[], status:'pending' },
  Food: { title:'', subCategory:'Restaurant', type:'', city:'', state:'', zipCode:'', address:'', phone:'', email:'', website:'', description:'', priceRange:'$$', openingHours:'', cuisine:[], specialties:[], deliveryAvailable:false, takeoutAvailable:false, dineInAvailable:false, cateringAvailable:false, image:'', status:'pending', featured:false, verified:true },
  Jobs: { title:'', location:'', contact:'', description:'', salary:'', status:'Pending', companyName:'', companyLogo:'', type:'Full Time', requirements:'', benefits:'', applyUrl:'' },
  Services: { serviceName:'', providerName:'', serviceType:'', city:'', area:'', postalCode:'', address:'', contactPhone:'', whatsapp:'', email:'', website:'', latitude:'', longitude:'', description:'', priceRange:'', amenitiesText:'', images:[], status:'pending' },
};

const CATEGORY_LABELS = ['Accommodation', 'Food', 'Jobs', 'Services'];
const normalizeStatus = (value, fallback = 'Pending') => {
  const raw = String(value || '').trim().toLowerCase();
  if (raw === 'active') return 'Active';
  if (raw === 'pending') return 'Pending';
  if (raw === 'inactive' || raw === 'disabled') return 'Inactive';
  return fallback;
};

const validate = (category, data) => {
  if (category === 'Accommodation') {
    if (!data.title?.trim()) return 'Title is required';
    if (!data.contactPhone?.trim()) return 'Contact Phone is required';
    if (!data.city?.trim()) return 'City is required';
    if (!data.postalCode?.trim()) return 'Postal Code is required';
    if (!data.description?.trim()) return 'Description is required';
    if (!data.coldRent) return 'Cold Rent is required';
    if (!data.warmRent) return 'Warm Rent is required';
    if (!data.deposit) return 'Deposit is required';
    if (!data.sizeSqm) return 'Size (sqm) is required';
    if (!data.bedrooms) return 'Bedrooms is required';
    if (!data.bathrooms) return 'Bathrooms is required';
    if (!data.images || data.images.length === 0) return 'At least one photo (JPG/JPEG/PNG) is required';
  }
  if (category === 'Food') {
    if (!data.title?.trim()) return 'Title is required';
    if (!data.subCategory?.trim()) return 'Sub Category is required';
    if (!data.city?.trim()) return 'City is required';
    if (!data.zipCode?.trim()) return 'Zip Code is required';
    if (!data.address?.trim()) return 'Address is required';
    if (!data.phone?.trim()) return 'Phone is required';
  }
  if (category === 'Jobs') {
    if (!data.title?.trim()) return 'Title is required';
    if (!data.location?.trim()) return 'Location is required';
    if (!data.companyName?.trim()) return 'Company Name is required';
    if (!data.type?.trim()) return 'Type is required';
    if (!data.status?.trim()) return 'Status is required';
  }
  if (category === 'Services') {
    if (!data.serviceName?.trim()) return 'Service Name is required';
    if (!data.providerName?.trim()) return 'Provider Name is required';
    if (!data.city?.trim()) return 'City is required';
    if (!data.postalCode?.trim()) return 'Postal Code is required';
    if (!data.contactPhone?.trim()) return 'Contact Phone is required';
    if (!data.description?.trim()) return 'Description is required';
    const amenities = (data.amenitiesText ?? '')
      .toString()
      .split(/[,;\n]/)
      .map(s => s.trim())
      .filter(Boolean);
    if (amenities.length === 0) return 'Services Offered is required';
  }
  return null;
};

const buildPayload = (category, data) => {
  if (category === 'Accommodation') {
    return {
      title: data.title?.trim(),
      propertyType: data.propertyType,
      city: data.city?.trim(),
      area: data.area?.trim() || null,
      postalCode: data.postalCode?.trim(),
      address: data.address?.trim() || null,
      contactPhone: data.contactPhone?.trim(),
      description: data.description?.trim() || null,
      status: data.status,
      rentDetails: { coldRent: +data.coldRent, warmRent: +data.warmRent, deposit: +data.deposit },
      propertyDetails: { sizeSqm: +data.sizeSqm, bedrooms: +data.bedrooms, bathrooms: +data.bathrooms },
      amenities: data.amenities.reduce((a, k) => {
        const key = k.replace(/ ([A-Z])/g, (_, c) => c.toLowerCase()).replace(/^./, c => c.toLowerCase()).replace(/ /g, '');
        a[key] = true; return a;
      }, {}),
      media: { images: data.images || [] },
      adminControls: { isActive: data.status === 'active' },
    };
  }
  if (category === 'Food') {
    return {
      title: data.title?.trim(),
      subCategory: data.subCategory?.trim(),
      type: data.type?.trim() || null,
      location: `${data.city?.trim()}, ${data.address?.trim()}`,
      address: data.address?.trim(),
      city: data.city?.trim(),
      state: data.state?.trim() || null,
      zipCode: data.zipCode?.trim(),
      phone: data.phone?.trim(),
      email: data.email?.trim() || null,
      website: data.website?.trim() || null,
      description: data.description?.trim() || null,
      priceRange: data.priceRange,
      openingHours: data.openingHours?.trim() || null,
      cuisine: data.cuisine || [],
      specialties: data.specialties || [],
      deliveryAvailable: data.deliveryAvailable,
      takeoutAvailable: data.takeoutAvailable,
      dineInAvailable: data.dineInAvailable,
      cateringAvailable: data.cateringAvailable,
      image: data.image?.trim() || '',
      status: data.status === 'active' ? 'Active' : data.status === 'pending' ? 'Pending' : 'Inactive',
      featured: data.featured,
      verified: data.verified,
      category: 'Food'
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
};

const API_MAP = {
  Accommodation: `${API_URL}/api/accommodation/admin`,
  Food: `${API_URL}/api/admin/foodgrocery`,
  Jobs: `${API_URL}/api/jobs/admin`,
  Services: `${API_URL}/api/services/admin`,
};

const LOCAL_JOBS_API = 'http://127.0.0.1:5000/api/jobs/admin';

const mapItemToFormData = (category, item) => {
  if (!item) return DEFAULTS[category];

  if (category === 'Jobs') {
    const status = normalizeStatus(item.status, 'Pending');

    return {
      ...DEFAULTS.Jobs,
      title: item.title || item.jobTitle || '',
      location: item.location || item.city || '',
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
      if (category === 'Jobs') {
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
                {c === 'Accommodation' ? '🏠' : c === 'Food' ? '🍴' : c === 'Jobs' ? '💼' : '🔧'} {c}
              </button>
            ))}
          </div>
        )}

        <form onSubmit={handleSubmit} className="add-listing-form" key={category}>
          {category === 'Accommodation' && <AccommodationForm key="accommodation" data={formData} set={setFormData} />}
          {category === 'Food' && <FoodForm key="food" data={formData} set={setFormData} />}
          {category === 'Jobs' && <JobsForm key="jobs" data={formData} set={setFormData} />}
          {category === 'Services' && <ServicesForm key="services" data={formData} set={setFormData} />}

          {/* Status */}
          <div className="form-group" style={{ marginTop: 8 }}>
            <label>Status</label>
            {editItem ? (
              category === 'Jobs' ? (
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
                {category === 'Jobs' ? (
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

