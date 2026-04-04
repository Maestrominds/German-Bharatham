import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { Plus, TrendingUp, FolderOpen, Users, Clock, Bell } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import AddListingModal from './AddListingModal';
import API_URL from '../config';

const Dashboard = () => {
  const [showAddModal, setShowAddModal]     = useState(false);
  const [totalCount, setTotalCount]         = useState(0);
  const [categoryCounts, setCategoryCounts] = useState({ Accommodation: 0, Food: 0, Jobs: 0, Services: 0 });
  const [userCount, setUserCount]           = useState(0);
  const [pendingReviews, setPendingReviews] = useState(0);
  const [categoryCount, setCategoryCount]   = useState(4);
  const [recentListings, setRecentListings] = useState([]);
  const [problemReports, setProblemReports] = useState([]);
  const [readReportIds, setReadReportIds] = useState(() => {
    try {
      const saved = localStorage.getItem('adminReadProblemReportIds');
      const parsed = saved ? JSON.parse(saved) : [];
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  });
  const navigate = useNavigate();

  const handleUnauthorized = useCallback(() => {
    localStorage.removeItem('adminToken');
    window.location.reload();
  }, []);

  const fetchProblemReports = useCallback(async () => {
    try {
      const token = localStorage.getItem('adminToken');
      const headers = { Authorization: `Bearer ${token}` };
      const endpoints = [
        `${API_URL}/api/problem-reports/admin`,
        `${API_URL}/api/report-problem/admin`,
        `${API_URL}/api/reported-problems/admin`,
      ];

      let payload = null;
      for (const endpoint of endpoints) {
        try {
          const response = await fetch(endpoint, { headers });
          if (response.status === 401 || response.status === 403) {
            handleUnauthorized();
            return;
          }
          if (!response.ok) continue;
          payload = await response.json();
          break;
        } catch {
          continue;
        }
      }

      const sourceList = Array.isArray(payload)
        ? payload
        : payload?.data || payload?.reports || payload?.problems || payload?.items || [];

      const mapped = (Array.isArray(sourceList) ? sourceList : [])
        .map((item, index) => ({
          id: item._id || item.id || `${item.createdAt || item.reportedAt || Date.now()}-${index}`,
          title: item.subject || item.title || item.problemType || 'Problem reported',
          description: item.description || item.message || item.problem || item.content || item.details || item.review || '',
          reportedBy: item.userName || item.user?.name || item.reportedBy || item.email || 'User',
          createdAt: item.createdAt || item.reportedAt || item.date || item.updatedAt || null,
        }))
        .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));

      setProblemReports(mapped);
    } catch {
      setProblemReports([]);
    }
  }, [handleUnauthorized]);

  const fetchAll = useCallback(async () => {
    const token   = localStorage.getItem('adminToken');
    const headers = { Authorization: `Bearer ${token}` };

    // Prefer single dashboard endpoint that returns aggregated stats (faster)
    try {
      const res = await fetch(`${API_URL}/api/admin/dashboard`, { headers });
      if (res.status === 401 || res.status === 403) { handleUnauthorized(); return; }
      if (res.ok) {
        const d = await res.json();
        const s = d.stats || {};
        setTotalCount(s.totalListings || 0);
        setPendingReviews(s.pendingReviews || 0);
        setUserCount(s.totalUsers || 0);

        // map category stats
        const catCounts = { Accommodation: 0, Food: 0, Jobs: 0, Services: 0 };
        (d.categoryStats || []).forEach(c => { if (c && c.name) catCounts[c.name] = c.count || 0; });
        setCategoryCounts(catCounts);
        setRecentListings(d.recentListings || []);
        setCategoryCount(s.totalCategories || 4);
      }
    } catch (e) { console.error('fetch dashboard error', e); }
    }, [handleUnauthorized]);

  useEffect(() => {
    fetchAll();
    fetchProblemReports();
  }, [fetchAll, fetchProblemReports]);

  const unreadCount = useMemo(
    () => problemReports.filter(report => !readReportIds.includes(report.id)).length,
    [problemReports, readReportIds]
  );

  const openReportedProblems = () => {
    if (problemReports.length > 0) {
      const nextReadIds = Array.from(new Set([...readReportIds, ...problemReports.map(report => report.id)]));
      setReadReportIds(nextReadIds);
      localStorage.setItem('adminReadProblemReportIds', JSON.stringify(nextReadIds));
    }
    navigate('/reported-problems');
  };

  const stats = [
    { label: 'Total Listings', value: totalCount,    icon: TrendingUp },
    { label: 'Categories',     value: categoryCount, icon: FolderOpen },
    { label: 'Total Users',    value: userCount,     icon: Users      },
    { label: 'Pending Reviews',value: pendingReviews, icon: Clock      },
  ];

  const categoryStats = [
    { name: 'Accommodation', count: categoryCounts.Accommodation, icon: '🏠' },
    { name: 'Food',          count: categoryCounts.Food,          icon: '🍴' },
    { name: 'Services',      count: categoryCounts.Services,      icon: '🔧' },
    { name: 'Jobs',          count: categoryCounts.Jobs,          icon: '💼' },
  ];

  return (
    <div className="dashboard">
      <div className="dashboard-header">
        <div>
          <h1>Dashboard</h1>
          <p>Welcome back! Here's what's happening.</p>
        </div>
        <div className="dashboard-header-actions">
          <button
            type="button"
            className="notification-btn"
            onClick={openReportedProblems}
            aria-label="Open reported problems"
          >
            <Bell size={20} />
            {unreadCount > 0 && (
              <span className="notification-badge">{unreadCount > 99 ? '99+' : unreadCount}</span>
            )}
          </button>

          <button
            className="add-listing-btn"
            onClick={() => setShowAddModal(true)}
          >
            <Plus size={20} />
            New Listing
          </button>
        </div>
      </div>

      <div className="stats-grid">
        {stats.map((stat, index) => (
          <div key={index} className="stat-card">
            <div className="stat-content">
              <div className="stat-icon">
                <stat.icon size={20} />
              </div>
              <div className="stat-info">
                <p className="stat-label">{stat.label}</p>
                <h3 className="stat-value">{stat.value}</h3>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="dashboard-content">
        <div className="dashboard-section">
          <h2>Listings by Category</h2>
          <div className="category-stats">
            {categoryStats.map((category, index) => (
              <div key={index} className="category-card">
                <div className="category-icon">{category.icon}</div>
                <div className="category-info">
                  <h3>{category.count}</h3>
                  <p>{category.name}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="dashboard-grid">
          <div className="dashboard-section">
            <div className="section-header">
              <h2>Recent Listings</h2>
            </div>
            <div className="listings-table">
              <table>
                <thead>
                  <tr>
                    <th>TITLE</th>
                    <th>CATEGORY</th>
                    <th>STATUS</th>
                    <th>ADDED</th>
                  </tr>
                </thead>
                <tbody>
                  {recentListings.length === 0 ? (
                    <tr><td colSpan={4} style={{ textAlign: 'center', color: '#6b7280', padding: 16 }}>No listings yet.</td></tr>
                  ) : recentListings.map((listing, index) => (
                    <tr key={index}>
                      <td>{listing.title}</td>
                      <td>{listing.category}</td>
                      <td>
                        <span className={`status ${listing.status.toLowerCase()}`}>
                          {listing.status}
                        </span>
                      </td>
                      <td>{listing.createdAt ? new Date(listing.createdAt).toLocaleDateString('en-GB') : '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          <div className="dashboard-section">
            <div className="section-header">
              <h2>Recent Activity</h2>
            </div>
            <div className="activity-list">
              {recentListings.slice(0, 5).map((listing, index) => (
                <div key={index} className="activity-item">
                  <div className="activity-content">
                    <p className="activity-action">Listing added</p>
                    <p className="activity-detail">{listing.title}</p>
                  </div>
                  <span className="activity-time">{listing.createdAt ? new Date(listing.createdAt).toLocaleDateString('en-GB') : '—'}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {showAddModal && (
        <AddListingModal
          onClose={() => setShowAddModal(false)}
          onSuccess={() => { setShowAddModal(false); fetchAll(); }}
        />
      )}
    </div>
  );
};

export default Dashboard;
