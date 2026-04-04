import React from 'react';
import { X, Check } from 'lucide-react';

const ReviewListingModal = ({ listing, onClose, onApprove, onReject }) => {
  const images = Array.isArray(listing.images) && listing.images.length > 0
    ? listing.images
    : (listing.image ? [listing.image] : []);

  const mainImage = images[0] || (listing.category === 'Services' ? '/service-default.jpg' : null);

  return (
    <div className="modal-overlay">
      <div className="modal-content review-modal">
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
                {images.slice(0, 2).map((img, idx) => (
                  <img key={idx} src={img} alt={listing.title} className="thumbnail" />
                ))}
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
              <p className="description-text">{listing.description}</p>
            </div>

            {listing.foodType && (
              <div className="detail-section">
                <span className="detail-label">Food Type</span>
                <span className="detail-value">{listing.foodType}</span>
              </div>
            )}

            {listing.amenities && (
              <div className="detail-section">
                <span className="detail-label">Amenities</span>
                <div className="amenities-list">
                  {listing.amenities.map((amenity, index) => (
                    <span key={index} className="amenity-tag">
                      {amenity}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>

        <div className="review-actions">
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

        {listing.submittedBy && listing.submittedTime && (
          <div className="submission-info">
            <span>Submitted by <strong>{listing.submittedBy}</strong> • {listing.submittedTime}</span>
          </div>
        )}
      </div>
    </div>
  );
};

export default ReviewListingModal;
