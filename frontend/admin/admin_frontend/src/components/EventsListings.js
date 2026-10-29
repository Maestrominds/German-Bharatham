import React, { useState, useEffect, useCallback } from 'react';
import { Plus, Edit, Trash2, ArrowLeft, Eye, Calendar, MapPin } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import AddEventModal from './AddEventModal';
import ViewEventModal from './ViewEventModal';
import EditEventModal from './EditEventModal';
import SkeletonLoader from './SkeletonLoader';
import API_URL from '../config';

const API = `${API_URL}/api/events/admin`;

const STATUS_COLORS = {
  active:   { bg: '#d1fae5', color: '#065f46' },
  inactive: { bg: '#fee2e2', color: '#991b1b' },
  pending:  { bg: '#fef3c7', color: '#92400e' },
};

const EventsListings = () => {
  const navigate = useNavigate();
  const [events, setEvents] = useState([]);
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editItem, setEditItem] = useState(null);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({ count: 0, activeCount: 0 });
  const [selectedEvent, setSelectedEvent] = useState(null);
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  const [totalCount, setTotalCount] = useState(0);
  const [statusFilter, setStatusFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');

  const fetchEvents = useCallback(async (p = 1) => {
    setLoading(true);
    try {
      const token = localStorage.getItem('adminToken');
      const queryParams = new URLSearchParams({ page: p, limit });
      if (statusFilter !== 'all') {
        queryParams.append('status', statusFilter === 'inactive' ? 'disabled' : statusFilter);
      }
      const response = await fetch(`${API}?${queryParams.toString()}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (response.ok) {
        const result = await response.json();
        const data = result.data || [];
        setEvents(data);
        const activeCount = data.filter(
          (d) => String(d.status).toLowerCase() === 'active'
        ).length;
        setStats({ count: result.totalCount || result.count || 0, activeCount });
        setTotalCount(result.totalCount || result.count || 0);
      } else {
        alert('Failed to fetch events');
      }
    } catch (error) {
      console.error('Error fetching events:', error);
      alert('Error connecting to server');
    } finally {
      setLoading(false);
    }
  }, [limit, statusFilter]);

  useEffect(() => {
    fetchEvents(page);
  }, [page, fetchEvents]);

  const handleDelete = async (id, title) => {
    if (!window.confirm(`Delete event "${title}"?`)) return;
    try {
      const token = localStorage.getItem('adminToken');
      const res = await fetch(`${API}/${id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        fetchEvents(page);
      } else {
        alert('Failed to delete event');
      }
    } catch (e) {
      alert('Error: ' + e.message);
    }
  };

  const handleStatusChange = async (id, newStatus) => {
    try {
      const token = localStorage.getItem('adminToken');
      const res = await fetch(`${API}/${id}/status`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ status: newStatus }),
      });
      if (res.ok) {
        setEvents((prev) =>
          prev.map((e) =>
            e._id === id || e.id === id ? { ...e, status: newStatus } : e
          )
        );
      } else {
        alert('Failed to update event status');
      }
    } catch (e) {
      alert('Error: ' + e.message);
    }
  };

  const formatDate = (d) => {
    if (!d) return 'N/A';
    try {
      return new Date(d).toLocaleDateString('en-GB', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
      });
    } catch {
      return 'N/A';
    }
  };

  const normalizeStatus = (s) => {
    const raw = String(s || '').toLowerCase();
    if (raw === 'active') return 'active';
    if (raw === 'pending') return 'pending';
    return 'inactive';
  };

  const filteredEvents = events.filter((e) => {
    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase();
    return (
      (e.title && e.title.toLowerCase().includes(q)) ||
      (e.city && e.city.toLowerCase().includes(q)) ||
      (e.organizer && e.organizer.toLowerCase().includes(q)) ||
      (e.venue && e.venue.toLowerCase().includes(q))
    );
  });

  const totalPages = Math.ceil(totalCount / limit);

  return (
    <div className="accommodation-listings">
      {/* Top Navigation */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
        <button
          onClick={() => navigate('/categories')}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 6,
            background: 'none',
            border: 'none',
            cursor: 'pointer',
            color: '#6b9976',
            fontSize: 14,
            fontWeight: 600,
            padding: '4px 0',
          }}
        >
          <ArrowLeft size={16} /> Categories
        </button>
      </div>

      {/* Header and Actions */}
      <div className="page-header">
        <div>
          <h1>🎉 Events Listings</h1>
          <p>Manage community events, cultural festivals, meetups, and workshops.</p>
        </div>

        <div className="header-actions">
          <input
            type="text"
            placeholder="Search events, cities, organizers..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{
              padding: '8px 12px',
              borderRadius: 8,
              border: '1px solid #e5e7eb',
              fontSize: 14,
              minWidth: 220,
            }}
          />

          <select
            className="filter-select"
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value);
              setPage(1);
            }}
          >
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="pending">Pending</option>
            <option value="inactive">Inactive</option>
          </select>

          <button className="add-listing-btn" onClick={() => setShowAddModal(true)}>
            <Plus size={20} /> New Event
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="stats-row">
        <div className="stat-card">
          <span className="stat-label">Total Events</span>
          <span className="stat-value">{stats.count}</span>
        </div>
        <div className="stat-card">
          <span className="stat-label">Active Events</span>
          <span className="stat-value">{stats.activeCount}</span>
        </div>
      </div>

      {/* Events Table */}
      <div className="listings-table-container">
        {loading ? (
          <SkeletonLoader count={5} />
        ) : filteredEvents.length === 0 ? (
          <p style={{ textAlign: 'center', padding: '40px 0', color: '#6b7280' }}>
            No events found.
          </p>
        ) : (
          <table className="listings-table">
            <thead>
              <tr>
                <th>Event</th>
                <th>Category</th>
                <th>City & Venue</th>
                <th>Date & Time</th>
                <th>Price</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredEvents.map((item) => {
                const normStatus = normalizeStatus(item.status);
                const statusStyle = STATUS_COLORS[normStatus] || STATUS_COLORS.inactive;
                const img = Array.isArray(item.images) && item.images.length > 0 ? item.images[0] : null;

                return (
                  <tr key={item._id || item.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        {img ? (
                          <img
                            src={img}
                            alt=""
                            style={{
                              width: 44,
                              height: 44,
                              borderRadius: 8,
                              objectFit: 'cover',
                              flexShrink: 0,
                            }}
                          />
                        ) : (
                          <div
                            style={{
                              width: 44,
                              height: 44,
                              borderRadius: 8,
                              background: '#f3f4f6',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              flexShrink: 0,
                            }}
                          >
                            <Calendar size={20} color="#9ca3af" />
                          </div>
                        )}
                        <div>
                          <div style={{ fontWeight: 600, color: '#111827', fontSize: 14, display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: 4 }}>
                            <span>{item.title}</span>
                            {item.isOnline && (
                              <span style={{ fontSize: 10, background: '#ede9fe', color: '#6d28d9', padding: '2px 6px', borderRadius: 4, fontWeight: 600 }}>ONLINE</span>
                            )}
                            {item.format && item.format !== 'one_day' && (
                              <span style={{ fontSize: 10, background: '#e0f2fe', color: '#0369a1', padding: '2px 6px', borderRadius: 4, fontWeight: 600, textTransform: 'uppercase' }}>{item.format.replace('_', ' ')}</span>
                            )}
                          </div>
                          {item.organizer && (
                            <div style={{ fontSize: 12, color: '#6b7280' }}>
                              by {item.organizer}
                            </div>
                          )}
                        </div>
                      </div>
                    </td>
                    <td>
                      <span
                        style={{
                          background: '#f3f4f6',
                          color: '#374151',
                          padding: '3px 8px',
                          borderRadius: 12,
                          fontSize: 12,
                          fontWeight: 500,
                          textTransform: 'capitalize',
                        }}
                      >
                        {item.category || 'Event'}
                      </span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 13 }}>
                        <MapPin size={14} color="#9ca3af" />
                        <span>{item.isOnline ? 'Online' : ([item.city, item.venue].filter(Boolean).join(' • ') || 'N/A')}</span>
                      </div>
                    </td>
                    <td style={{ fontSize: 13, color: '#374151' }}>
                      <div>{item.cardDateLabel || formatDate(item.startsAt)}</div>
                      {item.timeText && !item.cardDateLabel && <div style={{ fontSize: 11, color: '#6b7280' }}>{item.timeText}</div>}
                    </td>
                    <td style={{ fontSize: 13, fontWeight: 600, color: '#065f46' }}>
                      {item.priceText || item.price || (item.priceType === 'free' ? 'Free' : 'N/A')}
                    </td>
                    <td>
                      <select
                        value={normStatus}
                        onChange={(e) =>
                          handleStatusChange(item._id || item.id, e.target.value)
                        }
                        style={{
                          backgroundColor: statusStyle.bg,
                          color: statusStyle.color,
                          border: 'none',
                          borderRadius: '12px',
                          padding: '4px 10px',
                          fontWeight: '600',
                          fontSize: '12px',
                          cursor: 'pointer',
                        }}
                      >
                        <option value="active">Active</option>
                        <option value="pending">Pending</option>
                        <option value="inactive">Inactive</option>
                      </select>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: 6 }}>
                        <button
                          className="action-btn"
                          title="View"
                          onClick={() => setSelectedEvent(item)}
                          style={{ color: '#6b9976' }}
                        >
                          <Eye size={18} />
                        </button>
                        <button
                          className="action-btn"
                          title="Edit"
                          onClick={() => {
                            setEditItem(item);
                            setShowEditModal(true);
                          }}
                          style={{ color: '#2563eb' }}
                        >
                          <Edit size={18} />
                        </button>
                        <button
                          className="action-btn"
                          title="Delete"
                          onClick={() =>
                            handleDelete(item._id || item.id, item.title)
                          }
                          style={{ color: '#ef4444' }}
                        >
                          <Trash2 size={18} />
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

      {/* Pagination Controls */}
      {totalPages > 1 && (
        <div
          style={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            gap: 12,
            marginTop: 20,
          }}
        >
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page === 1}
            style={{
              padding: '6px 12px',
              borderRadius: 6,
              border: '1px solid #d1d5db',
              background: page === 1 ? '#f3f4f6' : 'white',
              cursor: page === 1 ? 'not-allowed' : 'pointer',
            }}
          >
            Previous
          </button>
          <span style={{ fontSize: 13, color: '#4b5563' }}>
            Page {page} of {totalPages}
          </span>
          <button
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
            disabled={page === totalPages}
            style={{
              padding: '6px 12px',
              borderRadius: 6,
              border: '1px solid #d1d5db',
              background: page === totalPages ? '#f3f4f6' : 'white',
              cursor: page === totalPages ? 'not-allowed' : 'pointer',
            }}
          >
            Next
          </button>
        </div>
      )}

      {/* Modals */}
      {showAddModal && (
        <AddEventModal
          onClose={() => setShowAddModal(false)}
          onSuccess={() => fetchEvents(page)}
        />
      )}

      {showEditModal && editItem && (
        <EditEventModal
          event={editItem}
          onClose={() => {
            setShowEditModal(false);
            setEditItem(null);
          }}
          onSuccess={() => {
            setShowEditModal(false);
            setEditItem(null);
            fetchEvents(page);
          }}
        />
      )}

      {selectedEvent && (
        <ViewEventModal
          event={selectedEvent}
          onClose={() => setSelectedEvent(null)}
        />
      )}
    </div>
  );
};

export default EventsListings;

