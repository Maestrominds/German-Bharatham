import React, { useState, useEffect } from 'react';
import { Plus, Trash2 } from 'lucide-react';
import SkeletonLoader from './SkeletonLoader';
import AddListingModal from './AddListingModal';
import API_URL from '../config';

const APIS = {
  Accommodation: { get: `${API_URL}/api/accommodation/admin?limit=100`, patch: (id) => `${API_URL}/api/accommodation/admin/${id}/status`, del: (id) => `${API_URL}/api/accommodation/admin/${id}`, titleKey: 'title' },
  Food:          { get: `${API_URL}/api/admin/foodgrocery?limit=100`,   patch: (id) => `${API_URL}/api/admin/foodgrocery/${id}/status`,  del: (id) => `${API_URL}/api/admin/foodgrocery/${id}`,  titleKey: 'title' },
  Jobs:          { get: `${API_URL}/api/jobs/admin?limit=100`,          patch: (id) => `${API_URL}/api/jobs/admin/${id}/status`,         del: (id) => `${API_URL}/api/jobs/admin/${id}`,         titleKey: 'title' },
  Services:      { get: `${API_URL}/api/services/admin?limit=100`,      patch: (id) => `${API_URL}/api/services/admin/${id}/status`,     del: (id) => `${API_URL}/api/services/admin/${id}`,     titleKey: 'serviceName' },
};

const STATUS_COLORS = {
  active:   { bg: '#d1fae5', color: '#065f46' },
  pending:  { bg: '#fef3c7', color: '#92400e' },
  inactive: { bg: '#fee2e2', color: '#991b1b' },
};

const Listings = () => {
  const [showAddModal, setShowAddModal] = useState(false);
  const [listings, setListings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');

  const handleUnauthorized = () => {
    localStorage.removeItem('adminToken');
    window.location.reload();
  };

  useEffect(() => { fetchAllListings(); }, []);

  const fetchAllListings = async () => {
    setLoading(true);
    const token = localStorage.getItem('adminToken');
    try {
      const res = await fetch(`${API_URL}/api/admin/all-listings`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });

      if (res.status === 401 || res.status === 403) { handleUnauthorized(); return; }
      if (!res.ok) throw new Error(`Failed to fetch: ${res.status}`);

      const data = await res.json();
      console.log('✅ Fetched listings data:', data);

      const mapItems = (items, cat, titleKey) => (items || []).map(item => ({
        _id: item._id,
        title: item[titleKey] || 'Untitled',
        category: cat,
        location: item.location || [item.city, item.area].filter(Boolean).join(', ') || 'N/A',
        status: ((raw) => {
          const s = String(raw || '').toLowerCase();
          if (s === 'active') return 'active';
          if (s === 'pending') return 'pending';
          if (s === 'disabled' || s === 'inactive') return 'inactive';
          return 'inactive';
        })(item.status),
        created: item.createdAt ? new Date(item.createdAt).toLocaleDateString('en-GB') : 'N/A',
      }));

      const all = [
        ...mapItems(data.Accommodation, 'Accommodation', 'title'),
        ...mapItems(data.Food,          'Food',          'title'),
        ...mapItems(data.Jobs,          'Jobs',          'title'),
        ...mapItems(data.Services,      'Services',      'serviceName'),
      ];

      all.sort((a, b) => b.created.localeCompare(a.created));
      setListings(all);
    } catch (e) {
      console.error('❌ Error fetching listings:', e);
      alert('Error loading listings: ' + e.message);
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (item, newStatus) => {
    const conf = APIS[item.category];
    if (!conf) return;
    try {
      const token = localStorage.getItem('adminToken');
      const res = await fetch(conf.patch(item._id), {
        method: 'PATCH',
        headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus })
      });
      if (res.ok) {
        setListings(prev => prev.map(l =>
          l._id === item._id && l.category === item.category ? { ...l, status: newStatus } : l
        ));
      } else { alert('Failed to update status'); }
    } catch (e) { alert('Error: ' + e.message); }
  };

  const handleDelete = async (item) => {
    if (!window.confirm(`Delete "${item.title}"?`)) return;
    const conf = APIS[item.category];
    if (!conf) return;
    try {
      const token = localStorage.getItem('adminToken');
      const res = await fetch(conf.del(item._id), {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (res.ok) {
        setListings(prev => prev.filter(l => !(l._id === item._id && l.category === item.category)));
      } else { alert('Failed to delete'); }
    } catch (e) { alert('Error: ' + e.message); }
  };

  const filtered = listings.filter(l => {
    if (categoryFilter !== 'all' && l.category !== categoryFilter) return false;
    if (statusFilter !== 'all' && l.status !== statusFilter) return false;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      return [l.title, l.category, l.location, l.status].some(v => v && v.toLowerCase().includes(q));
    }
    return true;
  });

  return (
    <div className="listings">
      <div className="listings-header">
        <div>
          <h1>All Listings</h1>
          <p>Manage all listings across every category.</p>
        </div>
        <div className="header-actions">
          <input
            type="text"
            placeholder="Search listings..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            style={{ padding: '8px 12px', borderRadius: 8, border: '1px solid #e5e7eb', fontSize: 14, minWidth: 200 }}
          />
          <select className="filter-select" value={categoryFilter} onChange={e => setCategoryFilter(e.target.value)}>
            <option value="all">All Categories</option>
            <option value="Accommodation">Accommodation</option>
            <option value="Food">Food</option>
            <option value="Jobs">Jobs</option>
            <option value="Services">Services</option>
          </select>
          <select className="filter-select" value={statusFilter} onChange={e => setStatusFilter(e.target.value)}>
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="pending">Pending</option>
            <option value="inactive">Inactive</option>
          </select>
          <button className="add-listing-btn" onClick={() => setShowAddModal(true)}>
            <Plus size={20} /> New Listing
          </button>
        </div>
      </div>

      <div className="listings-table">
        {loading ? (
          <SkeletonLoader rows={5} columns={6} type="table" />
        ) : filtered.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '40px' }}>No listings found.</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>TITLE</th>
                <th>CATEGORY</th>
                <th>LOCATION</th>
                <th>STATUS</th>
                <th>CREATED</th>
                <th>ACTION</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((listing) => {
                const sc = STATUS_COLORS[listing.status] || STATUS_COLORS.inactive;
                return (
                  <tr key={`${listing.category}-${listing._id}`}>
                    <td className="listing-title">{listing.title}</td>
                    <td>{listing.category}</td>
                    <td>{listing.location}</td>
                    <td>
                      <select
                        value={listing.status}
                        onChange={e => handleStatusChange(listing, e.target.value)}
                        style={{
                          background: sc.bg, color: sc.color, border: 'none', borderRadius: 12,
                          padding: '3px 10px', fontSize: 12, fontWeight: 600, cursor: 'pointer'
                        }}
                      >
                        <option value="active">Active</option>
                        <option value="pending">Pending</option>
                        <option value="inactive">Inactive</option>
                      </select>
                    </td>
                    <td>{listing.created}</td>
                    <td>
                      <div className="action-buttons">
                        <button className="action-btn delete-btn" onClick={() => handleDelete(listing)}>
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      {showAddModal && (
        <AddListingModal
          onClose={() => setShowAddModal(false)}
          onSuccess={() => { setShowAddModal(false); fetchAllListings(); }}
        />
      )}
    </div>
  );
};

export default Listings;