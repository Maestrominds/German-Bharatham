import React, { useState } from 'react';
import { X, MapPin, Phone, Clock, DollarSign, Star, Edit } from 'lucide-react';
import API_URL from '../config';

const ViewFoodGroceryModal = ({ item, onClose, onEdit }) => {
  const [mainIdx, setMainIdx] = useState(0);

  if (!item) return null;

  const rawImages = item.media?.images || item.images || (item.image ? [item.image] : []) || (item.companyLogo ? [item.companyLogo] : []);
  const resolveSrc = (src) => {
    if (!src) return null;
    // handle objects like { url: '...' }
    if (typeof src === 'object') src = src.url || src.src || src.path || '';
    if (!src) return null;
    if (/^(https?:)?\/\//i.test(src) || src.startsWith('data:')) return src;
    // relative path -> prefix with API_URL (strip trailing slash)
    const base = String(API_URL).replace(/\/$/, '');
    if (src.startsWith('/')) return base + src;
    return base + '/' + src;
  };

  let images = (Array.isArray(rawImages) ? rawImages.map(resolveSrc).filter(Boolean) : []);
  // fallback: if resolveSrc failed but raw strings exist, use raw strings
  if (images.length === 0 && Array.isArray(rawImages) && rawImages.length > 0) {
    images = rawImages.map(r => (typeof r === 'string' ? r : (r && (r.url || r.src || r.path || '')))).filter(Boolean);
  }

  

  // debug info for runtime inspection
  try { console.debug('ViewFoodGroceryModal images', { id: item._id, rawImages, images, imageField: item.image, companyLogo: item.companyLogo }); } catch (e) {}

  return (
    <div className="modal-overlay">
      <div className="modal-content modal-large" style={{ maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <h2>Listing Details</h2>
          <div className="header-actions">
            <button className="edit-btn" onClick={onEdit}>
              <Edit size={18} />
              Edit
            </button>
            <button className="close-btn" onClick={onClose}>
              <X size={24} />
            </button>
          </div>
        </div>

        <div className="view-content">
          {/* Image gallery */}
          {images && images.length > 0 && (
            <div style={{ marginBottom: 20 }}>
              <img
                src={images[mainIdx]}
                alt={item.title || item.name}
                style={{ width: '100%', maxHeight: 260, objectFit: 'cover', borderRadius: 8 }}
                onError={(e) => {
                  try {
                    const current = e.target.src || '';
                    const base = String(API_URL).replace(/\/$/, '');
                    // if current starts with base, try without base
                    if (current.startsWith(base)) {
                      e.target.src = current.replace(base, '');
                    } else {
                      // otherwise try prefixing with base
                      e.target.src = base + (current.startsWith('/') ? '' : '/') + current;
                    }
                  } catch (ex) { /* ignore */ }
                }}
              />
              {images.length > 1 && (
                <div style={{ display: 'flex', gap: 6, marginTop: 8, flexWrap: 'wrap' }}>
                  {images.map((img, i) => (
                    <img key={i} src={img} alt={`thumb-${i}`} onClick={() => setMainIdx(i)}
                      style={{ width: 60, height: 48, objectFit: 'cover', borderRadius: 4, cursor: 'pointer',
                        border: i === mainIdx ? '2px solid #6b9976' : '2px solid #e5e7eb' }} />
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Basic Info */}
          <div className="view-section">
            <div className="view-header-info">
              <div>
                <h1>{item.title || item.name}</h1>
                <div className="badges">
                  <span className="category-badge">{item.subCategory || item.category}</span>
                  {item.type && <span className="type-badge">{item.type}</span>}
                  {item.featured && <span className="featured-badge">Featured</span>}
                  <span className={`status-badge ${item.verified ? 'active' : 'inactive'}`}>
                    {item.verified ? 'Verified' : 'Not Verified'}
                  </span>
                </div>
              </div>
              <div className="rating-display">
                <Star fill="#FFD700" color="#FFD700" size={24} />
                <span className="rating-value">{item.rating ? item.rating.toFixed(1) : '0.0'}</span>
              </div>
            </div>
          </div>

          {/* Location */}
          <div className="view-section">
            <h3>
              <MapPin size={18} />
              Location
            </h3>
            <div className="info-grid">
              <div className="info-item">
                <span className="info-label">Address:</span>
                <span className="info-value">{item.address}</span>
              </div>
              {item.city && (
                <div className="info-item">
                  <span className="info-label">City:</span>
                  <span className="info-value">{item.city}</span>
                </div>
              )}
              {item.state && (
                <div className="info-item">
                  <span className="info-label">State/Region:</span>
                  <span className="info-value">{item.state}</span>
                </div>
              )}
              {item.zipCode && (
                <div className="info-item">
                  <span className="info-label">Zip Code:</span>
                  <span className="info-value">{item.zipCode}</span>
                </div>
              )}
            </div>
          </div>

          {/* Contact */}
          <div className="view-section">
            <h3>
              <Phone size={18} />
              Contact Information
            </h3>
            <div className="info-grid">
              {item.phone && (
                <div className="info-item">
                  <span className="info-label">Phone:</span>
                  <span className="info-value">
                    <a href={`tel:${item.phone}`}>{item.phone}</a>
                  </span>
                </div>
              )}
              {item.email && (
                <div className="info-item">
                  <span className="info-label">Email:</span>
                  <span className="info-value">
                    <a href={`mailto:${item.email}`}>{item.email}</a>
                  </span>
                </div>
              )}
              {item.website && (
                <div className="info-item">
                  <span className="info-label">Website:</span>
                  <span className="info-value">
                    <a href={item.website} target="_blank" rel="noopener noreferrer">
                      {item.website}
                    </a>
                  </span>
                </div>
              )}
            </div>
          </div>

          {/* Description */}
          {item.description && (
            <div className="view-section">
              <h3>Description</h3>
              <p className="description-text">{item.description}</p>
            </div>
          )}

          {/* Details */}
          <div className="view-section">
            <h3>Details</h3>
            <div className="info-grid">
              {item.openingHours && (
                <div className="info-item">
                  <span className="info-label">
                    <Clock size={16} />
                    Opening Hours:
                  </span>
                  <span className="info-value">{item.openingHours}</span>
                </div>
              )}
              {item.priceRange && (
                <div className="info-item">
                  <span className="info-label">
                    <DollarSign size={16} />
                    Price Range:
                  </span>
                  <span className="info-value">{item.priceRange}</span>
                </div>
              )}
            </div>
          </div>

          {/* Cuisine */}
          {item.cuisine && item.cuisine.length > 0 && (
            <div className="view-section">
              <h3>Cuisine Types</h3>
              <div className="tags-display">
                {item.cuisine.map((cuisine, idx) => (
                  <span key={idx} className="display-tag">{cuisine}</span>
                ))}
              </div>
            </div>
          )}

          {/* Specialties */}
          {item.specialties && item.specialties.length > 0 && (
            <div className="view-section">
              <h3>Specialties</h3>
              <div className="tags-display">
                {item.specialties.map((specialty, idx) => (
                  <span key={idx} className="display-tag">{specialty}</span>
                ))}
              </div>
            </div>
          )}

          {/* Services */}
          <div className="view-section">
            <h3>Services Available</h3>
            <div className="services-list">
              <div className={`service-item ${item.deliveryAvailable ? 'available' : 'unavailable'}`}>
                <span className="service-indicator"></span>
                Home Delivery
              </div>
              <div className={`service-item ${item.takeoutAvailable ? 'available' : 'unavailable'}`}>
                <span className="service-indicator"></span>
                Takeout
              </div>
            </div>
          </div>

          {/* Map Preview */}
          {item.latitude && item.longitude && (
            <div className="view-section">
              <h3>
                <MapPin size={18} />
                Location Map
              </h3>
              <div
                onClick={() => {
                  const url = `https://www.google.com/maps/dir/?api=1&destination=${item.latitude},${item.longitude}`;
                  window.open(url, '_blank', 'noopener,noreferrer');
                }}
                title="Click to open Google Maps navigation"
                style={{
                  position: 'relative', cursor: 'pointer', borderRadius: 10,
                  overflow: 'hidden', border: '2px solid #4caf50',
                  boxShadow: '0 2px 8px rgba(0,0,0,0.12)'
                }}
              >
                <iframe
                  title="food-map"
                  src={`https://www.openstreetmap.org/export/embed.html?bbox=${item.longitude - 0.015},${item.latitude - 0.015},${item.longitude + 0.015},${item.latitude + 0.015}&layer=mapnik&marker=${item.latitude},${item.longitude}`}
                  style={{ width: '100%', height: 200, border: 0, display: 'block', pointerEvents: 'none' }}
                />
                {/* Transparent overlay makes entire tile clickable */}
                <div style={{ position: 'absolute', inset: 0 }} />
                <div style={{
                  position: 'absolute', bottom: 8, right: 8,
                  background: 'rgba(255,255,255,0.92)', borderRadius: 6,
                  padding: '4px 10px', fontSize: 12, fontWeight: 600,
                  color: '#1a56db', boxShadow: '0 1px 4px rgba(0,0,0,0.15)'
                }}>
                  Click to navigate ↗
                </div>
              </div>
            </div>
          )}

          {/* Metadata */}
          <div className="view-section metadata">
            <div className="info-grid">
              <div className="info-item">
                <span className="info-label">Created:</span>
                <span className="info-value">
                  {new Date(item.createdAt).toLocaleDateString('en-GB', { 
                    year: 'numeric', 
                    month: 'long', 
                    day: 'numeric' 
                  })}
                </span>
              </div>
              <div className="info-item">
                <span className="info-label">Last Updated:</span>
                <span className="info-value">
                  {new Date(item.updatedAt).toLocaleDateString('en-GB', { 
                    year: 'numeric', 
                    month: 'long', 
                    day: 'numeric' 
                  })}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ViewFoodGroceryModal;
