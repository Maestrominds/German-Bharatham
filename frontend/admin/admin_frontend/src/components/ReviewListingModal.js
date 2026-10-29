import React, { useState, useEffect } from 'react';
import { X, Upload, Trash2 } from 'lucide-react';
import API_URL from '../config';

const DEFAULT_DOMAINS = [
  'IT / Technology',
  'Computer Science / Software',
  'Biotechnology / Life Sciences',
  'Healthcare / Medicine',
  'Finance / Banking',
  'Mechanical / Automotive',
  'Electrical / Electronics',
  'Engineering / Manufacturing',
  'Marketing / Sales',
  'Business / Management',
  'Legal / Law',
  'Education / Academia',
  'Other',
];

const COUNTRY_OPTIONS = [
  'Germany',
  'India',
  'Europe',
  'United Kingdom',
  'United States',
  'Other / Remote',
];

const ACCOMMODATION_AMENITIES = [
  { key: 'balcony', label: 'Balcony' },
  { key: 'terrace', label: 'Terrace' },
  { key: 'garden', label: 'Garden' },
  { key: 'lift', label: 'Lift' },
  { key: 'parking', label: 'Parking' },
  { key: 'garage', label: 'Garage' },
  { key: 'cellar', label: 'Cellar' },
  { key: 'washingMachine', label: 'Washing Machine' },
  { key: 'dishwasher', label: 'Dishwasher' },
  { key: 'kitchen', label: 'Kitchen' },
  { key: 'petsAllowed', label: 'Pets Allowed' },
  { key: 'smokingAllowed', label: 'Smoking Allowed' },
  { key: 'anmeldungPossible', label: 'Anmeldung Possible' },
  { key: 'studentFriendly', label: 'Student Friendly' },
  { key: 'wheelchairAccessible', label: 'Wheelchair Accessible' }
];

