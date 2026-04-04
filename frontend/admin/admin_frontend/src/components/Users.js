import React, { useState, useEffect } from 'react';
import API_URL from '../config';

const ITEMS_PER_PAGE = 10;

const Users = () => {
  const [sortBy, setSortBy]   = useState('newest');
  const [filterBy, setFilterBy] = useState('all');
  const [users, setUsers]     = useState([]);
  const [totalCount, setTotalCount] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const BASE = API_URL;

  const getUserPhotoSrc = (user) => {
    const p = user?.photo;
    if (!p || typeof p !== 'string') return null;
    const trimmed = p.trim();
    if (!trimmed) return null;
    if (trimmed.startsWith('data:image')) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;

    // Base64 without data: prefix (best-effort)
    const looksBase64 = /^[A-Za-z0-9+/=]+$/.test(trimmed) && trimmed.length > 100;
    if (looksBase64) return `data:image/jpeg;base64,${trimmed}`;

    return null;
  };
  useEffect(() => {
    fetchUsers();
  }, [currentPage, filterBy]);

const fetchUsers = async () => {
  try {
    const token = localStorage.getItem("adminToken");

    const qs = new URLSearchParams();
    qs.set('page', String(currentPage));
    qs.set('limit', String(ITEMS_PER_PAGE));
    const response = await fetch(`${BASE}/api/user/all-users?${qs.toString()}`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    const data = await response.json();

    if (!response.ok) {
      alert(data.message);
      return;
    }

    // normalize paged or array responses
    if (Array.isArray(data)) {
      setUsers(data);
      setTotalCount(data.length);
    } else if (Array.isArray(data.data)) {
      setUsers(data.data);
      setTotalCount(data.count || data.total || 0);
    } else {
      setUsers([]);
      setTotalCount(0);
    }

  } catch (error) {
    console.error("Error fetching users:", error);
  }
};
  const handleUserAction = async (userId, action) => {
  try {
    const token = localStorage.getItem("adminToken");

    await fetch(`${BASE}/api/user/${action}/${userId}`, {
      method: "PUT",
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    fetchUsers(); // refresh table

  } catch (error) {
    console.error("Error updating user:", error);
  }
};

  return (
    <div className="users">
      <div className="users-header">
        <div>
          <h1>Users</h1>
          <p>View and manage platform users.</p>
        </div>
        <div className="header-filters">
          <div className="filter-dropdown">
            <select
              value={sortBy}
              onChange={(e) => { setSortBy(e.target.value); setCurrentPage(1); }}
              className="filter-select"
            >
              <option value="newest">Newest first</option>
              <option value="oldest">Oldest first</option>
              <option value="alphabetical">A-Z</option>
            </select>
          </div>
          <div className="filter-dropdown">
            <select
              value={filterBy}
              onChange={(e) => { setFilterBy(e.target.value); setCurrentPage(1); }}
              className="filter-select"
            >
              <option value="all">All Users</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>
        </div>
      </div>

      {/* ── derived list with filter + sort + pagination ── */}
      {(() => {
        let list = Array.isArray(users) ? [...users] : [];

        // filter by status
        if (filterBy === 'active')   list = list.filter(u => u.isActive);
        if (filterBy === 'inactive') list = list.filter(u => !u.isActive);

        // sort
        if (sortBy === 'newest')      list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
        if (sortBy === 'oldest')      list.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
        if (sortBy === 'alphabetical') list.sort((a, b) => (a.name || '').localeCompare(b.name || ''));

        const totalPages  = Math.max(1, Math.ceil((totalCount || list.length) / ITEMS_PER_PAGE));
        const safePage    = Math.min(currentPage, totalPages || 1);
        const pageSlice   = list.slice(0, ITEMS_PER_PAGE);

        return (
          <>
            <div className="users-table">
              <table>
                <thead>
                  <tr>
                    <th>NAME</th>
                    <th>EMAIL</th>
                    <th>JOINED DATE</th>
                    <th>STATUS</th>
                    <th>ACTION</th>
                  </tr>
                </thead>
                <tbody>
                  {pageSlice.length === 0 ? (
                    <tr><td colSpan={5} style={{ textAlign: 'center', padding: 24, color: '#6b7280' }}>No users found.</td></tr>
                  ) : pageSlice.map((user) => (
                    <tr key={user._id}>
                      <td>
                        <div className="user-info">
                          <img
                            src={
                              getUserPhotoSrc(user) ||
                              `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name || 'U')}&background=6b9976&color=fff`
                            }
                            alt={user.name}
                            className="user-avatar"
                          />
                          <span className="user-name">{user.name}</span>
                        </div>
                      </td>
                      <td>{user.email}</td>
                      <td>{new Date(user.createdAt).toLocaleDateString()}</td>
                      <td>
                        <span className={`status ${user.isActive ? 'active' : 'inactive'}`}>
                          {user.isActive ? 'Active' : 'Inactive'}
                        </span>
                      </td>
                      <td>
                        {user.isActive ? (
                          <button className="action-btn deactivate-btn" onClick={() => handleUserAction(user._id, 'deactivate')}>Deactivate</button>
                        ) : (
                          <button className="action-btn activate-btn" onClick={() => handleUserAction(user._id, 'activate')}>Activate</button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {totalPages > 1 && (
              <div className="pagination">
                <div className="pagination-numbers">
                  {Array.from({ length: totalPages }, (_, i) => i + 1).map(page => (
                    <button
                      key={page}
                      className={`pagination-btn ${safePage === page ? 'active' : ''}`}
                      onClick={() => setCurrentPage(page)}
                    >
                      {page}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {totalCount > 0 && (
              <p style={{ fontSize: 13, color: '#6b7280', padding: '8px 0', textAlign: 'right' }}>
                Showing {(safePage - 1) * ITEMS_PER_PAGE + 1}–{Math.min(safePage * ITEMS_PER_PAGE, totalCount)} of {totalCount} users
              </p>
            )}
          </>
        );
      })()}
    </div>
  );
};

export default Users;
