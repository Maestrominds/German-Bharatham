import React, { useState } from 'react';
import { X } from 'lucide-react';

const AddAccommodationModal = ({ onClose, onSuccess }) => {
  const tabs = ['basic', 'rent', 'property', 'amenities', 'location'];
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    propertyType: 'shared_rooms',
    highlights: [],
    contactPhone: '',
    
    city: '',
    area: '',
    postalCode: '',
    address: '',
    latitude: '',
    longitude: '',
    
    rentDetails: {
      coldRent: '',
      warmRent: '',
      additionalCosts: '',
      deposit: '',
      electricityIncluded: false,
      heatingIncluded: false,
      internetIncluded: false
    },
    propertyDetails: {
      sizeSqm: '',
      bedrooms: '',
      bathrooms: '',
      totalFloors: ''
    },
    amenities: {
      balcony: false,
      terrace: false,
      garden: false,
      lift: false,
      parking: false,
      garage: false,
      cellar: false,
      washingMachine: false,
      dishwasher: false,
      kitchen: false,
      petsAllowed: false,
      smokingAllowed: false,
      anmeldungPossible: false,
      studentFriendly: false,
      wheelchairAccessible: false
    },
    locationHighlights: {
      nearUniversity: false,
      nearSupermarket: false,
      nearHospital: false,
      nearPublicTransport: false,
      ubahnDistanceMeters: '',
      sbahnDistanceMeters: '',
      busDistanceMeters: ''
    },
    media: {
      images: [],
      videoUrl: '',
      floorPlan: ''
    },
    adminControls: {
      viewsCount: 0,
      favouritesCount: 0
    }
  });

  const [activeTab, setActiveTab] = useState('basic');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const requiredFields = {
    basic: [
      { key: 'title', label: 'Title', valid: formData.title.trim().length > 0 },
      { key: 'contactPhone', label: 'Contact Phone', valid: formData.contactPhone.trim().length > 0 },
      { key: 'propertyType', label: 'Property Type', valid: formData.propertyType.trim().length > 0 },
      { key: 'city', label: 'City', valid: formData.city.trim().length > 0 },
      { key: 'postalCode', label: 'Postal Code', valid: formData.postalCode.trim().length > 0 }
    ],
    rent: [
      { key: 'coldRent', label: 'Cold Rent', valid: formData.rentDetails.coldRent !== '' },
      { key: 'warmRent', label: 'Warm Rent', valid: formData.rentDetails.warmRent !== '' },
      { key: 'additionalCosts', label: 'Additional Costs', valid: formData.rentDetails.additionalCosts !== '' },
      { key: 'deposit', label: 'Deposit', valid: formData.rentDetails.deposit !== '' }
    ],
    property: [
      { key: 'sizeSqm', label: 'Size (sqm)', valid: formData.propertyDetails.sizeSqm !== '' },
      { key: 'bedrooms', label: 'Bedrooms', valid: formData.propertyDetails.bedrooms !== '' },
      { key: 'bathrooms', label: 'Bathrooms', valid: formData.propertyDetails.bathrooms !== '' },
      { key: 'totalFloors', label: 'Total Floors', valid: formData.propertyDetails.totalFloors !== '' }
    ]
  };

  const isSectionValid = (section) => requiredFields[section].every((field) => field.valid);

  const getMissingFields = (section) => requiredFields[section].filter((field) => !field.valid).map((field) => field.label);

  const showMissingAlert = (section) => {
    const missing = getMissingFields(section);
    alert(`Please fill required fields in ${section.toUpperCase()} tab:\n• ${missing.join('\n• ')}`);
  };

  const canNavigateToTab = (targetTab) => {
    if (targetTab === 'basic') return true;
    if (targetTab === 'rent') return isSectionValid('basic');
    if (targetTab === 'property') return isSectionValid('basic') && isSectionValid('rent');
    if (targetTab === 'amenities' || targetTab === 'location') {
      return isSectionValid('basic') && isSectionValid('rent') && isSectionValid('property');
    }
    return false;
  };

  const goToTab = (targetTab) => {
    if (targetTab === 'rent' && !isSectionValid('basic')) {
      showMissingAlert('basic');
      setActiveTab('basic');
      return;
    }

    if (targetTab === 'property') {
      if (!isSectionValid('basic')) {
        showMissingAlert('basic');
        setActiveTab('basic');
        return;
      }
      if (!isSectionValid('rent')) {
        showMissingAlert('rent');
        setActiveTab('rent');
        return;
      }
    }

    if (targetTab === 'amenities' || targetTab === 'location') {
      if (!isSectionValid('basic')) {
        showMissingAlert('basic');
        setActiveTab('basic');
        return;
      }
      if (!isSectionValid('rent')) {
        showMissingAlert('rent');
        setActiveTab('rent');
        return;
      }
      if (!isSectionValid('property')) {
        showMissingAlert('property');
        setActiveTab('property');
        return;
      }
    }

    setActiveTab(targetTab);
  };

  const handleNext = () => {
    if (activeTab === 'basic' && !isSectionValid('basic')) {
      showMissingAlert('basic');
      return;
    }
    if (activeTab === 'rent' && !isSectionValid('rent')) {
      showMissingAlert('rent');
      return;
    }
    if (activeTab === 'property' && !isSectionValid('property')) {
      showMissingAlert('property');
      return;
    }

    const currentIndex = tabs.indexOf(activeTab);
    if (currentIndex < tabs.length - 1) {
      const nextTab = tabs[currentIndex + 1];
      goToTab(nextTab);
    }
  };

  const handleChange = (section, field, value) => {
    if (section) {
      setFormData(prev => ({
        ...prev,
        [section]: {
          ...prev[section],
          [field]: value
        }
      }));
    } else {
      setFormData(prev => ({ ...prev, [field]: value }));
    }
  };

  const handleSubmit = async () => {
    if (!isSectionValid('basic')) {
      showMissingAlert('basic');
      setActiveTab('basic');
      return;
    }
    if (!isSectionValid('rent')) {
      showMissingAlert('rent');
      setActiveTab('rent');
      return;
    }
    if (!isSectionValid('property')) {
      showMissingAlert('property');
      setActiveTab('property');
      return;
    }

    setIsSubmitting(true);

    try {
      // Convert string values to numbers for numeric fields
      const cleanedData = {
        ...formData,
        latitude: formData.latitude ? parseFloat(formData.latitude) : null,
        longitude: formData.longitude ? parseFloat(formData.longitude) : null,
        rentDetails: {
          ...formData.rentDetails,
          coldRent: formData.rentDetails.coldRent ? parseFloat(formData.rentDetails.coldRent) : null,
          warmRent: formData.rentDetails.warmRent ? parseFloat(formData.rentDetails.warmRent) : null,
          additionalCosts: formData.rentDetails.additionalCosts ? parseFloat(formData.rentDetails.additionalCosts) : null,
          deposit: formData.rentDetails.deposit ? parseFloat(formData.rentDetails.deposit) : null
        },
        propertyDetails: {
          ...formData.propertyDetails,
          sizeSqm: formData.propertyDetails.sizeSqm ? parseFloat(formData.propertyDetails.sizeSqm) : null,
          bedrooms: formData.propertyDetails.bedrooms ? parseInt(formData.propertyDetails.bedrooms, 10) : null,
          bathrooms: formData.propertyDetails.bathrooms ? parseInt(formData.propertyDetails.bathrooms, 10) : null,
          totalFloors: formData.propertyDetails.totalFloors ? parseInt(formData.propertyDetails.totalFloors, 10) : null
        },
        locationHighlights: {
          ...formData.locationHighlights,
          ubahnDistanceMeters: formData.locationHighlights.ubahnDistanceMeters ? parseInt(formData.locationHighlights.ubahnDistanceMeters, 10) : null,
          sbahnDistanceMeters: formData.locationHighlights.sbahnDistanceMeters ? parseInt(formData.locationHighlights.sbahnDistanceMeters, 10) : null,
          busDistanceMeters: formData.locationHighlights.busDistanceMeters ? parseInt(formData.locationHighlights.busDistanceMeters, 10) : null
        }
      };

      const response = await fetch('https://german-bharatham-backend.onrender.com/api/accommodation/admin', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-role': 'admin',
          'x-user-id': 'admin123'
        },
        body: JSON.stringify(cleanedData)
      });

      if (response.ok) {
        const result = await response.json();
        alert('Accommodation added successfully! ID: ' + result._id);
        onSuccess && onSuccess();
        onClose();
      } else {
        const error = await response.json();
        alert('Error: ' + error.message);
      }
    } catch (error) {
      alert('Error connecting to server: ' + error.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content modal-large">
        <div className="modal-header">
          <h2>Add New Accommodation</h2>
          <button className="close-btn" onClick={onClose}>
            <X size={24} />
          </button>
        </div>

        <div className="modal-tabs">
          <button className={`tab-btn ${activeTab === 'basic' ? 'active' : ''}`} onClick={() => goToTab('basic')} type="button">Basic Info</button>
          <button className={`tab-btn ${activeTab === 'rent' ? 'active' : ''}`} onClick={() => goToTab('rent')} type="button" disabled={!canNavigateToTab('rent')} title={!canNavigateToTab('rent') ? 'Fill Basic Info required fields first' : ''}>Rent Details</button>
          <button className={`tab-btn ${activeTab === 'property' ? 'active' : ''}`} onClick={() => goToTab('property')} type="button" disabled={!canNavigateToTab('property')} title={!canNavigateToTab('property') ? 'Fill Basic Info and Rent required fields first' : ''}>Property</button>
          <button className={`tab-btn ${activeTab === 'amenities' ? 'active' : ''}`} onClick={() => goToTab('amenities')} type="button" disabled={!canNavigateToTab('amenities')} title={!canNavigateToTab('amenities') ? 'Fill Basic, Rent, and Property required fields first' : ''}>Amenities</button>
          <button className={`tab-btn ${activeTab === 'location' ? 'active' : ''}`} onClick={() => goToTab('location')} type="button" disabled={!canNavigateToTab('location')} title={!canNavigateToTab('location') ? 'Fill Basic, Rent, and Property required fields first' : ''}>Location</button>
        </div>

        <form
          className="add-listing-form"
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              // Only submit if on location tab
              if (activeTab === 'location') {
                handleSubmit();
              }
            }
          }}
          onSubmit={(e) => {
            e.preventDefault();
            if (activeTab === 'location') {
              handleSubmit();
            } else {
              handleNext();
            }
          }}
        >
          {activeTab === 'basic' && (
            <div className="tab-content">
              <div className="form-group">
                <label>Title <span style={{ color: 'red' }}>*</span></label>
                <input type="text" value={formData.title} onChange={(e) => handleChange(null, 'title', e.target.value)} required placeholder="Cozy 2-Bedroom Apartment" />
              </div>
              
              <div className="form-group">
                <label>Description</label>
                <textarea value={formData.description} onChange={(e) => handleChange(null, 'description', e.target.value)} rows={5} placeholder="Detailed description..." />
              </div>

              <div className="form-group" style={{ border: '2px solid #ef4444', borderRadius: '8px', padding: '12px', backgroundColor: '#fef2f2' }}>
                <label style={{ color: '#dc2626', fontWeight: 700, fontSize: '14px' }}>📞 Contact Phone (Call &amp; WhatsApp) <span style={{ color: 'red' }}>*</span></label>
                <input
                  type="tel"
                  value={formData.contactPhone}
                  onChange={(e) => handleChange(null, 'contactPhone', e.target.value)}
                  placeholder="+49 170 1234567"
                  style={{ marginTop: '6px', borderColor: formData.contactPhone.trim().length === 0 ? '#ef4444' : '#d1d5db' }}
                />
                <small style={{ color: '#6b7280', display: 'block', marginTop: '4px' }}>⚠️ Required — include country code (e.g. +49). Users will Call or WhatsApp this number directly.</small>
              </div>

              <div className="form-group">
                <label>Property Type <span style={{ color: 'red' }}>*</span></label>
                <select value={formData.propertyType} onChange={(e) => handleChange(null, 'propertyType', e.target.value)} required>
                  <option value="shared_rooms">Shared Rooms</option>
                  <option value="private_apartments">Private Apartments</option>
                  <option value="temporary_stays">Temporary Stays</option>
                  <option value="rent_details">Rent Details</option>
                </select>
              </div>

              <div className="form-group">
                <label>Key Highlights (press Enter to add)</label>
                <input 
                  type="text" 
                  placeholder="e.g., Near University, Fully Furnished, Parking Available..." 
                  onKeyPress={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      const value = e.target.value.trim();
                      if (value && !formData.highlights.includes(value)) {
                        setFormData(prev => ({
                          ...prev,
                          highlights: [...prev.highlights, value]
                        }));
                        e.target.value = '';
                      }
                    }
                  }}
                />
                <div className="highlights-list" style={{ marginTop: '10px' }}>
                  {formData.highlights.map((highlight, index) => (
                    <span key={index} className="highlight-tag" style={{ 
                      display: 'inline-block', 
                      background: '#28a745', 
                      color: 'white', 
                      padding: '5px 10px', 
                      margin: '5px', 
                      borderRadius: '15px',
                      fontSize: '14px'
                    }}>
                      <span style={{ color: 'red', marginRight: '5px' }}>★</span>
                      {highlight}
                      <button 
                        type="button"
                        onClick={() => {
                          setFormData(prev => ({
                            ...prev,
                            highlights: prev.highlights.filter((_, i) => i !== index)
                          }));
                        }}
                        style={{ 
                          marginLeft: '8px', 
                          background: 'transparent', 
                          border: 'none', 
                          color: 'white', 
                          cursor: 'pointer',
                          fontSize: '16px'
                        }}
                      >
                        ×
                      </button>
                    </span>
                  ))}
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>City <span style={{ color: 'red' }}>*</span></label>
                  <input type="text" value={formData.city} onChange={(e) => handleChange(null, 'city', e.target.value)} required placeholder="Munich" />
                </div>
                <div className="form-group">
                  <label>Area</label>
                  <input type="text" value={formData.area} onChange={(e) => handleChange(null, 'area', e.target.value)} placeholder="Schwabing" />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Postal Code <span style={{ color: 'red' }}>*</span></label>
                  <input type="text" value={formData.postalCode} onChange={(e) => handleChange(null, 'postalCode', e.target.value)} placeholder="80331" required />
                </div>
                <div className="form-group">
                  <label>Address</label>
                  <input type="text" value={formData.address} onChange={(e) => handleChange(null, 'address', e.target.value)} placeholder="Leopoldstraße 123" />
                </div>
              </div>
            </div>
          )}

          {activeTab === 'rent' && (
            <div className="tab-content">
              <div className="form-row">
                <div className="form-group">
                  <label>Cold Rent (€) <span style={{ color: 'red' }}>*</span></label>
                  <input type="number" value={formData.rentDetails.coldRent} onChange={(e) => handleChange('rentDetails', 'coldRent', e.target.value)} placeholder="800" required />
                </div>
                <div className="form-group">
                  <label>Warm Rent (€) <span style={{ color: 'red' }}>*</span></label>
                  <input type="number" value={formData.rentDetails.warmRent} onChange={(e) => handleChange('rentDetails', 'warmRent', e.target.value)} placeholder="1000" required />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Additional Costs (€) <span style={{ color: 'red' }}>*</span></label>
                  <input type="number" value={formData.rentDetails.additionalCosts} onChange={(e) => handleChange('rentDetails', 'additionalCosts', e.target.value)} placeholder="200" required />
                </div>
                <div className="form-group">
                  <label>Deposit (€) <span style={{ color: 'red' }}>*</span></label>
                  <input type="number" value={formData.rentDetails.deposit} onChange={(e) => handleChange('rentDetails', 'deposit', e.target.value)} placeholder="2400" required />
                </div>
              </div>

              <div className="checkbox-group">
                <label className="checkbox-label">
                  <input type="checkbox" checked={formData.rentDetails.electricityIncluded} onChange={(e) => handleChange('rentDetails', 'electricityIncluded', e.target.checked)} />
                  Electricity Included
                </label>
                <label className="checkbox-label">
                  <input type="checkbox" checked={formData.rentDetails.heatingIncluded} onChange={(e) => handleChange('rentDetails', 'heatingIncluded', e.target.checked)} />
                  Heating Included
                </label>
                <label className="checkbox-label">
                  <input type="checkbox" checked={formData.rentDetails.internetIncluded} onChange={(e) => handleChange('rentDetails', 'internetIncluded', e.target.checked)} />
                  Internet Included
                </label>
              </div>
            </div>
          )}

          {activeTab === 'property' && (
            <div className="tab-content">
              <div className="form-row">
                <div className="form-group">
                  <label>Size (sqm) <span style={{ color: 'red' }}>*</span></label>
                  <input 
                    type="number" 
                    value={formData.propertyDetails.sizeSqm} 
                    onChange={(e) => handleChange('propertyDetails', 'sizeSqm', e.target.value)} 
                    placeholder="50" 
                    required 
                  />
                </div>
                <div className="form-group">
                  <label>Bedrooms <span style={{ color: 'red' }}>*</span></label>
                  <input 
                    type="number" 
                    value={formData.propertyDetails.bedrooms} 
                    onChange={(e) => handleChange('propertyDetails', 'bedrooms', e.target.value)} 
                    placeholder="2" 
                    required 
                  />
                </div>
                <div className="form-group">
                  <label>Bathrooms <span style={{ color: 'red' }}>*</span></label>
                  <input 
                    type="number" 
                    value={formData.propertyDetails.bathrooms} 
                    onChange={(e) => handleChange('propertyDetails', 'bathrooms', e.target.value)} 
                    placeholder="1" 
                    required 
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Total Floors <span style={{ color: 'red' }}>*</span></label>
                  <input 
                    type="number" 
                    value={formData.propertyDetails.totalFloors} 
                    onChange={(e) => handleChange('propertyDetails', 'totalFloors', e.target.value)} 
                    placeholder="5" 
                    required 
                  />
                </div>
              </div>
            </div>
          )}

          {activeTab === 'amenities' && (
            <div className="tab-content">
              <h3 style={{ marginBottom: '20px', color: '#333' }}>Property Amenities</h3>
              <div className="features-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '15px' }}>
                {Object.keys(formData.amenities).map(amenity => (
                  <label key={amenity} className="checkbox-label" style={{ 
                    padding: '12px', 
                    border: '1px solid #ddd', 
                    borderRadius: '8px',
                    cursor: 'pointer',
                    transition: 'all 0.2s',
                    backgroundColor: formData.amenities[amenity] ? '#d4edda' : 'white'
                  }}>
                    <input 
                      type="checkbox" 
                      checked={formData.amenities[amenity]} 
                      onChange={(e) => handleChange('amenities', amenity, e.target.checked)} 
                      style={{ marginRight: '10px' }}
                    />
                    <span style={{ fontWeight: formData.amenities[amenity] ? '600' : '400' }}>
                      {amenity.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                    </span>
                  </label>
                ))}
              </div>
            </div>
          )}

          {activeTab === 'location' && (
            <div className="tab-content">
              <div className="form-row">
                <div className="form-group">
                  <label>Latitude</label>
                  <input 
                    type="number" 
                    step="any"
                    value={formData.latitude} 
                    onChange={(e) => handleChange(null, 'latitude', e.target.value)} 
                    placeholder="48.1351" 
                  />
                </div>
                <div className="form-group">
                  <label>Longitude</label>
                  <input 
                    type="number" 
                    step="any"
                    value={formData.longitude} 
                    onChange={(e) => handleChange(null, 'longitude', e.target.value)} 
                    placeholder="11.5820" 
                  />
                </div>
                <div className="form-group">
                  <button 
                    type="button"
                    onClick={() => {
                      if (navigator.geolocation) {
                        navigator.geolocation.getCurrentPosition(
                          (position) => {
                            setFormData(prev => ({
                              ...prev,
                              latitude: position.coords.latitude.toFixed(6),
                              longitude: position.coords.longitude.toFixed(6)
                            }));
                            alert('Location captured successfully!');
                          },
                          (error) => {
                            alert('Unable to get location: ' + error.message);
                          }
                        );
                      } else {
                        alert('Geolocation is not supported by your browser');
                      }
                    }}
                    style={{
                      padding: '10px 20px',
                      marginTop: '25px',
                      background: '#28a745',
                      color: 'white',
                      border: 'none',
                      borderRadius: '5px',
                      cursor: 'pointer'
                    }}
                  >
                    Get Current Location
                  </button>
                </div>
              </div>

              {formData.latitude && formData.longitude && (
                <div className="map-preview" style={{ 
                  marginTop: '20px', 
                  padding: '15px', 
                  border: '2px solid #007bff', 
                  borderRadius: '8px',
                  backgroundColor: '#f8f9fa'
                }}>
                  <h4 style={{ marginBottom: '10px' }}>Location Preview</h4>
                  <p>Coordinates: {formData.latitude}, {formData.longitude}</p>
                  <button
                    type="button"
                    onClick={() => {
                      const url = `https://www.google.com/maps/dir/?api=1&destination=${formData.latitude},${formData.longitude}`;
                      window.open(url, '_blank');
                    }}
                    style={{
                      padding: '10px 20px',
                      marginTop: '10px',
                      background: '#007bff',
                      color: 'white',
                      border: 'none',
                      borderRadius: '5px',
                      cursor: 'pointer'
                    }}
                  >
                    Open in Google Maps & Get Directions
                  </button>
                </div>
              )}

              <div className="checkbox-group" style={{ marginTop: '20px' }}>
                <h4 style={{ marginBottom: '15px' }}>Location Highlights</h4>
                <label className="checkbox-label">
                  <input type="checkbox" checked={formData.locationHighlights.nearUniversity} onChange={(e) => handleChange('locationHighlights', 'nearUniversity', e.target.checked)} />
                  Near University
                </label>
                <label className="checkbox-label">
                  <input type="checkbox" checked={formData.locationHighlights.nearSupermarket} onChange={(e) => handleChange('locationHighlights', 'nearSupermarket', e.target.checked)} />
                  Near Supermarket
                </label>
                <label className="checkbox-label">
                  <input type="checkbox" checked={formData.locationHighlights.nearHospital} onChange={(e) => handleChange('locationHighlights', 'nearHospital', e.target.checked)} />
                  Near Hospital
                </label>
                <label className="checkbox-label">
                  <input type="checkbox" checked={formData.locationHighlights.nearPublicTransport} onChange={(e) => handleChange('locationHighlights', 'nearPublicTransport', e.target.checked)} />
                  Near Public Transport
                </label>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>U-Bahn Distance (m)</label>
                  <input type="number" value={formData.locationHighlights.ubahnDistanceMeters} onChange={(e) => handleChange('locationHighlights', 'ubahnDistanceMeters', e.target.value)} placeholder="200" />
                </div>
                <div className="form-group">
                  <label>S-Bahn Distance (m)</label>
                  <input type="number" value={formData.locationHighlights.sbahnDistanceMeters} onChange={(e) => handleChange('locationHighlights', 'sbahnDistanceMeters', e.target.value)} placeholder="300" />
                </div>
                <div className="form-group">
                  <label>Bus Distance (m)</label>
                  <input type="number" value={formData.locationHighlights.busDistanceMeters} onChange={(e) => handleChange('locationHighlights', 'busDistanceMeters', e.target.value)} placeholder="100" />
                </div>
              </div>

              <div className="form-group">
                <label>Image URLs (comma separated)</label>
                <input type="text" placeholder="https://image1.jpg, https://image2.jpg" onChange={(e) => handleChange('media', 'images', e.target.value.split(',').map(s => s.trim()))} />
              </div>
            </div>
          )}

          <div className="form-actions">
            <button type="button" className="cancel-btn" onClick={onClose} disabled={isSubmitting}>
              Cancel
            </button>
            {activeTab === 'location' ? (
              <button 
                type="submit" 
                className="create-btn" 
                disabled={isSubmitting}
                style={{ 
                  background: '#28a745', 
                  color: 'white', 
                  padding: '12px 24px', 
                  border: 'none', 
                  borderRadius: '6px', 
                  cursor: isSubmitting ? 'not-allowed' : 'pointer',
                  fontWeight: '600',
                  opacity: isSubmitting ? 0.6 : 1
                }}
              >
                {isSubmitting ? 'Adding...' : 'Add Accommodation'}
              </button>
            ) : (
              <button 
                type="button" 
                className="next-btn" 
                onClick={(e) => {
                  e.preventDefault();
                  e.stopPropagation();
                  handleNext();
                }}
                style={{ 
                  background: '#28a745', 
                  color: 'white', 
                  padding: '12px 24px', 
                  border: 'none', 
                  borderRadius: '6px', 
                  cursor: 'pointer',
                  fontWeight: '600'
                }}
              >
                Next →
              </button>
            )}
          </div>
        </form>
      </div>
    </div>
  );
};

export default AddAccommodationModal;
