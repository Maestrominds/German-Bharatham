import React, { useState, useEffect, useCallback } from 'react';
import { Plus, Edit, Trash2, ArrowLeft, Eye } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import AddAccommodationModal from './AddAccommodationModal';
import ViewAccommodationModal from './ViewAccommodationModal';
import EditAccommodationModal from './EditAccommodationModal';
import SkeletonLoader from './SkeletonLoader';
import API_URL from '../config';

const API = `${API_URL}/api/accommodation/admin`;

const STATUS_COLORS = {
  active:   { bg: '#d1fae5', color: '#065f46' },
  inactive: { bg: '#fee2e2', color: '#991b1b' },
  pending:  { bg: '#fef3c7', color: '#92400e' },
};

const AccommodationListings = () => {
  const navigate = useNavigate();
  const [accommodations, setAccommodations] = useState([]);
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editItem, setEditItem] = useState(null);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({ count: 0, activeCount: 0 });
  const [selectedAccommodation, setSelectedAccommodation] = useState(null);
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  const [totalCount, setTotalCount] = useState(0);
  const [statusFilter, setStatusFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');

  const fetchAccommodations = useCallback(async (p = 1) => {
    setLoading(true);
    try {
      const token = localStorage.getItem('adminToken');
      // Pass status filter to API for server-side filtering instead of fetching all and filtering client-side
      const queryParams = new URLSearchParams({ page: p, limit });
      if (statusFilter !== 'all') {
        queryParams.append('status', statusFilter === 'inactive' ? 'disabled' : statusFilter);
      }
      const response = await fetch(`${API}?${queryParams.toString()}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (response.ok) {
        const result = await response.json();
        setAccommodations(result.data || []);
        setStats({ count: result.count || 0, activeCount: result.activeCount || 0 });
        setTotalCount(result.totalCount || 0);
      } else {
        alert('Failed to fetch accommodations');
      }
    } catch (error) {
      console.error('Error:', error);
      alert('Error connecting to server');
    } finally {
      setLoading(false);
    }
  }, [limit, statusFilter]);

  useEffect(() => { fetchAccommodations(page); }, [page, fetchAccommodations]);

  const handleDelete = async (id, title) => {
    if (!window.confirm(`Delete "${title}"?`)) return;
    try {
      const token = localStorage.getItem('adminToken');
      const res = await fetch(`${API}/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (res.ok) { fetchAccommodations(); }
      else { alert('Failed to delete'); }
    } catch (e) { alert('Error: ' + e.message); }
  };

  const handleStatusChange = async (id, newStatus) => {
    try {
      const token = localStorage.getItem('adminToken');
      const res = await fetch(`${API}/${id}/status`, {
        method: 'PATCH',
        headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus })
      });
      if (res.ok) {
        setAccommodations(prev => prev.map(a =>
          a._id === id ? { ...a, status: newStatus, adminControls: { ...a.adminControls, isActive: newStatus === 'active' } } : a
        ));
      } else { alert('Failed to update status'); }
    } catch (e) { alert('Error: ' + e.message); }
  };

  const formatDate = (d) => d ? new Date(d).toLocaleDateString('en-GB') : 'N/A';

  const formatPrice = (a) => {
    if (a.rentDetails?.warmRent) return `€${a.rentDetails.warmRent}/mo`;
    if (a.rentDetails?.coldRent)  return `€${a.rentDetails.coldRent}/mo`;
    return 'N/A';
  };

  const normalizeStatus = s => {
    if (s === 'disabled') return 'inactive';
    if (s === 'pending') return 'pending';
    return s || 'inactive';
  };

  const filtered = (statusFilter === 'all'
    ? accommodations
    : accommodations.filter(a => normalizeStatus(a.status || (a.adminControls?.isActive ? 'active' : 'inactive')) === statusFilter)
  ).filter(a => {
    if (!searchQuery) return true;
    const q = searchQuery.toLowerCase();
    return [a.title, a.propertyType, a.city, a.area, a.status].some(v => v && v.toLowerCase().includes(q));
  });

  return (
    <div className="listings">
      <div className="listings-header">
        <div>
          <button
            onClick={() => navigate('/categories')}
            style={{ 
              background: '#2d5a3d', 
              border: 'none', 
              color: '#fff', 
              cursor: 'pointer', 
              display: 'flex', 
              alignItems: 'center', 
              gap: 6, 
              marginBottom: 8, 
              fontSize: 14,
              padding: '8px 16px',
              borderRadius: 8,
              fontWeight: 500,
              transition: 'all 0.2s'
            }}
            onMouseEnter={(e) => e.currentTarget.style.background = '#234a31'}
            onMouseLeave={(e) => e.currentTarget.style.background = '#2d5a3d'}
          >
            <ArrowLeft size={16} /> Back to Categories
          </button>
          <h1>🏠 Accommodation Listings</h1>
          <p>Showing {stats.count} of {totalCount || stats.count}</p>
        </div>
        <div className="header-actions" style={{ display:'flex', gap:10, alignItems:'center' }}>
          <input
            type="text"
            placeholder="Search accommodations..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            style={{ padding:'8px 12px', borderRadius:8, border:'1px solid #e5e7eb', fontSize:14, minWidth:200 }}
          />
          <select
            value={statusFilter}
            onChange={e => setStatusFilter(e.target.value)}
            style={{ padding:'8px 12px', borderRadius:8, border:'1px solid #e5e7eb', fontSize:14, cursor:'pointer' }}
          >
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="pending">Pending</option>
            <option value="inactive">Inactive</option>
          </select>
          <button className="add-listing-btn" onClick={() => setShowAddModal(true)}>
            <Plus size={20} /> New Accommodation
          </button>
        </div>
      </div>

      {/* Pagination controls */}
      <div style={{ display:'flex', justifyContent:'flex-end', gap:8, alignItems:'center', padding:'8px 0' }}>
        <button
          onClick={() => setPage(p => Math.max(1, p - 1))}
          disabled={page === 1}
          style={{ padding: '6px 10px', borderRadius:6, cursor: page===1 ? 'not-allowed' : 'pointer' }}
        >Prev</button>
        <div style={{ fontSize:14, color:'#374151' }}>Page {page} • {totalCount} items</div>
        <button
          onClick={() => setPage(p => p + 1)}
          disabled={page * limit >= totalCount}
          style={{ padding: '6px 10px', borderRadius:6, cursor: page * limit >= totalCount ? 'not-allowed' : 'pointer' }}
        >Next</button>
      </div>

      {loading ? (
        <SkeletonLoader rows={5} columns={8} type="table" />
      ) : filtered.length === 0 ? (
        <div style={{ textAlign:'center', padding:'40px' }}>
          <p>No accommodations found.</p>
        </div>
      ) : (
        <div className="listings-table">
          <table>
            <thead>
              <tr>
                <th>IMAGE</th>
                <th>TITLE</th>
                <th>TYPE</th>
                <th>LOCATION</th>
                <th>PRICE</th>
                <th>STATUS</th>
                <th>CREATED</th>
                <th>ACTION</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((a) => {
                const st = normalizeStatus(a.status || (a.adminControls?.isActive ? 'active' : 'inactive'));
                const sc = STATUS_COLORS[st] || STATUS_COLORS.inactive;
                return (
                  <tr key={a._id}>
                    <td>
                      {a.media?.images?.[0]
                        ? <img src={a.media.images[0]} alt=""
                            style={{ width: 56, height: 44, objectFit: 'cover', borderRadius: 6, border: '1px solid #e5e7eb' }} />
                        : <div style={{ width: 56, height: 44, background: '#f3f4f6', borderRadius: 6, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18 }}>🏠</div>
                      }
                    </td>
                    <td className="listing-title">{a.title || 'Untitled'}</td>
                    <td>{a.propertyType || 'N/A'}</td>
                    <td>{a.city || 'N/A'}{a.area ? `, ${a.area}` : ''}</td>
                    <td>{formatPrice(a)}</td>
                    <td>
                      <select
                        value={st}
                        onChange={e => handleStatusChange(a._id, e.target.value)}
                        style={{ background: sc.bg, color: sc.color, border:'none', borderRadius:12,
                          padding:'3px 10px', fontSize:12, fontWeight:600, cursor:'pointer' }}
                      >
                        <option value="active">Active</option>
                        <option value="pending">Pending</option>
                        <option value="inactive">Inactive</option>
                      </select>
                    </td>
                    <td>{formatDate(a.createdAt)}</td>
                    <td>
                      <div className="action-buttons">
                        <button className="action-btn" title="View" onClick={() => setSelectedAccommodation(a)} style={{ color:'#6b9976' }}>
                          <Eye size={16} />
                        </button>
                        <button className="action-btn" title="Edit" onClick={() => { setEditItem(a); setShowEditModal(true); }} style={{ color:'#3b82f6' }}>
                          <Edit size={16} />
                        </button>
                        <button className="action-btn delete-btn" title="Delete" onClick={() => handleDelete(a._id, a.title)}>
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {showAddModal && (
        <AddAccommodationModal
          onClose={() => setShowAddModal(false)}
          onSuccess={fetchAccommodations}
        />
      )}

      {showEditModal && editItem && (
        <EditAccommodationModal
          accommodation={editItem}
          onClose={() => { setShowEditModal(false); setEditItem(null); }}
          onSuccess={() => { setShowEditModal(false); setEditItem(null); fetchAccommodations(); }}
        />
      )}

      {selectedAccommodation && (
        <ViewAccommodationModal
          accommodation={selectedAccommodation}
          onClose={() => setSelectedAccommodation(null)}
        />
      )}
    </div>
  );
};

export default AccommodationListings;