const ReviewListingModal = ({ listing, onClose, onApprove, onReject, onSavePending, saving }) => {
  // 'images' holds either string URLs (existing) or File objects (newly picked)
  const [images, setImages] = useState(
    Array.isArray(listing.images) && listing.images.length > 0
      ? listing.images
      : (listing.image ? [listing.image] : [])
  );
  // Track object URLs created for new File objects so we can display them
  const [previewUrls, setPreviewUrls] = useState([]);
  const [availableDomains, setAvailableDomains] = useState(DEFAULT_DOMAINS);

  useEffect(() => {
    fetch(`${API_URL}/api/profile-options`)
      .then(res => res.json())
      .then(d => {
        if (d && Array.isArray(d.domains)) {
          const names = d.domains.map(item => (typeof item === 'object' ? item.name : item)).filter(Boolean);
          if (names.length > 0) {
            setAvailableDomains(Array.from(new Set([...DEFAULT_DOMAINS, ...names])));
          }
        }
      })
      .catch(() => {});
  }, []);

  const [formData, setFormData] = useState(() => {
    const raw = listing.raw || {};
    return {
      ...raw,
      title: raw.title || raw.serviceName || raw.name || '',
      description: raw.description || '',
      contactPhone: raw.contactPhone || raw.contact || raw.phone || raw.email || '',
      city: raw.city || raw.location || raw.address || '',
      area: raw.state ? String(raw.state) : (typeof raw.area === 'string' ? raw.area : ''),

      // Accommodation details
      propertyType: raw.propertyType || raw.type || 'Apartment',
      postalCode: (raw.zipCode !== undefined && raw.zipCode !== null) ? String(raw.zipCode) : (raw.postalCode ? String(raw.postalCode) : ''),
      address: raw.address || '',
      rentDetails: {
        coldRent: raw.rentDetails?.coldRent ?? '',
        warmRent: raw.rentDetails?.warmRent ?? '',
        deposit: raw.rentDetails?.deposit ?? '',
        electricityIncluded: !!raw.rentDetails?.electricityIncluded,
        heatingIncluded: !!raw.rentDetails?.heatingIncluded,
        internetIncluded: !!raw.rentDetails?.internetIncluded,
      },
      propertyDetails: {
        sizeSqm: raw.propertyDetails?.sizeSqm ?? '',
        bedrooms: raw.propertyDetails?.bedrooms ?? '',
        bathrooms: raw.propertyDetails?.bathrooms ?? '',
      },
      amenities: raw.amenities && typeof raw.amenities === 'object' ? raw.amenities : {},



      // Link (Accommodation & Second Hand Store)
      link: raw.link || raw.externalUrl || raw.website || '',

      // Jobs
      country: raw.country || 'Germany',
      domain: raw.domain || raw.industry || '',
      companyName: raw.companyName || raw.company || '',
      contact: raw.contact || raw.phone || '',
      jobType: raw.jobType || raw.type || 'Full Time',
      salary: raw.salary || '',
      applyUrl: raw.applyUrl || '',
      requirements: raw.requirements || '',
      benefits: raw.benefits || '',

      // Services
      serviceType: raw.serviceType || 'Immigration',
      providerName: raw.providerName || '',
      whatsapp: raw.whatsapp || '',
      email: raw.email || '',
      website: raw.website || '',
      priceRange: raw.priceRange || '',
      latitude: raw.latitude || '',
      servicesOfferedText: Array.isArray(raw.amenities) ? raw.amenities.join(', ') : (raw.servicesOffered || ''),

      // Second Hand Store
      price: raw.price || '',
      contactEmail: raw.contactEmail || '',
      deliveryOption: raw.deliveryOption || '',

      // Events
      eventCategory: raw.category || 'festivals',
      eventFormat: raw.format || 'one_day',
      venue: raw.venue || '',
      address: raw.address || '',
      isOnline: !!raw.isOnline,
      onlineLink: raw.onlineLink || '',
      organizer: raw.organizer || '',
      timeText: raw.timeText || '',
      startsAt: raw.startsAt ? String(raw.startsAt).slice(0, 16) : '',
      endsAt: raw.endsAt ? String(raw.endsAt).slice(0, 16) : '',
      ticketUrl: raw.ticketUrl || raw.externalUrl || raw.onlineLink || '',
      shortDescription: raw.shortDescription || '',
      priceType: raw.priceType || 'paid',
      priceText: raw.priceText || raw.price || '',
      familyFriendly: !!raw.familyFriendly,
    };
  });

  const handleFieldChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleNestedFieldChange = (section, field, type, value) => {
    setFormData(prev => ({
      ...prev,
      [section]: {
        ...prev[section],
        [field]: type === 'checkbox' ? value : value
      }
    }));
  };

  const handleImageUpload = (e) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;

    const maxLimit = listing.category === 'Second Hand Store' ? 5 : (listing.category === 'Jobs' ? 1 : 3);
    if (images.length + files.length > maxLimit) {
      alert(`You can upload a maximum of ${maxLimit} image${maxLimit > 1 ? 's' : ''}.`);
      return;
    }

    // Use object URLs for instant preview - no FileReader/base64 needed
    const newPreviews = files.map(f => URL.createObjectURL(f));
    setImages(prev => [...prev, ...files].slice(0, maxLimit));
    setPreviewUrls(prev => [...prev, ...newPreviews].slice(0, maxLimit));
  };

  // Helper to get a displayable URL for any image entry (existing URL or new File)
  const getDisplayUrl = (img, index) => {
    if (typeof img === 'string') return img;
    // It's a File object - find its preview URL
    const newFileIndex = images.filter((v, i) => i < index && v instanceof File).length;
    return previewUrls[newFileIndex] || '';
  };

  const removeImage = (index) => {
    const removed = images[index];
    if (removed instanceof File) {
      // Also remove its preview URL
      const newFileIndex = images.filter((v, i) => i < index && v instanceof File).length;
      setPreviewUrls(prev => prev.filter((_, i) => i !== newFileIndex));
    }
    setImages(images.filter((_, i) => i !== index));
  };

  // Upload any new File objects to Cloudinary via backend endpoint, returns final URL array
  const resolveImageUrls = async (token) => {
    const resolved = [];
    for (const img of images) {
      if (typeof img === 'string') {
        resolved.push(img); // already a URL
      } else {
        // Upload the File to Cloudinary
        const fd = new FormData();
        fd.append('image', img);
        const res = await fetch(`${require('../config').default}/api/admin/upload-image`, {
          method: 'POST',
          headers: { Authorization: `Bearer ${token}` },
          body: fd,
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.message || 'Image upload failed');
        resolved.push(data.url);
      }
    }
    return resolved;
  };

  const prepareSubmitPayload = (status, resolvedImages = []) => {
    const common = {
      title: formData.title?.trim() || '',
      city: formData.city?.trim() || '',
      description: formData.description?.trim() || '',
      images: resolvedImages,
      status
    };

    if (listing.category === 'Accommodation') {
      return {
        ...common,
        contactPhone: formData.contactPhone?.trim() || '',
        phone: formData.contactPhone?.trim() || '',
        address: formData.address?.trim() || null,
        area: formData.propertyDetails.sizeSqm !== '' ? parseFloat(formData.propertyDetails.sizeSqm) : null,
        state: formData.area?.trim() || null,
        postalCode: formData.postalCode?.trim() || null,
        zipCode: formData.postalCode?.trim() || null,
        type: formData.propertyType || null,
        website: formData.link?.trim() || null,
        externalUrl: formData.link?.trim() || null,
        rentDetails: {
          coldRent: formData.rentDetails.coldRent !== '' ? parseFloat(formData.rentDetails.coldRent) : null,
          warmRent: formData.rentDetails.warmRent !== '' ? parseFloat(formData.rentDetails.warmRent) : null,
          deposit: formData.rentDetails.deposit !== '' ? parseFloat(formData.rentDetails.deposit) : null,
        },
        propertyDetails: {
          sizeSqm: formData.propertyDetails.sizeSqm !== '' ? parseFloat(formData.propertyDetails.sizeSqm) : null,
          bedrooms: formData.propertyDetails.bedrooms !== '' ? parseInt(formData.propertyDetails.bedrooms, 10) : null,
          bathrooms: formData.propertyDetails.bathrooms !== '' ? parseInt(formData.propertyDetails.bathrooms, 10) : null,
        },
        amenities: formData.amenities && typeof formData.amenities === 'object' ? formData.amenities : {},
        media: {
          images: resolvedImages
        },
      };
    }

    if (listing.category === 'Jobs') {
      return {
        ...common,
        location: formData.city?.trim() || '',
        country: formData.country?.trim() || 'Germany',
        domain: formData.domain?.trim() || null,
        contact: formData.contactPhone?.trim() || null,
        companyName: formData.companyName?.trim() || null,
        companyLogo: resolvedImages.length > 0 ? resolvedImages[0] : null,
        jobType: formData.jobType || 'Full Time',
        salary: formData.salary?.trim() || null,
        applyUrl: formData.applyUrl?.trim() || null,
        requirements: formData.requirements?.trim() || null,
        benefits: formData.benefits?.trim() || null,
      };
    }

    if (listing.category === 'Services') {
      return {
        ...common,
        serviceName: formData.title?.trim() || '',
        providerName: formData.providerName?.trim() || null,
        serviceType: formData.serviceType || null,
        area: formData.area?.trim() || null,
        address: formData.address?.trim() || null,
        postalCode: formData.postalCode?.trim() || null,
        contactPhone: formData.contactPhone?.trim() || null,
        phone: formData.contactPhone?.trim() || null,
        whatsapp: formData.whatsapp?.trim() || null,
        email: formData.email?.trim() || null,
        website: formData.website?.trim() || null,
        latitude: formData.latitude !== '' ? parseFloat(formData.latitude) : null,
        longitude: formData.longitude !== '' ? parseFloat(formData.longitude) : null,
        priceRange: formData.priceRange || null,
        amenities: (formData.servicesOfferedText || '').split(',').map(s => s.trim()).filter(Boolean),
      };
    }

    if (listing.category === 'Second Hand Store') {
      return {
        ...common,
        price: formData.price?.trim() || null,
        contactPhone: formData.contactPhone?.trim() || null,
        contactEmail: formData.contactEmail?.trim() || null,
        deliveryOption: formData.deliveryOption?.trim() || null,
        externalUrl: formData.link?.trim() || null,
      };
    }

    if (listing.category === 'Events') {
      const format = formData.eventFormat || 'one_day';
      let endsAt = formData.endsAt;
      if (format === 'one_day' && formData.startsAt && !endsAt) {
        endsAt = formData.startsAt;
      }
      return {
        ...common,
        category: formData.eventCategory || 'festivals',
        format,
        city: formData.city?.trim() || null,
        venue: formData.venue?.trim() || null,
        address: formData.address?.trim() || null,
        isOnline: !!formData.isOnline,
        onlineLink: formData.onlineLink?.trim() || null,
        organizer: formData.organizer?.trim() || null,
        contact: formData.contactPhone?.trim() || null,
        timeText: formData.timeText?.trim() || null,
        startsAt: formData.startsAt ? new Date(formData.startsAt).toISOString() : null,
        endsAt: endsAt ? new Date(endsAt).toISOString() : null,
        price: formData.price?.trim() || null,
        priceType: formData.priceType || 'paid',
        priceText: formData.priceText?.trim() || formData.price?.trim() || null,
        ticketUrl: formData.ticketUrl?.trim() || null,
        externalUrl: formData.ticketUrl?.trim() || null,
        shortDescription: formData.shortDescription?.trim() || null,
        familyFriendly: !!formData.familyFriendly,
      };
    }

    return { ...common, status };
  };

  const handleSaveClick = async () => {
    try {
      const token = localStorage.getItem('adminToken');
      const resolvedImages = await resolveImageUrls(token);
      const payload = prepareSubmitPayload(listing.category === 'Jobs' ? 'Pending' : 'pending', resolvedImages);
      onSavePending(payload);
    } catch (e) { alert('Image upload failed: ' + e.message); }
  };

  const handleApproveClick = async () => {
    try {
      const token = localStorage.getItem('adminToken');
      const resolvedImages = await resolveImageUrls(token);
      const payload = prepareSubmitPayload(listing.category === 'Jobs' ? 'Active' : 'active', resolvedImages);
      onApprove(payload);
    } catch (e) { alert('Image upload failed: ' + e.message); }
  };

  const inputStyle = { width: '100%', padding: '8px 12px', border: '1px solid #d1d5db', borderRadius: '6px', fontSize: '14px', marginTop: '4px', boxSizing: 'border-box' };
  const textareaStyle = { width: '100%', padding: '8px 12px', border: '1px solid #d1d5db', borderRadius: '6px', fontSize: '14px', marginTop: '4px', fontFamily: 'inherit', boxSizing: 'border-box' };

  const renderCategoryFields = () => {
    if (listing.category === 'Accommodation') {
      return (
        <div style={{ marginTop: '20px', borderTop: '1px solid #e5e7eb', paddingTop: '15px' }}>
          <h4 style={{ margin: '0 0 12px 0', color: '#111827', fontSize: '15px', fontWeight: '600' }}>Accommodation Details</h4>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Property Type</label>
              <select name="propertyType" value={formData.propertyType} onChange={handleFieldChange} style={inputStyle}>
                <option value="apartment">Apartment</option>
                <option value="temporary_stays">Temporary Stays</option>
                <option value="shared_rooms">Shared Rooms</option>
              </select>
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Postal Code</label>
              <input type="text" name="postalCode" value={formData.postalCode} onChange={handleFieldChange} style={inputStyle} />
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Area</label>
              <input type="text" name="area" value={formData.area || ''} onChange={handleFieldChange} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Address (Paste Map Link Only)</label>
              <input type="text" name="address" value={formData.address} onChange={handleFieldChange} style={inputStyle} />
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px', marginBottom: '15px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Size (sqm)</label>
              <input type="number" value={formData.propertyDetails.sizeSqm} onChange={(e) => handleNestedFieldChange('propertyDetails', 'sizeSqm', 'number', e.target.value)} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Bedrooms</label>
              <input type="number" value={formData.propertyDetails.bedrooms} onChange={(e) => handleNestedFieldChange('propertyDetails', 'bedrooms', 'number', e.target.value)} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Bathrooms</label>
              <input type="number" value={formData.propertyDetails.bathrooms} onChange={(e) => handleNestedFieldChange('propertyDetails', 'bathrooms', 'number', e.target.value)} style={inputStyle} />
            </div>
          </div>
          <h5 style={{ margin: '15px 0 8px 0', color: '#374151', fontSize: '13px', fontWeight: '600' }}>Pricing & Rent (€)</h5>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px', marginBottom: '15px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Cold Rent</label>
              <input type="number" value={formData.rentDetails.coldRent} onChange={(e) => handleNestedFieldChange('rentDetails', 'coldRent', 'number', e.target.value)} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Warm Rent</label>
              <input type="number" value={formData.rentDetails.warmRent} onChange={(e) => handleNestedFieldChange('rentDetails', 'warmRent', 'number', e.target.value)} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Deposit</label>
              <input type="number" value={formData.rentDetails.deposit} onChange={(e) => handleNestedFieldChange('rentDetails', 'deposit', 'number', e.target.value)} style={inputStyle} />
            </div>
          </div>
          <h5 style={{ margin: '15px 0 8px 0', color: '#374151', fontSize: '13px', fontWeight: '600' }}>Amenities</h5>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '10px' }}>
            {ACCOMMODATION_AMENITIES.map((amenity) => (
              <label key={amenity.key} style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#374151', cursor: 'pointer' }}>
                <input type="checkbox" checked={!!formData.amenities[amenity.key]} onChange={(e) => handleNestedFieldChange('amenities', amenity.key, 'checkbox', e.target.checked)} style={{ width: '16px', height: '16px' }} />
                {amenity.label}
              </label>
            ))}
          </div>
          <div style={{ marginTop: '14px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Link / Website (Optional)</label>
            <input type="text" name="link" value={formData.link || ''} onChange={handleFieldChange} placeholder="https://..." style={inputStyle} />
          </div>
        </div>
      );
    }

    if (listing.category === 'Jobs') {
      return (
        <div style={{ marginTop: '20px', borderTop: '1px solid #e5e7eb', paddingTop: '15px' }}>
          <h4 style={{ margin: '0 0 12px 0', color: '#111827', fontSize: '15px', fontWeight: '600' }}>Job Details</h4>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Company Name</label>
              <input type="text" name="companyName" value={formData.companyName} onChange={handleFieldChange} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Job Type</label>
              <select name="jobType" value={formData.jobType} onChange={handleFieldChange} style={inputStyle}>
                <option value="Full Time">Full Time</option>
                <option value="Part Time">Part Time</option>
                <option value="Contract">Contract</option>
                <option value="Internship">Internship</option>
                <option value="Freelance">Freelance</option>
              </select>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Country</label>
              <select
                name="country"
                value={formData.country || 'Germany'}
                onChange={handleFieldChange}
                style={inputStyle}
              >
                {formData.country && !COUNTRY_OPTIONS.includes(formData.country) && (
                  <option value={formData.country}>{formData.country}</option>
                )}
                {COUNTRY_OPTIONS.map(c => (
                  <option key={c} value={c}>{c}</option>
                ))}
              </select>
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Field / Domain</label>
              <select
                name="domain"
                value={formData.domain || ''}
                onChange={handleFieldChange}
                style={inputStyle}
              >
                <option value="">Select Domain / Industry</option>
                {(availableDomains.length > 0 ? availableDomains : DEFAULT_DOMAINS).map(d => (
                  <option key={d} value={d}>{d}</option>
                ))}
                {formData.domain && !availableDomains.includes(formData.domain) && (
                  <option value={formData.domain}>{formData.domain}</option>
                )}
              </select>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Salary Info</label>
              <input type="text" name="salary" value={formData.salary} onChange={handleFieldChange} placeholder="e.g. €45,000 - €55,000 / year" style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Apply URL</label>
              <input type="text" name="applyUrl" value={formData.applyUrl} onChange={handleFieldChange} placeholder="https://..." style={inputStyle} />
            </div>
          </div>
          <div style={{ marginBottom: '12px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Requirements</label>
            <textarea name="requirements" rows={3} value={formData.requirements} onChange={handleFieldChange} style={textareaStyle} />
          </div>
          <div style={{ marginBottom: '12px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Benefits</label>
            <textarea name="benefits" rows={3} value={formData.benefits} onChange={handleFieldChange} style={textareaStyle} />
          </div>
        </div>
      );
    }
    if (listing.category === 'Services') {
      return (
        <div style={{ marginTop: '20px', borderTop: '1px solid #e5e7eb', paddingTop: '15px' }}>
          <h4 style={{ margin: '0 0 12px 0', color: '#111827', fontSize: '15px', fontWeight: '600' }}>Service Details</h4>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Service Type</label>
              <select name="serviceType" value={formData.serviceType} onChange={handleFieldChange} style={inputStyle}>
                <option value="Immigration">Immigration</option>
                <option value="Legal">Legal</option>
                <option value="Financial">Financial</option>
                <option value="Tax">Tax</option>
                <option value="Consultation">Consultation</option>
                <option value="Home Services">Home Services</option>
                <option value="Tuition &amp; Coaching">Tuition &amp; Coaching</option>
                <option value="IT Services">IT Services</option>
                <option value="Education">Education</option>
                <option value="Relocation">Relocation</option>
                <option value="Translation">Translation</option>
                <option value="Other">Other</option>
              </select>
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Provider Name</label>
              <input type="text" name="providerName" value={formData.providerName} onChange={handleFieldChange} style={inputStyle} />
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Area</label>
              <input type="text" name="area" value={formData.area} onChange={handleFieldChange} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Postal Code</label>
              <input type="text" name="postalCode" value={formData.postalCode || ''} onChange={handleFieldChange} style={inputStyle} />
            </div>
          </div>
          <div style={{ marginBottom: '12px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Address</label>
            <input type="text" name="address" value={formData.address || ''} onChange={handleFieldChange} style={inputStyle} />
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>WhatsApp</label>
              <input type="text" name="whatsapp" value={formData.whatsapp || ''} onChange={handleFieldChange} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Email</label>
              <input type="text" name="email" value={formData.email || ''} onChange={handleFieldChange} style={inputStyle} />
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Website</label>
              <input type="text" name="website" value={formData.website || ''} onChange={handleFieldChange} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Price Range</label>
              <select name="priceRange" value={formData.priceRange || '€€'} onChange={handleFieldChange} style={inputStyle}>
                <option value="€">€ (Low)</option>
                <option value="€€">€€ (Medium)</option>
                <option value="€€€">€€€ (Premium)</option>
                <option value="€€€€">€€€€ (Luxury)</option>
              </select>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Latitude</label>
              <input type="number" step="any" name="latitude" value={formData.latitude || ''} onChange={handleFieldChange} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Longitude</label>
              <input type="number" step="any" name="longitude" value={formData.longitude || ''} onChange={handleFieldChange} style={inputStyle} />
            </div>
          </div>
          <div style={{ marginBottom: '12px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Services Offered (comma separated)</label>
            <input type="text" name="servicesOfferedText" value={formData.servicesOfferedText || ''} onChange={handleFieldChange} style={inputStyle} />
          </div>
        </div>
      );
    }
    if (listing.category === 'Second Hand Store') {
      return (
        <div style={{ marginTop: '20px', borderTop: '1px solid #e5e7eb', paddingTop: '15px' }}>
          <h4 style={{ margin: '0 0 12px 0', color: '#111827', fontSize: '15px', fontWeight: '600' }}>Store Details</h4>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Price</label>
              <input type="text" name="price" value={formData.price} onChange={handleFieldChange} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Delivery Option</label>
              <select name="deliveryOption" value={formData.deliveryOption} onChange={handleFieldChange} style={inputStyle}>
                <option value="">— select —</option>
                <option value="Shipping Possible">Shipping Possible</option>
                <option value="Pickup only">Pickup only</option>
              </select>
            </div>
          </div>
          <div style={{ marginBottom: '12px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Contact Email</label>
            <input type="text" name="contactEmail" value={formData.contactEmail} onChange={handleFieldChange} style={inputStyle} />
          </div>
          <div style={{ marginBottom: '12px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Link / Website (Optional)</label>
            <input type="text" name="link" value={formData.link || ''} onChange={handleFieldChange} placeholder="https://..." style={inputStyle} />
          </div>
        </div>
      );
    }
    if (listing.category === 'Events') {
      return (
        <div style={{ marginTop: '20px', borderTop: '1px solid #e5e7eb', paddingTop: '15px' }}>
          <h4 style={{ margin: '0 0 12px 0', color: '#111827', fontSize: '15px', fontWeight: '600' }}>Event Details</h4>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Format *</label>
              <select name="eventFormat" value={formData.eventFormat || 'one_day'} onChange={handleFieldChange} style={inputStyle}>
                <option value="one_day">One-Day Event</option>
                <option value="multi_day">Multi-Day Festival</option>
                <option value="course">Course / Multi-Week</option>
                <option value="workshop">Single Workshop</option>
                <option value="screening">Movie Screening (Multiple Cinemas)</option>
                <option value="deadline">Deadline / Application Close</option>
              </select>
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Category *</label>
              <select name="eventCategory" value={formData.eventCategory || 'festivals'} onChange={handleFieldChange} style={inputStyle}>
                <option value="festivals">Festivals & Celebrations</option>
                <option value="screenings">Movies & Screenings</option>
                <option value="standup">Standup Comedy</option>
                <option value="concerts">Concerts & Music</option>
                <option value="workshops">Workshops & Masterclasses</option>
                <option value="networking">Professional & Networking</option>
                <option value="sports">Sports & Fitness</option>
                <option value="kids">Kids & Family</option>
                <option value="food">Food & Pop-ups</option>
                <option value="spiritual">Spiritual & Community</option>
                <option value="other">Other</option>
              </select>
            </div>
          </div>

          <div style={{ marginBottom: '12px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>
              Short Description (max 160 chars) - {(formData.shortDescription || '').length}/160
            </label>
            <input
              type="text"
              name="shortDescription"
              maxLength={160}
              value={formData.shortDescription || ''}
              onChange={handleFieldChange}
              placeholder="One punchy sentence for cards (e.g. Diwali mela with live stalls and dhol)"
              style={inputStyle}
            />
          </div>

          <div style={{ marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <input
              type="checkbox"
              id="rev_isOnline"
              name="isOnline"
              checked={!!formData.isOnline}
              onChange={handleFieldChange}
              style={{ width: '16px', height: '16px', cursor: 'pointer' }}
            />
            <label htmlFor="rev_isOnline" style={{ fontSize: '13px', color: '#374151', cursor: 'pointer' }}>
              This is an Online / Virtual Event (available across Germany)
            </label>
          </div>

          {formData.isOnline ? (
            <div style={{ marginBottom: '12px' }}>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Online Meeting / Stream Link</label>
              <input type="text" name="onlineLink" value={formData.onlineLink || ''} onChange={handleFieldChange} placeholder="https://zoom.us/j/... or Google Meet" style={inputStyle} />
            </div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
              <div>
                <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Venue Name</label>
                <input type="text" name="venue" value={formData.venue || ''} onChange={handleFieldChange} placeholder="e.g. Meistersingerhalle" style={inputStyle} />
              </div>
              <div>
                <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Street Address</label>
                <input type="text" name="address" value={formData.address || ''} onChange={handleFieldChange} placeholder="e.g. Münchener Str. 101, 90478" style={inputStyle} />
              </div>
            </div>
          )}

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Starts At *</label>
              <input type="datetime-local" name="startsAt" value={formData.startsAt || ''} onChange={handleFieldChange} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Ends At</label>
              <input type="datetime-local" name="endsAt" value={formData.endsAt || ''} onChange={handleFieldChange} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Time Text (Display)</label>
              <input type="text" name="timeText" value={formData.timeText || ''} onChange={handleFieldChange} placeholder="e.g. 18:00 - 22:00" style={inputStyle} />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Price Type</label>
              <select name="priceType" value={formData.priceType || 'paid'} onChange={handleFieldChange} style={inputStyle}>
                <option value="free">Free</option>
                <option value="paid">Paid</option>
                <option value="donation">Donation / Pay what you want</option>
              </select>
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Price Display Text</label>
              <input type="text" name="priceText" value={formData.priceText || ''} onChange={handleFieldChange} placeholder="e.g. €15 early bird, Free entry" style={inputStyle} />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Organizer / Host</label>
              <input type="text" name="organizer" value={formData.organizer || ''} onChange={handleFieldChange} placeholder="e.g. Bharat Club e.V." style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Ticket / Booking URL</label>
              <input type="text" name="ticketUrl" value={formData.ticketUrl || ''} onChange={handleFieldChange} placeholder="https://eventbrite.com/..." style={inputStyle} />
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <input
              type="checkbox"
              id="rev_familyFriendly"
              name="familyFriendly"
              checked={!!formData.familyFriendly}
              onChange={handleFieldChange}
              style={{ width: '16px', height: '16px', cursor: 'pointer' }}
            />
            <label htmlFor="rev_familyFriendly" style={{ fontSize: '13px', color: '#374151', cursor: 'pointer' }}>
              Family Friendly / Kids Welcome
            </label>
          </div>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="modal-overlay" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0, 0, 0, 0.5)', zIndex: 1000 }}>
      <div className="modal-content review-modal" style={{ maxWidth: '900px', width: '95%', maxHeight: '90vh', overflowY: 'auto', background: '#fff', borderRadius: '12px' }}>
        <div className="modal-header" style={{ padding: '20px', borderBottom: '1px solid #e5e7eb', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2>Edit & Moderate Listing</h2>
          <button className="close-btn" onClick={onClose} disabled={saving} style={{ border: 'none', background: 'none', cursor: 'pointer' }}>
            <X size={24} />
          </button>
        </div>
        <div className="review-content" style={{ padding: '20px 24px' }}>
          <div className="review-images" style={{ marginBottom: '20px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '600' }}>Listing Images</label>
            <div style={{ display: 'flex', gap: '8px', marginTop: '8px', flexWrap: 'wrap' }}>
              {images.map((img, idx) => (
                <div key={idx} style={{ position: 'relative' }}>
                  <img src={getDisplayUrl(img, idx)} alt={`img-${idx}`} style={{ width: 80, height: 80, objectFit: 'cover', borderRadius: 4 }} />
                  <button onClick={() => removeImage(idx)} style={{ position: 'absolute', top: -5, right: -5, background: '#ef4444', color: '#fff', border: 'none', borderRadius: '50%', padding: 2, cursor: 'pointer' }}><Trash2 size={12} /></button>
                </div>
              ))}
              {images.length < (listing.category === 'Second Hand Store' ? 5 : (listing.category === 'Jobs' ? 1 : 3)) && (
                <>
                  <input
                    type="file"
                    accept="image/*"
                    multiple
                    id="review-image-upload-input"
                    style={{ display: 'none' }}
                    onChange={handleImageUpload}
                  />
                  <label
                    htmlFor="review-image-upload-input"
                    style={{ width: 80, height: 80, border: '2px dashed #d1d5db', borderRadius: 4, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', boxSizing: 'border-box' }}
                  >
                    <Upload size={20} />
                  </label>
                </>
              )}
            </div>
          </div>
          <div className="review-details" style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '600' }}>Title / Name *</label>
              <input type="text" name="title" value={formData.title} onChange={handleFieldChange} style={inputStyle} />
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: listing.category === 'Second Hand Store' ? '1fr' : '1fr 1fr', gap: '12px' }}>
              {listing.category !== 'Second Hand Store' && (
                <div>
                  <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '600' }}>City *</label>
                  <input type="text" name="city" value={formData.city} onChange={handleFieldChange} style={inputStyle} />
                </div>
              )}
              <div>
                <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '600' }}>
                  {listing.category === 'Jobs' ? 'Contact Details' : 'Contact Phone *'}
                </label>
                <input
                  type="text"
                  name="contactPhone"
                  value={formData.contactPhone}
                  onChange={handleFieldChange}
                  style={inputStyle}
                />
              </div>
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '600' }}>Description *</label>
              <textarea name="description" rows={4} value={formData.description} onChange={handleFieldChange} style={textareaStyle} />
            </div>
            {renderCategoryFields()}
          </div>
        </div>
        <div className="review-actions" style={{ padding: '15px 24px', display: 'flex', justifyContent: 'flex-end', gap: '10px', borderTop: '1px solid #e5e7eb' }}>
          <button onClick={onClose} disabled={saving !== null} style={{ padding: '8px 16px', borderRadius: '6px', cursor: saving !== null ? 'not-allowed' : 'pointer', opacity: saving !== null ? 0.6 : 1 }}>Cancel</button>
          <button onClick={handleSaveClick} disabled={saving !== null} style={{ padding: '8px 16px', background: '#3b82f6', color: '#fff', border: 'none', borderRadius: '6px', cursor: saving !== null ? 'not-allowed' : 'pointer', opacity: saving !== null ? 0.6 : 1 }}>
            {saving === 'pending' ? 'Saving...' : 'Save Pending'}
          </button>
          <button onClick={handleApproveClick} disabled={saving !== null} style={{ padding: '8px 16px', background: '#10b981', color: '#fff', border: 'none', borderRadius: '6px', cursor: saving !== null ? 'not-allowed' : 'pointer', opacity: saving !== null ? 0.6 : 1 }}>
            {saving === 'active' || saving === 'approved' ? 'Approving...' : 'Approve'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ReviewListingModal;
