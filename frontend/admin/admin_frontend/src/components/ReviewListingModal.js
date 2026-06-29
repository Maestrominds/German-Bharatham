import React, { useState } from 'react';
import { X, Check, Save } from 'lucide-react';

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
  const images = Array.isArray(listing.images) && listing.images.length > 0
    ? listing.images
    : (listing.image ? [listing.image] : []);

  const mainImage = images[0] || (listing.category === 'Services' ? '/service-default.jpg' : null);

  // Set up local state for the editable fields from the listing's raw data
  const [formData, setFormData] = useState(() => {
    const raw = listing.raw || {};
    return {
      ...raw,
      title: raw.title || raw.serviceName || raw.name || '',
      description: raw.description || '',
      contactPhone: raw.contactPhone || raw.contact || raw.phone || raw.email || '',
      city: raw.city || raw.location || raw.address || '',
      state: raw.state || '',
      
      // Accommodation details
      propertyType: raw.propertyType || 'Apartment',
      postalCode: raw.zipCode || raw.postalCode || '',
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
      area: raw.area || '',
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

  // Prepares structural payload to match backend Prisma models on submission
  const prepareSubmitPayload = (status) => {
    if (listing.category === 'Accommodation') {
      return {
        title: formData.title?.trim() || '',
        city: formData.city?.trim() || '',
        contactPhone: formData.contactPhone?.trim() || '',
        phone: formData.contactPhone?.trim() || '',
        address: formData.address?.trim() || null,
        state: formData.state?.trim() || null,
        zipCode: formData.postalCode?.trim() || null,
        postalCode: formData.postalCode?.trim() || null,
        type: formData.propertyType || null,
        description: formData.description?.trim() || null,
        status,
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
      };
    }

    if (listing.category === 'Food') {
      const cuisineArr = typeof formData.cuisine === 'string'
        ? formData.cuisine.split(',').map(s => s.trim()).filter(Boolean)
        : (Array.isArray(formData.cuisine) ? formData.cuisine : []);
      const specialtiesArr = typeof formData.specialties === 'string'
        ? formData.specialties.split(',').map(s => s.trim()).filter(Boolean)
        : (Array.isArray(formData.specialties) ? formData.specialties : []);
      return {
        name: formData.title?.trim() || '',
        title: formData.title?.trim() || '',
        city: formData.city?.trim() || '',
        address: formData.address?.trim() || null,
        state: formData.state?.trim() || null,
        zipCode: formData.zipCode?.trim() || null,
        phone: formData.contactPhone?.trim() || null,
        subCategory: formData.subCategory || null,
        type: formData.type?.trim() || null,
        description: formData.description?.trim() || null,
        priceRange: formData.priceRange || null,
        openingHours: formData.openingHours?.trim() || null,
        website: formData.website?.trim() || null,
        cuisine: cuisineArr,
        specialties: specialtiesArr,
        dineInAvailable: !!formData.dineInAvailable,
        deliveryAvailable: !!formData.deliveryAvailable,
        takeoutAvailable: !!formData.takeoutAvailable,
        cateringAvailable: !!formData.cateringAvailable,
        status,
      };
    }

    if (listing.category === 'Jobs') {
      return {
        title: formData.title?.trim() || '',
        location: formData.city?.trim() || '',
        city: formData.city?.trim() || '',
        contact: formData.contactPhone?.trim() || null,
        description: formData.description?.trim() || null,
        companyName: formData.companyName?.trim() || null,
        jobType: formData.jobType || 'Full Time',
        salary: formData.salary?.trim() || null,
        applyUrl: formData.applyUrl?.trim() || null,
        requirements: formData.requirements?.trim() || null,
        benefits: formData.benefits?.trim() || null,
        status,
      };
    }

    if (listing.category === 'Services') {
      const amenities = (formData.servicesOfferedText || '')
        .split(',').map(s => s.trim()).filter(Boolean);
      return {
        title: formData.title?.trim() || '',
        serviceName: formData.title?.trim() || '',
        providerName: formData.providerName?.trim() || null,
        serviceType: formData.serviceType || null,
        city: formData.city?.trim() || '',
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
        description: formData.description?.trim() || null,
        priceRange: formData.priceRange || null,
        amenities,
        status,
      };
    }

    return { status };
  };

  const handleSaveClick = () => {
    const payload = prepareSubmitPayload(listing.category === 'Jobs' ? 'Pending' : 'pending');
    onSavePending(payload);
  };

  const handleApproveClick = () => {
    const payload = prepareSubmitPayload(listing.category === 'Jobs' ? 'Active' : 'active');
    onApprove(payload);
  };

  const inputStyle = {
    width: '100%',
    padding: '8px 12px',
    border: '1px solid #d1d5db',
    borderRadius: '6px',
    fontSize: '14px',
    marginTop: '4px',
    boxSizing: 'border-box'
  };

  const textareaStyle = {
    width: '100%',
    padding: '8px 12px',
    border: '1px solid #d1d5db',
    borderRadius: '6px',
    fontSize: '14px',
    marginTop: '4px',
    fontFamily: 'inherit',
    boxSizing: 'border-box'
  };

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
              <input type="text" name="postalCode" value={formData.postalCode} onChange={handleFieldChange} style={inputStyle} />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>State</label>
              <input type="text" name="state" value={formData.state || ''} onChange={handleFieldChange} style={inputStyle} placeholder="e.g. Bayern" />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Address</label>
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
              <input type="text" name="address" value={formData.address || ''} onChange={handleFieldChange} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Postal Code</label>
              <input type="text" name="zipCode" value={formData.zipCode || ''} onChange={handleFieldChange} style={inputStyle} />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Type (e.g. Veg/Non-Veg)</label>
              <input type="text" name="type" value={formData.type || ''} onChange={handleFieldChange} style={inputStyle} placeholder="Vegetarian" />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>State</label>
              <input type="text" name="state" value={formData.state || ''} onChange={handleFieldChange} style={inputStyle} placeholder="e.g. Berlin" />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Opening Hours</label>
              <input type="text" name="openingHours" value={formData.openingHours || ''} onChange={handleFieldChange} placeholder="e.g. 10:00 AM - 10:00 PM" style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Website</label>
              <input type="text" name="website" value={formData.website || ''} onChange={handleFieldChange} placeholder="https://..." style={inputStyle} />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '15px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Cuisines (comma separated)</label>
              <input type="text" name="cuisine" value={formData.cuisine} onChange={handleFieldChange} placeholder="South Indian, Punjabi, etc." style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Specialties (comma separated)</label>
              <input type="text" name="specialties" value={formData.specialties} onChange={handleFieldChange} placeholder="Biryani, Masala Dosa, etc." style={inputStyle} />
            </div>
          </div>

          <h5 style={{ margin: '15px 0 8px 0', color: '#374151', fontSize: '13px', fontWeight: '600' }}>Options</h5>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: '10px' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#374151', cursor: 'pointer' }}>
              <input type="checkbox" name="dineInAvailable" checked={formData.dineInAvailable} onChange={handleFieldChange} style={{ width: '16px', height: '16px' }} />
              Dine In
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#374151', cursor: 'pointer' }}>
              <input type="checkbox" name="deliveryAvailable" checked={formData.deliveryAvailable} onChange={handleFieldChange} style={{ width: '16px', height: '16px' }} />
              Delivery
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#374151', cursor: 'pointer' }}>
              <input type="checkbox" name="takeoutAvailable" checked={formData.takeoutAvailable} onChange={handleFieldChange} style={{ width: '16px', height: '16px' }} />
              Takeout
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#374151', cursor: 'pointer' }}>
              <input type="checkbox" name="cateringAvailable" checked={formData.cateringAvailable} onChange={handleFieldChange} style={{ width: '16px', height: '16px' }} />
              Catering
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
              <input type="text" name="companyName" value={formData.companyName} onChange={handleFieldChange} style={inputStyle} />
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
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Price Range</label>
              <select name="priceRange" value={formData.priceRange} onChange={handleFieldChange} style={inputStyle}>
                <option value="€">€ (Low)</option>
                <option value="€€">€€ (Medium)</option>
                <option value="€€€">€€€ (Premium)</option>
                <option value="€€€€">€€€€ (Luxury)</option>
              </select>
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>WhatsApp (No spaces/special chars)</label>
              <input type="text" name="whatsapp" value={formData.whatsapp} onChange={(e) => {
                e.target.value = e.target.value.replace(/[^0-9]/g, '');
                handleFieldChange(e);
              }} placeholder="49123456789" style={inputStyle} />
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
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Email</label>
              <input type="email" name="email" value={formData.email || ''} onChange={handleFieldChange} style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Website</label>
              <input type="text" name="website" value={formData.website || ''} onChange={handleFieldChange} placeholder="https://..." style={inputStyle} />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Latitude</label>
              <input type="number" name="latitude" value={formData.latitude} onChange={handleFieldChange} step="any" style={inputStyle} />
            </div>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Longitude</label>
              <input type="number" name="longitude" value={formData.longitude} onChange={handleFieldChange} step="any" style={inputStyle} />
            </div>
          </div>

          <div style={{ marginBottom: '12px' }}>
            <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '500' }}>Services Offered (comma separated)</label>
            <input type="text" name="servicesOfferedText" value={formData.servicesOfferedText} onChange={handleFieldChange} placeholder="e.g. Tax filing, Double tax consultation" style={inputStyle} />
          </div>
        </div>
      );
    }

    return null;
  };

  return (
    <div className="modal-overlay" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0, 0, 0, 0.5)', zIndex: 1000 }}>
      <div className="modal-content review-modal" style={{ maxWidth: '900px', width: '95%', maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <h2>Edit & Moderate Listing</h2>
          <button className="close-btn" onClick={onClose} disabled={saving}>
            <X size={24} />
          </button>
        </div>

        <div className="review-content" style={{ padding: '20px 24px' }}>
          <div className="review-images" style={{ marginBottom: '20px' }}>
            {mainImage ? (
              <>
                <img src={mainImage} alt={formData.title} className="main-image" style={{ width: '100%', maxHeight: '240px', objectFit: 'cover', borderRadius: '8px' }} />
                <div style={{ display: 'flex', gap: '8px', marginTop: '8px', overflowX: 'auto' }}>
                  {images.map((img, idx) => (
                    <img key={idx} src={img} alt={formData.title} className="thumbnail" style={{ width: 60, height: 60, objectFit: 'cover', borderRadius: 4, cursor: 'pointer', border: idx === 0 ? '2px solid #10b981' : 'none' }} />
                  ))}
                </div>
              </>
            ) : (
              <div style={{ width: '100%', height: 180, background: '#f3f4f6', borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 28 }}>
                📷
              </div>
            )}
          </div>

          <div className="review-details" style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '600' }}>Listing Category</label>
              <span className="listing-category-text" style={{ display: 'block', fontSize: '16px', fontWeight: 'bold', color: '#10b981', marginTop: '4px' }}>{listing.category}</span>
            </div>

            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '600' }}>Title / Name <span style={{ color: '#ef4444' }}>*</span></label>
              <input type="text" name="title" value={formData.title} onChange={handleFieldChange} style={inputStyle} required />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div>
                <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '600' }}>City <span style={{ color: '#ef4444' }}>*</span></label>
                <input type="text" name="city" value={formData.city} onChange={handleFieldChange} style={inputStyle} required />
              </div>
              <div>
                <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '600' }}>Contact Phone <span style={{ color: '#ef4444' }}>*</span></label>
                <input type="text" name="contactPhone" value={formData.contactPhone} onChange={handleFieldChange} style={inputStyle} required />
              </div>
            </div>

            <div>
              <label style={{ fontSize: '12px', color: '#4b5563', fontWeight: '600' }}>Description <span style={{ color: '#ef4444' }}>*</span></label>
              <textarea name="description" rows={4} value={formData.description} onChange={handleFieldChange} style={textareaStyle} required />
            </div>

            {renderCategoryFields()}
          </div>
        </div>

        {listing.createdBy && (
          <div className="submission-info" style={{ margin: '0 24px 15px 24px', padding: '12px', background: '#f0f9ff', border: '1px solid #bae6fd', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '13px', color: '#0369a1' }}>
              👤 Submitted by User: <strong>{listing.createdBy.name}</strong> ({listing.createdBy.email || 'No email'})
            </span>
          </div>
        )}

        <div className="review-actions" style={{ padding: '15px 24px', display: 'flex', justifyContent: 'flex-end', gap: '10px', borderTop: '1px solid #e5e7eb' }}>
          <button className="close-action-btn" onClick={onClose} disabled={!!saving} style={{ padding: '8px 16px', background: '#f3f4f6', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: '500' }}>
            Cancel
          </button>
          <button className="approve-action-btn" onClick={handleSaveClick} disabled={!!saving} style={{ padding: '8px 16px', background: '#3b82f6', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px', fontWeight: '500', opacity: saving ? 0.7 : 1 }}>
            <Save size={16} />
            {saving === 'pending' ? 'Saving...' : 'Save as Pending'}
          </button>
          <button className="approve-action-btn" onClick={handleApproveClick} disabled={!!saving} style={{ padding: '8px 16px', background: '#10b981', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px', fontWeight: '500', opacity: saving ? 0.7 : 1 }}>
            <Check size={16} />
            {saving === 'active' ? 'Approving...' : 'Save & Approve'}
          </button>
          <button className="reject-action-btn" onClick={onReject} disabled={!!saving} style={{ padding: '8px 16px', background: '#ef4444', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px', fontWeight: '500', opacity: saving ? 0.7 : 1 }}>
            <X size={16} />
            Reject
          </button>
        </div>
      </div>
    </div>
  );
};

export default ReviewListingModal;
