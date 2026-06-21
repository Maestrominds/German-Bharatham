import React from 'react';
import { X, Check } from 'lucide-react';

const ReviewListingModal = ({ listing, onClose, onApprove, onReject }) => {
  const images = Array.isArray(listing.images) && listing.images.length > 0
    ? listing.images
    : (listing.image ? [listing.image] : []);

  const mainImage = images[0] || (listing.category === 'Services' ? '/service-default.jpg' : null);

  const renderCategoryDetails = () => {
    const raw = listing.raw || {};
    if (listing.category === 'Accommodation') {
      return (
        <div style={{ marginTop: '15px', borderTop: '1px solid #f3f4f6', paddingTop: '15px' }}>
          <h4 style={{ margin: '0 0 10px 0', color: '#111827' }}>Accommodation Details</h4>
          <div className="details-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '15px' }}>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Property Type</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.propertyType || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Postal Code</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.postalCode || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Address</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.address || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Size</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.propertyDetails?.sizeSqm ? `${raw.propertyDetails.sizeSqm} sqm` : '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Bedrooms</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.propertyDetails?.bedrooms || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Bathrooms</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.propertyDetails?.bathrooms || '—'}</span>
            </div>
          </div>
          <h4 style={{ margin: '15px 0 10px 0', color: '#111827' }}>Pricing</h4>
          <div className="details-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '15px' }}>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Cold Rent</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.rentDetails?.coldRent ? `€${raw.rentDetails.coldRent}` : '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Warm Rent</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.rentDetails?.warmRent ? `€${raw.rentDetails.warmRent}` : '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Deposit</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.rentDetails?.deposit ? `€${raw.rentDetails.deposit}` : '—'}</span>
            </div>
          </div>
        </div>
      );
    }
    if (listing.category === 'Food') {
      return (
        <div style={{ marginTop: '15px', borderTop: '1px solid #f3f4f6', paddingTop: '15px' }}>
          <h4 style={{ margin: '0 0 10px 0', color: '#111827' }}>Food & Grocery Details</h4>
          <div className="details-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '15px' }}>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Sub-Category</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.subCategory || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Price Range</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.priceRange || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Type/Cuisine</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.type || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Zip Code</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.zipCode || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Address</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.address || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>State</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.state || '—'}</span>
            </div>
            <div className="detail-item" style={{ gridColumn: 'span 2' }}>
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Website</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>
                {raw.website ? <a href={raw.website} target="_blank" rel="noreferrer" style={{ color: '#10b981' }}>{raw.website}</a> : '—'}
              </span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Opening Hours</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.openingHours || '—'}</span>
            </div>
          </div>
          
          {raw.cuisine && raw.cuisine.length > 0 && (
            <div className="detail-section" style={{ marginTop: '12px' }}>
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Cuisines</span>
              <div className="amenities-list" style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', marginTop: '5px' }}>
                {raw.cuisine.map((c, idx) => <span key={idx} className="amenity-tag" style={{ background: '#f3f4f6', padding: '2px 8px', borderRadius: '4px', fontSize: '12px' }}>{c}</span>)}
              </div>
            </div>
          )}
          {raw.specialties && raw.specialties.length > 0 && (
            <div className="detail-section" style={{ marginTop: '12px' }}>
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Specialties</span>
              <div className="amenities-list" style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', marginTop: '5px' }}>
                {raw.specialties.map((s, idx) => <span key={idx} className="amenity-tag" style={{ background: '#f3f4f6', padding: '2px 8px', borderRadius: '4px', fontSize: '12px' }}>{s}</span>)}
              </div>
            </div>
          )}

          <div className="detail-section" style={{ marginTop: '12px' }}>
            <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Services Available</span>
            <div style={{ display: 'flex', gap: '15px', flexWrap: 'wrap', marginTop: '5px' }}>
              <label><input type="checkbox" checked={!!raw.dineInAvailable} readOnly style={{ marginRight: '4px' }} /> Dine-in</label>
              <label><input type="checkbox" checked={!!raw.deliveryAvailable} readOnly style={{ marginRight: '4px' }} /> Delivery</label>
              <label><input type="checkbox" checked={!!raw.takeoutAvailable} readOnly style={{ marginRight: '4px' }} /> Takeout</label>
              <label><input type="checkbox" checked={!!raw.cateringAvailable} readOnly style={{ marginRight: '4px' }} /> Catering</label>
            </div>
          </div>
        </div>
      );
    }
    if (listing.category === 'Jobs') {
      return (
        <div style={{ marginTop: '15px', borderTop: '1px solid #f3f4f6', paddingTop: '15px' }}>
          <h4 style={{ margin: '0 0 10px 0', color: '#111827' }}>Job Details</h4>
          <div className="details-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '15px' }}>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Company Name</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.companyName || raw.company || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Job Type</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.jobType || raw.type || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Salary</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.salary || '—'}</span>
            </div>
            <div className="detail-item" style={{ gridColumn: 'span 2' }}>
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Apply URL</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>
                {raw.applyUrl ? <a href={raw.applyUrl} target="_blank" rel="noreferrer" style={{ color: '#10b981' }}>{raw.applyUrl}</a> : '—'}
              </span>
            </div>
          </div>
          <div className="detail-section" style={{ marginTop: '12px' }}>
            <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Requirements</span>
            <p className="description-text" style={{ whiteSpace: 'pre-line', fontSize: '13px', margin: '4px 0 0 0', color: '#374151' }}>{raw.requirements || '—'}</p>
          </div>
          <div className="detail-section" style={{ marginTop: '12px' }}>
            <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Benefits</span>
            <p className="description-text" style={{ whiteSpace: 'pre-line', fontSize: '13px', margin: '4px 0 0 0', color: '#374151' }}>{raw.benefits || '—'}</p>
          </div>
        </div>
      );
    }
    if (listing.category === 'Services') {
      return (
        <div style={{ marginTop: '15px', borderTop: '1px solid #f3f4f6', paddingTop: '15px' }}>
          <h4 style={{ margin: '0 0 10px 0', color: '#111827' }}>Service Details</h4>
          <div className="details-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '15px' }}>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Service Type</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.serviceType || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Provider Name</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.providerName || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Price Range</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.priceRange || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>WhatsApp</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.whatsapp || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Postal Code</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.postalCode || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Area</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.area || '—'}</span>
            </div>
            <div className="detail-item" style={{ gridColumn: 'span 2' }}>
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Website</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>
                {raw.website ? <a href={raw.website} target="_blank" rel="noreferrer" style={{ color: '#10b981' }}>{raw.website}</a> : '—'}
              </span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Latitude</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.latitude || '—'}</span>
            </div>
            <div className="detail-item">
              <span className="detail-label" style={{ display: 'block', fontSize: '12px', color: '#6b7280' }}>Longitude</span>
              <span className="detail-value" style={{ fontWeight: '500', color: '#1f2937' }}>{raw.longitude || '—'}</span>
            </div>
          </div>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content review-modal" style={{ maxWidth: '650px', width: '95%', maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <h2>Review Listing</h2>
          <button className="close-btn" onClick={onClose}>
            <X size={24} />
          </button>
        </div>

        <div className="review-content">
          <div className="review-images">
            {mainImage ? (
              <>
                <img src={mainImage} alt={listing.title} className="main-image" />
                <div style={{ display: 'flex', gap: '8px', marginTop: '8px', overflowX: 'auto' }}>
                  {images.map((img, idx) => (
                    <img key={idx} src={img} alt={listing.title} className="thumbnail" style={{ width: 60, height: 60, objectFit: 'cover', borderRadius: 4, cursor: 'pointer', border: idx === 0 ? '2px solid #10b981' : 'none' }} />
                  ))}
                </div>
              </>
            ) : (
              <div style={{ width: '100%', height: 180, background: '#f3f4f6', borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 28 }}>
                📷
              </div>
            )}
          </div>

          <div className="review-details">
            <div className="listing-title-section">
              <h3>{listing.title}</h3>
              <span className="pending-tag">Pending</span>
            </div>
            <p className="listing-category-text">{listing.category}</p>

            <div className="details-grid">
              <div className="detail-item">
                <span className="detail-label">Location</span>
                <span className="detail-value">{listing.location}</span>
              </div>
              <div className="detail-item">
                <span className="detail-label">Contact</span>
                <span className="detail-value">{listing.contact}</span>
              </div>
            </div>

            <div className="detail-section">
              <span className="detail-label">Description</span>
              <p className="description-text" style={{ whiteSpace: 'pre-line' }}>{listing.description || 'No description provided.'}</p>
            </div>

            {listing.foodType && (
              <div className="detail-section">
                <span className="detail-label">Food Type</span>
                <span className="detail-value">{listing.foodType}</span>
              </div>
            )}

            {listing.amenities && listing.amenities.length > 0 && (
              <div className="detail-section">
                <span className="detail-label">Amenities / Tags</span>
                <div className="amenities-list">
                  {listing.amenities.map((amenity, index) => (
                    <span key={index} className="amenity-tag">
                      {amenity}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {renderCategoryDetails()}
          </div>
        </div>

        {listing.createdBy && (
          <div className="submission-info" style={{ margin: '15px 24px 0 24px', padding: '12px', background: '#f0f9ff', border: '1px solid #bae6fd', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '13px', color: '#0369a1' }}>
              👤 Submitted by User: <strong>{listing.createdBy.name}</strong> ({listing.createdBy.email || 'No email'})
            </span>
          </div>
        )}

        <div className="review-actions" style={{ padding: '15px 24px' }}>
          <button className="close-action-btn" onClick={onClose}>
            Close
          </button>
          <button className="approve-action-btn" onClick={onApprove}>
            <Check size={16} />
            Approve
          </button>
          <button className="reject-action-btn" onClick={onReject}>
            <X size={16} />
            Reject
          </button>
        </div>
      </div>
    </div>
  );
};

export default ReviewListingModal;
