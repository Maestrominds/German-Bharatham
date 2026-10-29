import React, { useEffect, useState } from 'react';
import { Edit, Check, X } from 'lucide-react';
import ReviewListingModal from './ReviewListingModal';
import SkeletonLoader from './SkeletonLoader';
import API_URL from '../config';

const PATCH_URLS = {
  Accommodation: (id) => `${API_URL}/api/accommodation/admin/${id}/status`,
  Jobs:          (id) => `${API_URL}/api/jobs/admin/${id}/status`,
  Services:      (id) => `${API_URL}/api/services/admin/${id}/status`,
  'Second Hand Store': (id) => `${API_URL}/api/second-hand/admin/${id}/status`,
  Events:        (id) => `${API_URL}/api/events/admin/${id}/status`,
};

const DELETE_URLS = {
  Accommodation: (id) => `${API_URL}/api/accommodation/admin/${id}`,
  Jobs:          (id) => `${API_URL}/api/jobs/admin/${id}`,
  Services:      (id) => `${API_URL}/api/services/admin/${id}`,
  'Second Hand Store': (id) => `${API_URL}/api/second-hand/admin/${id}`,
  Events:        (id) => `${API_URL}/api/events/admin/${id}`,
};

const ContentModeration = () => {
  const [showReviewModal, setShowReviewModal] = useState(false);
  const [selectedListing, setSelectedListing] = useState(null);
  const [pendingListings, setPendingListings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(null);

  // Filters & Pagination
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [creatorFilter, setCreatorFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);

  const authHeaders = () => ({
    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
    'Content-Type': 'application/json',
  });

  const mapListing = (category, raw) => ({
    id: raw._id,
    title: raw.title || raw.serviceName || raw.name || 'Untitled',
    category,
    location: raw.location || raw.city || raw.address || '',
    contact: raw.contactPhone || raw.contact || raw.phone || raw.email || '—',
    image: raw.companyLogo || raw.media?.images?.[0] || raw.images?.[0] || (raw.image ? (typeof raw.image === 'string' && raw.image.includes(';;;') ? raw.image.split(';;;')[0] : raw.image) : null),
    images: raw.media?.images || raw.images || (raw.image ? (typeof raw.image === 'string' && raw.image.includes(';;;') ? raw.image.split(';;;') : [raw.image]) : []),
    description: raw.description || '',
    amenities: Array.isArray(raw.amenities) ? raw.amenities : [],
    creatorType: raw.creatorType || 'admin',
    createdBy: raw.createdBy || null,
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
        ...(data.Jobs          || []).map(r => mapListing('Jobs', r)),
        ...(data.Services      || []).map(r => mapListing('Services', r)),
        ...(data['Second Hand Store'] || []).map(r => mapListing('Second Hand Store', r)),
        ...(data.Events        || []).map(r => mapListing('Events', r)),
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
    const isApprove = status === 'active' || status === 'Active';
    setSaving(`${listing.category}-${listing.id}-${isApprove ? 'approve' : 'reject'}`);
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
    } catch (e) {
      alert(e.message);
    } finally {
      setSaving(null);
    }
  };

  const handleSaveListing = async (listing, editedPayload, finalStatus) => {
    const statusLower = String(finalStatus).toLowerCase();
    setSaving(`${listing.category}-${listing.id}-${statusLower === 'active' ? 'approve' : 'save'}`);
    try {
      const res = await fetch(DELETE_URLS[listing.category](listing.id), {
        method: 'PUT',
        headers: authHeaders(),
        body: JSON.stringify(editedPayload),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.message || 'Failed to save listing changes');
      }

      // After saving data, update the status if needed
      if (statusLower === 'active') {
        await updateStatus(listing, finalStatus);
      } else {
        await fetchPending();
      }
    } catch (e) {
      alert('Save error: ' + e.message);
    } finally {
      setSaving(null);
    }
  };

  const handleApprove = (listing) => updateStatus(listing, listing.category === 'Jobs' ? 'Active' : 'active');

  const handleReject = async (listing) => {
    setSaving(`${listing.category}-${listing.id}-reject`);
    try {
      if (listing.creatorType === 'user') {
        await updateStatus(listing, 'Rejected');
      } else {
        const res = await fetch(DELETE_URLS[listing.category](listing.id), {
          method: 'DELETE',
          headers: authHeaders(),
        });
        if (!res.ok) {
          const e2 = await res.json().catch(() => ({}));
          throw new Error(e2.message || 'Failed to delete');
        }
        await fetchPending();
      }
    } catch (e) { 
      alert(e.message); 
    } finally {
      setSaving(null);
    }
  };

  const filteredListings = pendingListings.filter((l) => {
    if (categoryFilter !== 'all' && l.category !== categoryFilter) return false;
    if (creatorFilter === 'user' && l.creatorType !== 'user' && !l.createdBy) return false;
    if (creatorFilter === 'admin' && (l.creatorType === 'user' || l.createdBy)) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const matchesTitle = (l.title || '').toLowerCase().includes(q);
      const matchesLocation = (l.location || '').toLowerCase().includes(q);
      const matchesCreator = (l.createdBy?.name || '').toLowerCase().includes(q);
      if (!matchesTitle && !matchesLocation && !matchesCreator) return false;
    }
    return true;
  });

  const totalPages = Math.max(1, Math.ceil(filteredListings.length / pageSize));
  const safeCurrentPage = Math.min(currentPage, totalPages);
  const startIndex = (safeCurrentPage - 1) * pageSize;
  const paginatedListings = filteredListings.slice(startIndex, startIndex + pageSize);

  return (
    <div className="content-moderation">
      <div className="moderation-header">
        <div>
          <h1>Content Moderation</h1>
          <p>Review and approve pending listings ({pendingListings.length} total pending).</p>
        </div>
      </div>

      {/* Filter and Limit Toolbar */}
      <div style={{
        display: 'flex',
        gap: '12px',
        alignItems: 'center',
        flexWrap: 'wrap',
        marginBottom: '20px',
        background: '#fff',
        padding: '12px 16px',
        borderRadius: '10px',
        border: '1px solid #e5e7eb',
        boxShadow: '0 1px 3px rgba(0,0,0,0.04)'
      }}>
        {/* Search */}
        <input
          type="text"
          placeholder="Search by title, city, user..."
          value={searchQuery}
          onChange={(e) => { setSearchQuery(e.target.value); setCurrentPage(1); }}
          style={{
            padding: '8px 12px',
            borderRadius: '6px',
            border: '1px solid #d1d5db',
            fontSize: '13px',
            minWidth: '220px',
            flex: '1'
          }}
        />

        {/* Category Filter */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          <span style={{ fontSize: '13px', fontWeight: '600', color: '#4b5563' }}>Category:</span>
          <select
            value={categoryFilter}
            onChange={(e) => { setCategoryFilter(e.target.value); setCurrentPage(1); }}
            style={{
              padding: '8px 10px',
              borderRadius: '6px',
              border: '1px solid #d1d5db',
              fontSize: '13px',
              background: '#fff'
            }}
          >
            <option value="all">All Categories</option>
            <option value="Accommodation">Accommodation</option>
            <option value="Jobs">Jobs</option>
            <option value="Services">Services</option>
            <option value="Second Hand Store">Second Hand Store</option>
            <option value="Events">Events</option>
          </select>
        </div>

        {/* Creator Type Filter */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          <span style={{ fontSize: '13px', fontWeight: '600', color: '#4b5563' }}>Origin:</span>
          <select
            value={creatorFilter}
            onChange={(e) => { setCreatorFilter(e.target.value); setCurrentPage(1); }}
            style={{
              padding: '8px 10px',
              borderRadius: '6px',
              border: '1px solid #d1d5db',
              fontSize: '13px',
              background: '#fff'
            }}
          >
            <option value="all">All (User & Admin)</option>
            <option value="user">👤 User Submitted Only</option>
            <option value="admin">🛡️ Admin Created Only</option>
          </select>
        </div>

        {/* Page Size Filter */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          <span style={{ fontSize: '13px', fontWeight: '600', color: '#4b5563' }}>Per page:</span>
          <select
            value={pageSize}
            onChange={(e) => { setPageSize(Number(e.target.value)); setCurrentPage(1); }}
            style={{
              padding: '8px 10px',
              borderRadius: '6px',
              border: '1px solid #d1d5db',
              fontSize: '13px',
              background: '#fff'
            }}
          >
            <option value={5}>5</option>
            <option value={10}>10</option>
            <option value={20}>20</option>
            <option value={50}>50</option>
          </select>
        </div>

        {(categoryFilter !== 'all' || creatorFilter !== 'all' || searchQuery.trim()) && (
          <button
            onClick={() => {
              setCategoryFilter('all');
              setCreatorFilter('all');
              setSearchQuery('');
              setCurrentPage(1);
            }}
            style={{
              padding: '7px 12px',
              fontSize: '12px',
              color: '#ef4444',
              background: '#fee2e2',
              border: 'none',
              borderRadius: '6px',
              cursor: 'pointer',
              fontWeight: '600'
            }}
          >
            Reset Filters
          </button>
        )}
      </div>

      <div className="pending-listings">
        {loading ? (
          <SkeletonLoader rows={3} columns={5} type="list" />
        ) : filteredListings.length === 0 ? (
          <div style={{ padding: 40, textAlign: 'center', background: '#fff', borderRadius: '10px', border: '1px solid #e5e7eb', color: '#6b7280' }}>
            {pendingListings.length === 0 ? 'No pending listings to review.' : 'No listings match your selected filters.'}
          </div>
        ) : paginatedListings.map((listing) => (
          <div key={listing.id} className="listing-card">
            <div className="listing-image">
              {listing.image ? (
                <img src={listing.image} alt={listing.title} />
              ) : (
                <div style={{ width: '100%', height: '100%', background: '#f3f4f6', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22 }}>📷</div>
              )}
            </div>
            <div className="listing-details">
              <div className="listing-header" style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                <h3 style={{ margin: 0 }}>{listing.title}</h3>
                <span className="listing-category">{listing.category}</span>
                {(listing.creatorType === 'user' || listing.createdBy) ? (
                  <span style={{ fontSize: 11, background: '#e0f2fe', color: '#0369a1', padding: '2px 8px', borderRadius: 12, fontWeight: 'bold' }}>
                    👤 User: {listing.createdBy?.name || 'User'}
                  </span>
                ) : (
                  <span style={{ fontSize: 11, background: '#fef3c7', color: '#92400e', padding: '2px 8px', borderRadius: 12, fontWeight: 'bold' }}>
                    🛡️ Admin
                  </span>
                )}
              </div>
              <div className="listing-info">
                <div className="info-row">
                  {listing.category !== 'Second Hand Store' && <span className="info-label">Location</span>}
                  <span className="info-label">Contact</span>
                </div>
                <div className="info-row">
                  {listing.category !== 'Second Hand Store' && <span className="info-value">{listing.location || '—'}</span>}
                  <span className="info-value">{listing.contact || '—'}</span>
                </div>
              </div>
            </div>
            <div className="listing-actions-vertical">
              <button className="action-btn view-btn" disabled={saving !== null} onClick={() => { setSelectedListing(listing); setShowReviewModal(true); }}>
                <Edit size={16} /> Edit
              </button>
              <button className="action-btn approve-btn" disabled={saving !== null} onClick={() => handleApprove(listing)}>
                <Check size={16} /> {saving === `${listing.category}-${listing.id}-approve` ? 'Approving...' : 'Approve'}
              </button>
              <button className="action-btn reject-btn" disabled={saving !== null} onClick={() => handleReject(listing)}>
                <X size={16} /> {saving === `${listing.category}-${listing.id}-reject` ? 'Rejecting...' : 'Reject'}
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Pagination Controls */}
      {filteredListings.length > pageSize && (
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginTop: '20px',
          padding: '12px 16px',
          background: '#fff',
          borderRadius: '8px',
          border: '1px solid #e5e7eb'
        }}>
          <span style={{ fontSize: '13px', color: '#6b7280' }}>
            Showing {startIndex + 1} to {Math.min(startIndex + pageSize, filteredListings.length)} of {filteredListings.length} listings
          </span>
          <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
            <button
              disabled={safeCurrentPage <= 1}
              onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
              style={{
                padding: '6px 14px',
                borderRadius: '6px',
                border: '1px solid #d1d5db',
                background: safeCurrentPage <= 1 ? '#f3f4f6' : '#fff',
                color: safeCurrentPage <= 1 ? '#9ca3af' : '#374151',
                cursor: safeCurrentPage <= 1 ? 'not-allowed' : 'pointer',
                fontWeight: '600',
                fontSize: '13px'
              }}
            >
              Previous
            </button>
            <span style={{ fontSize: '13px', fontWeight: '600', color: '#374151', padding: '0 8px' }}>
              Page {safeCurrentPage} of {totalPages}
            </span>
            <button
              disabled={safeCurrentPage >= totalPages}
              onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
              style={{
                padding: '6px 14px',
                borderRadius: '6px',
                border: '1px solid #d1d5db',
                background: safeCurrentPage >= totalPages ? '#f3f4f6' : '#fff',
                color: safeCurrentPage >= totalPages ? '#9ca3af' : '#374151',
                cursor: safeCurrentPage >= totalPages ? 'not-allowed' : 'pointer',
                fontWeight: '600',
                fontSize: '13px'
              }}
            >
              Next
            </button>
          </div>
        </div>
      )}

      {showReviewModal && selectedListing && (
        <ReviewListingModal
          listing={selectedListing}
          onClose={() => setShowReviewModal(false)}
          saving={saving ? (saving.includes('-approve') ? 'active' : 'pending') : null}
          onApprove={async (editedPayload) => {
            const status = selectedListing.category === 'Jobs' ? 'Active' : 'active';
            await handleSaveListing(selectedListing, editedPayload, status);
            setShowReviewModal(false);
          }}
          onSavePending={async (editedPayload) => {
            const status = selectedListing.category === 'Jobs' ? 'Pending' : 'pending';
            await handleSaveListing(selectedListing, editedPayload, status);
            setShowReviewModal(false);
          }}
          onReject={() => { handleReject(selectedListing); setShowReviewModal(false); }}
        />
      )}
    </div>
  );
};

export default ContentModeration;