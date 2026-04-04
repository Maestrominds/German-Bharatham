import React, { useEffect, useState } from 'react';
import { Eye, Check, X } from 'lucide-react';
import ReviewListingModal from './ReviewListingModal';
import SkeletonLoader from './SkeletonLoader';
import API_URL from '../config';

const PATCH_URLS = {
  Accommodation: (id) => `${API_URL}/api/accommodation/admin/${id}/status`,
  Food:          (id) => `${API_URL}/api/admin/foodgrocery/${id}/status`,
  Jobs:          (id) => `${API_URL}/api/jobs/admin/${id}/status`,
  Services:      (id) => `${API_URL}/api/services/admin/${id}/status`,
};

const DELETE_URLS = {
  Accommodation: (id) => `${API_URL}/api/accommodation/admin/${id}`,
  Food:          (id) => `${API_URL}/api/admin/foodgrocery/${id}`,
  Jobs:          (id) => `${API_URL}/api/jobs/admin/${id}`,
  Services:      (id) => `${API_URL}/api/services/admin/${id}`,
};

const ContentModeration = () => {
  const [showReviewModal, setShowReviewModal] = useState(false);
  const [selectedListing, setSelectedListing] = useState(null);
  const [pendingListings, setPendingListings] = useState([]);
  const [loading, setLoading] = useState(true);

  const authHeaders = () => ({
    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
    'Content-Type': 'application/json',
  });

  const mapListing = (category, raw) => ({
    id: raw._id,
    title: raw.title || raw.serviceName || raw.name || 'Untitled',
    category,
    location: raw.location || raw.city || raw.address || '',
    contact: raw.contactPhone || raw.phone || raw.email || '—',
    image: raw.companyLogo || raw.media?.images?.[0] || raw.images?.[0] || raw.image || null,
    images: raw.media?.images || raw.images || (raw.image ? [raw.image] : []),
    description: raw.description || '',
    amenities: Array.isArray(raw.amenities) ? raw.amenities : [],
    raw,
  });

  // eslint-disable-next-line react-hooks/exhaustive-deps
  const fetchPending = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API_URL}/api/admin/pending-listings`, {
        headers: authHeaders()
      });
      if (!res.ok) throw new Error(`Failed to fetch: ${res.status}`);
      const data = await res.json();
      console.log('✅ Fetched pending listings:', data);

      const all = [
        ...(data.Accommodation || []).map(r => mapListing('Accommodation', r)),
        ...(data.Food          || []).map(r => mapListing('Food', r)),
        ...(data.Jobs          || []).map(r => mapListing('Jobs', r)),
        ...(data.Services      || []).map(r => mapListing('Services', r)),
      ];
      console.log('📋 Total pending listings:', all.length);
      setPendingListings(all);
    } catch (e) {
      console.error('❌ Error fetching pending listings:', e);
      alert('Error loading pending listings: ' + e.message);
      setPendingListings([]);
    } finally {
      setLoading(false);
    }
  };

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { fetchPending(); }, []);

  const updateStatus = async (listing, status) => {
    try {
      const res = await fetch(PATCH_URLS[listing.category](listing.id), {
        method: 'PATCH',
        headers: authHeaders(),
        body: JSON.stringify({ status }),
      });
      if (!res.ok) {
        const e2 = await res.json().catch(() => ({}));
        throw new Error(e2.message || 'Failed to update status');
      }
      await fetchPending();
    } catch (e) { alert(e.message); }
  };

  const handleApprove = (listing) => updateStatus(listing, 'active');

  const handleReject = async (listing) => {
    try {
      const res = await fetch(DELETE_URLS[listing.category](listing.id), {
        method: 'DELETE',
        headers: authHeaders(),
      });
      if (!res.ok) {
        const e2 = await res.json().catch(() => ({}));
        throw new Error(e2.message || 'Failed to delete');
      }
      await fetchPending();
    } catch (e) { alert(e.message); }
  };

  return (
    <div className="content-moderation">
      <div className="moderation-header">
        <div>
          <h1>Content Moderation</h1>
          <p>Review and approve pending listings.</p>
        </div>
      </div>

      <div className="pending-listings">
        {loading ? (
          <SkeletonLoader rows={3} columns={5} type="list" />
        ) : pendingListings.length === 0 ? (
          <div style={{ padding: 30, textAlign: 'center' }}>No pending listings.</div>
        ) : pendingListings.map((listing) => (
          <div key={listing.id} className="listing-card">
            <div className="listing-image">
              {listing.image ? (
                <img src={listing.image} alt={listing.title} />
              ) : (
                <div style={{ width: '100%', height: '100%', background: '#f3f4f6', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22 }}>📷</div>
              )}
            </div>
            <div className="listing-details">
              <div className="listing-header">
                <h3>{listing.title}</h3>
                <span className="listing-category">{listing.category}</span>
              </div>
              <div className="listing-info">
                <div className="info-row">
                  <span className="info-label">Location</span>
                  <span className="info-label">Contact</span>
                </div>
                <div className="info-row">
                  <span className="info-value">{listing.location}</span>
                  <span className="info-value">{listing.contact}</span>
                </div>
              </div>
            </div>
            <div className="listing-actions-vertical">
              <button className="action-btn view-btn" onClick={() => { setSelectedListing(listing); setShowReviewModal(true); }}>
                <Eye size={16} /> View
              </button>
              <button className="action-btn approve-btn" onClick={() => handleApprove(listing)}>
                <Check size={16} /> Approve
              </button>
              <button className="action-btn reject-btn" onClick={() => handleReject(listing)}>
                <X size={16} /> Reject
              </button>
            </div>
          </div>
        ))}
      </div>

      {showReviewModal && selectedListing && (
        <ReviewListingModal
          listing={selectedListing}
          onClose={() => setShowReviewModal(false)}
          onApprove={() => { handleApprove(selectedListing); setShowReviewModal(false); }}
          onReject={() => { handleReject(selectedListing); setShowReviewModal(false); }}
        />
      )}
    </div>
  );
};

export default ContentModeration;