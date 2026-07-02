import React, { useState } from 'react';
import { X, Check, Save, Upload, Trash2 } from 'lucide-react';

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
  const [images, setImages] = useState(Array.isArray(listing.images) && listing.images.length > 0
    ? listing.images
    : (listing.image ? [listing.image] : []));

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

      // Food
      subCategory: raw.subCategory || 'Restaurant',
      priceRange: raw.priceRange || '€€',
      type: raw.type || '',
      zipCode: raw.zipCode || '',
      website: raw.website || '',
      openingHours: raw.openingHours || '',
      cuisine: Array.isArray(raw.cuisine) ? raw.cuisine.join(', ') : (raw.cuisine || ''),
      specialties: Array.isArray(raw.specialties) ? raw.specialties.join(', ') : (raw.specialties || ''),
      dineInAvailable: !!raw.dineInAvailable,
      deliveryAvailable: !!raw.deliveryAvailable,
      takeoutAvailable: !!raw.takeoutAvailable,
      cateringAvailable: !!raw.cateringAvailable,

      // Jobs
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
      latitude: raw.latitude || '',
      longitude: raw.longitude || '',
      servicesOfferedText: Array.isArray(raw.amenities) ? raw.amenities.join(', ') : (raw.servicesOffered || '')
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

    const maxLimit = listing.category === 'Jobs' ? 1 : 3;
    if (images.length + files.length > maxLimit) {
      alert(`You can upload a maximum of ${maxLimit} image${maxLimit > 1 ? 's' : ''}.`);
      return;
    }

    files.forEach(file => {
      const reader = new FileReader();
      reader.onload = (uploadEvent) => {
        const base64 = uploadEvent.target.result;
        if (base64) {
          setImages(prev => {
            if (prev.length >= maxLimit) return prev;
            return [...prev, base64];
          });
        }
      };
      reader.readAsDataURL(file);
    });
  };

  const removeImage = (index) => {
    setImages(images.filter((_, i) => i !== index));
  };

  const prepareSubmitPayload = (status) => {
    const common = {
      title: formData.title?.trim() || '',
      city: formData.city?.trim() || '',
      description: formData.description?.trim() || '',
      images: images,
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
          images: images
        },
      };
    }

    if (listing.category === 'Food') {
      return {
        ...common,
        name: formData.title?.trim() || '',
        address: formData.address?.trim() || null,
        zipCode: formData.zipCode?.trim() || null,
        phone: formData.contactPhone?.trim() || null,
        subCategory: formData.subCategory || null,
        type: formData.type?.trim() || null,
        priceRange: formData.priceRange || null,
        openingHours: formData.openingHours?.trim() || null,
        website: formData.website?.trim() || null,
        cuisine: typeof formData.cuisine === 'string' ? formData.cuisine.split(',').map(s => s.trim()).filter(Boolean) : [],
        specialties: typeof formData.specialties === 'string' ? formData.specialties.split(',').map(s => s.trim()).filter(Boolean) : [],
        dineInAvailable: !!formData.dineInAvailable,
        deliveryAvailable: !!formData.deliveryAvailable,
        takeoutAvailable: !!formData.takeoutAvailable,
        cateringAvailable: !!formData.cateringAvailable,
      };
    }

    if (listing.category === 'Jobs') {
      return {
        ...common,
        location: formData.city?.trim() || '',
        contact: formData.contactPhone?.trim() || null,
        companyName: formData.companyName?.trim() || null,
        companyLogo: images.length > 0 ? images[0] : null,
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

    return { ...common, status };
  };

  const handleSaveClick = () => {
    const payload = prepareSubmitPayload(listing.category === 'Jobs' ? 'Pending' : 'pending');
    onSavePending(payload);
  };

  const handleApproveClick = () => {
    const payload = prepareSubmitPayload(listing.category === 'Jobs' ? 'Active' : 'active');
    onApprove(payload);
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
                <option value="Apartment">Apartment</option>
                <option value="House">House</option>
                <option value="Room">Room</option>
                <option value="Studio">Studio</option>
                <option value="Other">Other</option>
              </select>
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Postal Code</label>
              <input type="text" name="postalCode" value={formData.postalCode} onChange={handleFieldChange} style={inputStyle} maxLength={20} />
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Area</label>
              <input type="text" name="area" value={formData.area || ''} onChange={handleFieldChange} style={inputStyle} maxLength={100} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Address</label>
              <input type="text" name="address" value={formData.address} onChange={handleFieldChange} style={inputStyle} maxLength={200} />
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
        </div>
      );
    }
    if (listing.category === 'Food') {
      return (
        <div style={{ marginTop: '20px', borderTop: '1px solid #e5e7eb', paddingTop: '15px' }}>
          <h4 style={{ margin: '0 0 12px 0', color: '#111827', fontSize: '15px', fontWeight: '600' }}>Food Listing Details</h4>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Sub-Category</label>
              <select name="subCategory" value={formData.subCategory} onChange={handleFieldChange} style={inputStyle}>
                <option value="Restaurant">Restaurant</option>
                <option value="Grocery Store">Grocery Store</option>
                <option value="Bakery">Bakery</option>
                <option value="Cafe">Cafe</option>
                <option value="Food Truck">Food Truck</option>
                <option value="Other">Other</option>
              </select>
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Price Range</label>
              <select name="priceRange" value={formData.priceRange} onChange={handleFieldChange} style={inputStyle}>
                <option value="€">€ - Budget Friendly</option>
                <option value="€€">€€ - Moderate</option>
                <option value="€€€">€€€ - Expensive</option>
                <option value="€€€€">€€€€ - Very Expensive</option>
              </select>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Address</label>
              <input type="text" name="address" value={formData.address || ''} onChange={handleFieldChange} style={inputStyle} maxLength={200} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Postal Code</label>
              <input type="text" name="zipCode" value={formData.zipCode || ''} onChange={handleFieldChange} style={inputStyle} maxLength={20} />
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Type (e.g. Veg/Non-Veg)</label>
              <input type="text" name="type" value={formData.type || ''} onChange={handleFieldChange} style={inputStyle} placeholder="Vegetarian" maxLength={100} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Opening Hours</label>
              <input type="text" name="openingHours" value={formData.openingHours || ''} onChange={handleFieldChange} placeholder="e.g. 10:00 AM - 10:00 PM" style={inputStyle} maxLength={200} />
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '15px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Cuisines (comma separated)</label>
              <input type="text" name="cuisine" value={formData.cuisine} onChange={handleFieldChange} placeholder="South Indian, Punjabi, etc." style={inputStyle} maxLength={500} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Specialties (comma separated)</label>
              <input type="text" name="specialties" value={formData.specialties} onChange={handleFieldChange} placeholder="Biryani, Masala Dosa, etc." style={inputStyle} maxLength={500} />
            </div>
          </div>
          <h5 style={{ margin: '15px 0 8px 0', color: '#374151', fontSize: '13px', fontWeight: '600' }}>Options</h5>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: '10px' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#374151', cursor: 'pointer' }}>
              <input type="checkbox" name="dineInAvailable" checked={formData.dineInAvailable} onChange={handleFieldChange} style={{ width: '16px', height: '16px' }} /> Dine In
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#374151', cursor: 'pointer' }}>
              <input type="checkbox" name="deliveryAvailable" checked={formData.deliveryAvailable} onChange={handleFieldChange} style={{ width: '16px', height: '16px' }} /> Delivery
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#374151', cursor: 'pointer' }}>
              <input type="checkbox" name="takeoutAvailable" checked={formData.takeoutAvailable} onChange={handleFieldChange} style={{ width: '16px', height: '16px' }} /> Takeout
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#374151', cursor: 'pointer' }}>
              <input type="checkbox" name="cateringAvailable" checked={formData.cateringAvailable} onChange={handleFieldChange} style={{ width: '16px', height: '16px' }} /> Catering
            </label>
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
              <input type="text" name="companyName" value={formData.companyName} onChange={handleFieldChange} style={inputStyle} maxLength={100} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Job Type</label>
              <select name="jobType" value={formData.jobType} onChange={handleFieldChange} style={inputStyle}>
                <option value="Full-time">Full-time</option>
                <option value="Part-time">Part-time</option>
                <option value="Contract">Contract</option>
                <option value="Internship">Internship</option>
                <option value="Mini-Job">Mini-Job</option>
              </select>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Salary Info</label>
              <input type="text" name="salary" value={formData.salary} onChange={handleFieldChange} placeholder="e.g. €45,000 - €55,000 / year" style={inputStyle} maxLength={50} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Apply URL</label>
              <input type="text" name="applyUrl" value={formData.applyUrl} onChange={handleFieldChange} placeholder="https://..." style={inputStyle} maxLength={500} />
            </div>
          </div>
          <div style={{ marginBottom: '12px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Requirements</label>
            <textarea name="requirements" rows={3} value={formData.requirements} onChange={handleFieldChange} style={textareaStyle} maxLength={2000} />
          </div>
          <div style={{ marginBottom: '12px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Benefits</label>
            <textarea name="benefits" rows={3} value={formData.benefits} onChange={handleFieldChange} style={textareaStyle} maxLength={2000} />
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
              <input type="text" name="providerName" value={formData.providerName} onChange={handleFieldChange} style={inputStyle} maxLength={100} />
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Area</label>
              <input type="text" name="area" value={formData.area} onChange={handleFieldChange} style={inputStyle} maxLength={100} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Postal Code</label>
              <input type="text" name="postalCode" value={formData.postalCode || ''} onChange={handleFieldChange} style={inputStyle} maxLength={20} />
            </div>
          </div>
          <div style={{ marginBottom: '12px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Address</label>
            <input type="text" name="address" value={formData.address || ''} onChange={handleFieldChange} style={inputStyle} maxLength={200} />
          </div>
          <div style={{ marginBottom: '12px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Services Offered (comma separated)</label>
            <input type="text" name="servicesOfferedText" value={formData.servicesOfferedText} onChange={handleFieldChange} style={inputStyle} maxLength={2000} />
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
                  <img src={img} style={{ width: 80, height: 80, objectFit: 'cover', borderRadius: 4 }} />
                  <button onClick={() => removeImage(idx)} style={{ position: 'absolute', top: -5, right: -5, background: '#ef4444', color: '#fff', border: 'none', borderRadius: '50%', padding: 2, cursor: 'pointer' }}><Trash2 size={12} /></button>
                </div>
              ))}
              {images.length < 3 && (
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
              <input type="text" name="title" value={formData.title} onChange={handleFieldChange} style={inputStyle} required maxLength={100} />
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div>
                <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '600' }}>City *</label>
                <input type="text" name="city" value={formData.city} onChange={handleFieldChange} style={inputStyle} required maxLength={50} />
              </div>
              <div>
                <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '600' }}>Contact Phone *</label>
                <input type="text" name="contactPhone" value={formData.contactPhone} onChange={handleFieldChange} style={inputStyle} required maxLength={20} />
              </div>
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '600' }}>Description *</label>
              <textarea name="description" rows={4} value={formData.description} onChange={handleFieldChange} style={textareaStyle} required maxLength={5000} />
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
