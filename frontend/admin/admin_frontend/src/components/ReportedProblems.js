import React, { useCallback, useEffect, useState } from 'react';
import { AlertCircle } from 'lucide-react';
import SkeletonLoader from './SkeletonLoader';
import API_URL from '../config';

const mapReports = (payload) => {
  const list = Array.isArray(payload)
    ? payload
    : payload?.data || payload?.reports || payload?.problems || payload?.items || [];

  return (Array.isArray(list) ? list : [])
    .map((item, index) => ({
      id: item._id || item.id || `${item.createdAt || Date.now()}-${index}`,
      subject: item.subject || item.title || 'Problem reported',
      description: item.description || item.message || item.problem || item.content || '',
      userName: item.user?.name || item.userName || item.reportedBy || 'User',
      userEmail: item.user?.email || item.email || '',
      createdAt: item.createdAt || item.reportedAt || item.date || null,
    }))
    .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
};

const ReportedProblems = () => {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [readReportIds, setReadReportIds] = useState(() => {
    try {
      const saved = localStorage.getItem('adminReadProblemReportIds');
      const parsed = saved ? JSON.parse(saved) : [];
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  });

  const fetchReports = useCallback(async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem('adminToken');
      const response = await fetch(`${API_URL}/api/problem-reports/admin`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!response.ok) {
        setReports([]);
        return;
      }

      const payload = await response.json();
      setReports(mapReports(payload));
    } catch {
      setReports([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchReports();
  }, [fetchReports]);

  useEffect(() => {
    if (!reports.length) return;
    setReadReportIds((current) => {
      const nextReadIds = Array.from(new Set([...current, ...reports.map((r) => r.id)]));
      localStorage.setItem('adminReadProblemReportIds', JSON.stringify(nextReadIds));
      return nextReadIds;
    });
  }, [reports]);

  return (
    <div className="content-moderation">
      <div className="moderation-header">
        <div>
          <h1>Reported Problems</h1>
          <p>Problems submitted by users.</p>
        </div>
      </div>

      <div className="dashboard-section">
        {loading ? (
          <SkeletonLoader rows={3} columns={4} type="list" />
        ) : reports.length === 0 ? (
          <div style={{ padding: '1rem', color: '#6b7280' }}>No reported problems.</div>
        ) : (
          <div className="notification-list" style={{ maxHeight: 'none' }}>
            {reports.map((report) => (
              <div key={report.id} className="notification-item">
                <div className="notification-item-icon">
                  <AlertCircle size={16} />
                </div>
                <div className="notification-item-content" style={{ width: '100%' }}>
                  <p className="notification-item-title">{report.subject}</p>
                  <p className="notification-item-description" style={{ WebkitLineClamp: 'unset' }}>
                    {report.description || 'No details provided.'}
                  </p>
                  <p className="notification-item-meta">
                    {report.userName}
                    {report.userEmail ? ` (${report.userEmail})` : ''}
                    {report.createdAt ? ` • ${new Date(report.createdAt).toLocaleString('en-GB')}` : ''}
                    {` • ${readReportIds.includes(report.id) ? 'Read' : 'Unread'}`}
                  </p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default ReportedProblems;
