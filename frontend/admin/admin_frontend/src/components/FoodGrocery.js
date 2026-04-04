import React, { useState, useEffect } from 'react';
import { Plus, Edit, Trash2, ChevronLeft, ChevronRight, Search, Eye } from 'lucide-react';
import AddFoodGroceryModal from './AddFoodGroceryModal';
import EditFoodGroceryModal from './EditFoodGroceryModal';
import ViewFoodGroceryModal from './ViewFoodGroceryModal';
import SkeletonLoader from './SkeletonLoader';
import API_URL from '../config';

const FoodGrocery = () => {
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showViewModal, setShowViewModal] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);
  const [listings, setListings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('All');
  const [statusFilter, setStatusFilter] = useState('all');
  const [sortBy, setSortBy] = useState('newest');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  // Fetch all food & grocery listings
  const fetchListings = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('adminToken');
      const qs = new URLSearchParams();
      qs.set('page', String(currentPage));
      qs.set('limit', String(itemsPerPage));
      if (statusFilter && statusFilter !== 'all') qs.set('status', statusFilter);
      const url = `${API_URL}/api/admin/foodgrocery?${qs.toString()}`;
      const response = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      if (!response.ok) throw new Error('Failed to fetch listings');
      const data = await response.json();
      // Normalize backend responses (array or paged object)
      if (Array.isArray(data)) setListings(data);
      else if (Array.isArray(data.data)) setListings(data.data);
      else if (Array.isArray(data.items)) setListings(data.items);
      else setListings([]);
      setError(null);
    } catch (err) {
      setError(err.message);
      console.error('Error fetching listings:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchListings();
  }, []);

  // Handle delete
  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this listing?')) return;
    
    try {
      const token = localStorage.getItem('adminToken');
      const response = await fetch(`${API_URL}/api/admin/foodgrocery/${id}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      if (!response.ok) throw new Error('Failed to delete listing');
      
      // Refresh listings
      fetchListings();
    } catch (err) {
      alert('Error deleting listing: ' + err.message);
      console.error('Error deleting:', err);
    }
  };

  // Resolve image URL (prefix API_URL for relative paths)
  const resolveSrc = (src) => {
    if (!src) return null;
    try {
      if (typeof src === 'object') src = src.url || src.src || src.path || '';
      if (!src) return null;
      if (/^(https?:)?\/\//i.test(src) || src.startsWith('data:')) return src;
      const base = String(API_URL).replace(/\/$/, '');
      if (src.startsWith('/')) return base + src;
      return base + '/' + src;
    } catch (e) { return src; }
  };

  // Handle edit - fetch latest item before opening modal
  const handleEdit = async (item) => {
    try {
      const token = localStorage.getItem('adminToken');
      const res = await fetch(`${API_URL}/api/admin/foodgrocery/${item._id}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (res.ok) {
        const fresh = await res.json();
        setSelectedItem(fresh);
      } else {
        setSelectedItem(item);
      }
    } catch (err) {
      console.error('Error fetching item for edit:', err);
      setSelectedItem(item);
    }
    setShowEditModal(true);
  };

  // Handle view - fetch latest item before showing
  const handleView = async (item) => {
    try {
      const token = localStorage.getItem('adminToken');
      const res = await fetch(`${API_URL}/api/admin/foodgrocery/${item._id}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (res.ok) {
        const fresh = await res.json();
        // backend returns item directly for GET /:id
        setSelectedItem(fresh);
      } else {
        setSelectedItem(item);
      }
    } catch (err) {
      console.error('Error fetching item for view:', err);
      setSelectedItem(item);
    }
    setShowViewModal(true);
  };

  // Filter and sort listings
  const getFilteredListings = () => {
    let filtered = [...listings];

    // Search filter - search across multiple fields
    if (searchTerm) {
      const searchLower = searchTerm.toLowerCase();
      filtered = filtered.filter(item =>
        (item.title || item.name || '').toLowerCase().includes(searchLower) ||
        (item.location || '').toLowerCase().includes(searchLower) ||
        (item.city || '').toLowerCase().includes(searchLower) ||
        (item.address || '').toLowerCase().includes(searchLower) ||
        (item.subCategory || item.category || '').toLowerCase().includes(searchLower) ||
        (item.description || '').toLowerCase().includes(searchLower)
      );
    }

    // Category filter
    if (categoryFilter !== 'All') {
      filtered = filtered.filter(item => (item.subCategory || item.category) === categoryFilter);
    }

    // Status filter
    const normalizeStatus = (it) => {
      const s = (it.status ?? (it.verified ? 'active' : undefined) ?? (it.adminControls?.isActive ? 'active' : undefined));
      if (!s) return 'inactive';
      const lower = String(s).toLowerCase();
      if (lower === 'disabled') return 'inactive';
      if (lower === 'pending') return 'pending';
      if (lower === 'verified') return 'active';
      if (lower === 'active') return 'active';
      return lower;
    };

    if (statusFilter !== 'all') {
      filtered = filtered.filter(item => normalizeStatus(item) === statusFilter);
    }

    // Sort
    switch (sortBy) {
      case 'newest':
        filtered.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
        break;
      case 'a-z':
        filtered.sort((a, b) => (a.title || a.name || '').localeCompare(b.title || b.name || ''));
        break;
      case 'z-a':
        filtered.sort((a, b) => (b.title || b.name || '').localeCompare(a.title || a.name || ''));
        break;
      default:
        break;
    }

    return filtered;
  };

  const filteredListings = getFilteredListings();
  const totalPages = Math.ceil(filteredListings.length / itemsPerPage);
  const paginatedListings = filteredListings.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  // Format date
  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-GB', { year: 'numeric', month: '2-digit', day: '2-digit' }).split('/').reverse().join('-');
  };

  return (
    <div className="food-grocery">
      <div className="food-grocery-header">
        <div>
          <h1>Food & Grocery</h1>
          <p>Manage all restaurants and grocery stores in one place.</p>
        </div>
        <button 
          className="add-listing-btn"
          onClick={() => setShowAddModal(true)}
        >
          <Plus size={20} />
          New Listing
        </button>
      </div>

      {/* Search and Filters */}
      <div className="filters-section">
        <div className="search-box">
          <Search size={20} />
          <input
            type="text"
            placeholder="Search food & grocery..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <div className="filter-controls">
          <select
            className="filter-select"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="pending">Pending</option>
            <option value="inactive">Inactive</option>
          </select>
          <select 
            className="filter-select"
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value)}
          >
            <option value="newest">Newest First</option>
            <option value="oldest">Oldest First</option>
            <option value="a-z">A-Z</option>
            <option value="z-a">Z-A</option>
          </select>
          <select 
            className="filter-select"
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
          >
            <option value="All">All Categories</option>
            <option value="Restaurant">Restaurant</option>
            <option value="Grocery Store">Grocery Store</option>
            <option value="Bakery">Bakery</option>
            <option value="Cafe">Cafe</option>
            <option value="Supermarket">Supermarket</option>
          </select>
        </div>
      </div>

      {/* Loading/Error States */}
      {loading && (
        <div className="loading-state">
          <SkeletonLoader rows={5} columns={8} type="table" />
        </div>
      )}

      {error && (
        <div className="error-state">
          <p>Error: {error}</p>
          <button onClick={fetchListings}>Retry</button>
        </div>
      )}

      {/* Listings Table */}
      {!loading && !error && (
        <>
          <div className="food-grocery-table">
            <table>
              <thead>
                <tr>
                  <th>NAME</th>
                  <th>CATEGORY</th>
                  <th>LOCATION</th>
                  <th>CONTACT</th>
                  <th>RATING</th>
                  <th>STATUS</th>
                  <th>CREATED</th>
                  <th>ACTIONS</th>
                </tr>
              </thead>
              <tbody>
                {paginatedListings.length === 0 ? (
                  <tr>
                    <td colSpan="8" className="no-data">
                      No listings found. Click "New Listing" to add one.
                    </td>
                  </tr>
                ) : (
                  paginatedListings.map((item) => (
                    <tr key={item._id}>
                      <td className="listing-title">
                        <div className="title-with-image">
                          {(() => {
                            const raw = item.image || item.companyLogo || item.media?.images?.[0] || item.images?.[0] || null;
                            const img = resolveSrc(raw);
                            return img ? (
                              <img src={img} alt={item.title || item.name} className="listing-thumbnail" />
                            ) : null;
                          })()}
                          <span>{item.title || item.name}</span>
                        </div>
                      </td>
                      <td>
                        <span className="category-badge">{item.subCategory || item.category}</span>
                      </td>
                      <td className="location-cell">
                        {item.city ? `${item.city}${item.address ? ', ' + item.address.substring(0, 20) + '...' : ''}` : item.address}
                      </td>
                      <td>{item.phone || '-'}</td>
                      <td>
                        <div className="rating-cell">
                          <span className="rating-star">⭐</span>
                          {item.rating ? item.rating.toFixed(1) : '0.0'}
                        </div>
                      </td>
                      <td>
                        <span className={`status ${item.verified ? 'active' : 'inactive'}`}>
                          {item.verified ? 'Active' : 'Inactive'}
                        </span>
                      </td>
                      <td>{formatDate(item.createdAt)}</td>
                      <td>
                        <div className="action-buttons">
                          <button 
                            className="action-btn view-btn"
                            onClick={() => handleView(item)}
                            title="View Details"
                          >
                            <Eye size={16} />
                          </button>
                          <button 
                            className="action-btn edit-btn"
                            onClick={() => handleEdit(item)}
                            title="Edit"
                          >
                            <Edit size={16} />
                          </button>
                          <button 
                            className="action-btn delete-btn"
                            onClick={() => handleDelete(item._id)}
                            title="Delete"
                          >
                            <Trash2 size={16} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {filteredListings.length > 0 && (
            <div className="pagination">
              <div className="pagination-info">
                Showing {((currentPage - 1) * itemsPerPage) + 1}-{Math.min(currentPage * itemsPerPage, filteredListings.length)} of {filteredListings.length} results
              </div>
              <div className="pagination-controls">
                <button 
                  className="pagination-btn"
                  onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                  disabled={currentPage === 1}
                >
                  <ChevronLeft size={16} />
                </button>
                {[...Array(Math.min(5, totalPages))].map((_, idx) => {
                  let pageNum;
                  if (totalPages <= 5) {
                    pageNum = idx + 1;
                  } else if (currentPage <= 3) {
                    pageNum = idx + 1;
                  } else if (currentPage >= totalPages - 2) {
                    pageNum = totalPages - 4 + idx;
                  } else {
                    pageNum = currentPage - 2 + idx;
                  }
                  
                  return (
                    <button
                      key={idx}
                      className={`pagination-btn ${currentPage === pageNum ? 'active' : ''}`}
                      onClick={() => setCurrentPage(pageNum)}
                    >
                      {pageNum}
                    </button>
                  );
                })}
                <button 
                  className="pagination-btn"
                  onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
                  disabled={currentPage === totalPages}
                >
                  <ChevronRight size={16} />
                </button>
              </div>
            </div>
          )}
        </>
      )}

      {/* Modals */}
      {showAddModal && (
        <AddFoodGroceryModal 
          onClose={() => setShowAddModal(false)}
          onSuccess={() => {
            setShowAddModal(false);
            fetchListings();
          }}
        />
      )}

      {showEditModal && selectedItem && (
        <EditFoodGroceryModal 
          item={selectedItem}
          onClose={() => {
            setShowEditModal(false);
            setSelectedItem(null);
          }}
            onSuccess={(updated) => {
              // close modal
              setShowEditModal(false);
              setSelectedItem(null);
              try {
                console.debug('FoodGrocery onSuccess payload:', updated);
                // Normalize updated item whether backend returns {data: [...]}, {item: ...} or item directly
                let updatedItem = updated;
                // handle common wrapper shapes
                if (!updatedItem) updatedItem = null;
                // { data: [...] }
                else if (Array.isArray(updatedItem.data)) updatedItem = updatedItem.data[0];
                else if (updatedItem.data) updatedItem = updatedItem.data;
                // { item: {...} }
                else if (updatedItem.item) updatedItem = updatedItem.item;
                // { value: {...} } (some drivers)
                else if (updatedItem.value) updatedItem = updatedItem.value;
                // mongoose doc wrapper
                else if (updatedItem._doc) updatedItem = updatedItem._doc;

                if (updatedItem && (updatedItem._id || updatedItem.id)) {
                  const id = String(updatedItem._id || updatedItem.id);
                  setListings(prev => prev.map(it => (String(it._id) === id ? { ...it, ...updatedItem } : it)));
                }
              } catch (e) {
                console.error('Error applying optimistic update:', e);
              }
              // refresh from server to ensure canonical state
              fetchListings();
            }}
        />
      )}

      {showViewModal && selectedItem && (
        <ViewFoodGroceryModal 
          item={selectedItem}
          onClose={() => {
            setShowViewModal(false);
            setSelectedItem(null);
          }}
          onEdit={() => {
            setShowViewModal(false);
            setShowEditModal(true);
          }}
        />
      )}
    </div>
  );
};

export default FoodGrocery;
