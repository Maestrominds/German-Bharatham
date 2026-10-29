import React from 'react';
import { X, Calendar, MapPin, DollarSign, User, Phone, ExternalLink, Globe, Sparkles } from 'lucide-react';

const FORMAT_LABELS = {
  one_day: 'One-Day Event',
  multi_day: 'Multi-Day Festival',
  course: 'Course / Multi-Week',
  workshop: 'Workshop',
  screening: 'Movie Screening',
  deadline: 'Deadline',
};

const ViewEventModal = ({ event, onClose }) => {
  if (!event) return null;

  const formatDate = (d) => {
    if (!d) return 'N/A';
    try {
      return new Date(d).toLocaleString('en-GB', {
        dateStyle: 'medium',
        timeStyle: 'short',
      });
    } catch {
      return String(d);
    }
  };

  const images = Array.isArray(event.images) ? event.images : [];
  const sessions = Array.isArray(event.sessions) ? event.sessions : [];

  return (
    <div className="modal-overlay">
      <div className="modal-content" style={{ maxWidth: 640, maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <h2 style={{ fontSize: 18 }}>{event.title || 'Event Details'}</h2>
          <button className="close-btn" onClick={onClose}>
            <X size={20} />
          </button>
        </div>

        <div style={{ padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: 16 }}>
          {/* Images preview carousel */}
          {images.length > 0 && (
            <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 4 }}>
              {images.map((img, i) => (
                <img
                  key={i}
                  src={img}
                  alt={`event-${i}`}
                  style={{
                    height: 160,
                    borderRadius: 8,
                    objectFit: 'cover',
                    flexShrink: 0,
                  }}
                />
              ))}
            </div>
          )}

          {/* Quick Badges */}
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <span
              style={{
                background: '#e0f2fe',
                color: '#0369a1',
                padding: '4px 10px',
                borderRadius: 14,
                fontSize: 12,
                fontWeight: 600,
                textTransform: 'capitalize',
              }}
            >
              {FORMAT_LABELS[event.format] || event.format || 'Event'}
            </span>
            <span
              style={{
                background: '#fef3c7',
                color: '#92400e',
                padding: '4px 10px',
                borderRadius: 14,
                fontSize: 12,
                fontWeight: 600,
                textTransform: 'capitalize',
              }}
            >
              {event.category || 'festivals'}
            </span>
            {event.isOnline && (
              <span
                style={{
                  background: '#ede9fe',
                  color: '#6d28d9',
                  padding: '4px 10px',
                  borderRadius: 14,
                  fontSize: 12,
                  fontWeight: 600,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 4,
                }}
              >
                <Globe size={12} /> Online
              </span>
            )}
            {event.familyFriendly && (
              <span
                style={{
                  background: '#fdf2f8',
                  color: '#be185d',
                  padding: '4px 10px',
                  borderRadius: 14,
                  fontSize: 12,
                  fontWeight: 600,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 4,
                }}
              >
                <Sparkles size={12} /> Family-Friendly
              </span>
            )}
            <span
              style={{
                background:
                  String(event.status).toLowerCase() === 'active'
                    ? '#d1fae5'
                    : '#fee2e2',
                color:
                  String(event.status).toLowerCase() === 'active'
                    ? '#065f46'
                    : '#991b1b',
                padding: '4px 10px',
                borderRadius: 14,
                fontSize: 12,
                fontWeight: 600,
              }}
            >
              {event.status || 'Active'}
            </span>
          </div>

          {/* Short Description */}
          {(event.shortDescription || event.short_description) && (
            <div style={{ background: '#f8fafc', padding: '10px 14px', borderRadius: 8, fontStyle: 'italic', color: '#475569', fontSize: 13, borderLeft: '3px solid #3b82f6' }}>
              "{event.shortDescription || event.short_description}"
            </div>
          )}

          {/* Details Grid */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: '1fr 1fr',
              gap: 12,
              background: '#f9fafb',
              padding: 14,
              borderRadius: 10,
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Calendar size={16} color="#6b7280" />
              <div>
                <div style={{ fontSize: 11, color: '#6b7280' }}>Starts</div>
                <div style={{ fontSize: 13, fontWeight: 600 }}>
                  {formatDate(event.startsAt || event.start_date)}
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Calendar size={16} color="#6b7280" />
              <div>
                <div style={{ fontSize: 11, color: '#6b7280' }}>Ends</div>
                <div style={{ fontSize: 13, fontWeight: 600 }}>
                  {formatDate(event.endsAt || event.end_date)}
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <MapPin size={16} color="#6b7280" />
              <div>
                <div style={{ fontSize: 11, color: '#6b7280' }}>City / Venue</div>
                <div style={{ fontSize: 13, fontWeight: 600 }}>
                  {event.isOnline
                    ? 'Online'
                    : [event.city, event.venue, event.address].filter(Boolean).join(' • ') || 'N/A'}
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <DollarSign size={16} color="#6b7280" />
              <div>
                <div style={{ fontSize: 11, color: '#6b7280' }}>Price</div>
                <div style={{ fontSize: 13, fontWeight: 600 }}>
                  {event.priceText || event.price || (event.priceType === 'free' ? 'Free' : 'N/A')}
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <User size={16} color="#6b7280" />
              <div>
                <div style={{ fontSize: 11, color: '#6b7280' }}>Organizer</div>
                <div style={{ fontSize: 13, fontWeight: 600 }}>
                  {event.organizer || 'German Bharatham'}
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Phone size={16} color="#6b7280" />
              <div>
                <div style={{ fontSize: 11, color: '#6b7280' }}>Contact</div>
                <div style={{ fontSize: 13, fontWeight: 600 }}>
                  {event.contact || 'N/A'}
                </div>
              </div>
            </div>
          </div>

          {/* Sessions / Cinemas table if available */}
          {sessions.length > 0 && (
            <div>
              <div style={{ fontSize: 13, fontWeight: 600, color: '#374151', marginBottom: 8 }}>
                Cinemas & Showtimes ({sessions.length})
              </div>
              <div style={{ border: '1px solid #e5e7eb', borderRadius: 8, overflow: 'hidden' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 12 }}>
                  <thead style={{ background: '#f9fafb', borderBottom: '1px solid #e5e7eb' }}>
                    <tr>
                      <th style={{ padding: '8px 12px', textAlign: 'left' }}>Cinema / Venue</th>
                      <th style={{ padding: '8px 12px', textAlign: 'left' }}>City</th>
                      <th style={{ padding: '8px 12px', textAlign: 'left' }}>Date & Time</th>
                      <th style={{ padding: '8px 12px', textAlign: 'left' }}>Booking</th>
                    </tr>
                  </thead>
                  <tbody>
                    {sessions.map((s, idx) => (
                      <tr key={idx} style={{ borderBottom: '1px solid #f3f4f6' }}>
                        <td style={{ padding: '8px 12px', fontWeight: 500 }}>{s.cinemaName || s.venue || '—'}</td>
                        <td style={{ padding: '8px 12px', color: '#6b7280' }}>{s.city || '—'}</td>
                        <td style={{ padding: '8px 12px', color: '#374151' }}>
                          {[s.date, s.time].filter(Boolean).join(' ') || (s.startsAt ? formatDate(s.startsAt) : '—')}
                        </td>
                        <td style={{ padding: '8px 12px' }}>
                          {s.bookingUrl ? (
                            <a href={s.bookingUrl} target="_blank" rel="noreferrer" style={{ color: '#2563eb' }}>
                              Book
                            </a>
                          ) : '—'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Ticket / External URL */}
          {(event.ticketUrl || event.externalUrl || event.onlineLink) && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <ExternalLink size={15} color="#2563eb" />
              <a
                href={
                  (event.ticketUrl || event.externalUrl || event.onlineLink).startsWith('http')
                    ? event.ticketUrl || event.externalUrl || event.onlineLink
                    : `https://${event.ticketUrl || event.externalUrl || event.onlineLink}`
                }
                target="_blank"
                rel="noreferrer"
                style={{ color: '#2563eb', fontSize: 13, fontWeight: 600 }}
              >
                {event.isOnline ? 'Open Online Meeting / Stream Link' : 'Open Ticket / Registration Link'}
              </a>
            </div>
          )}

          {/* Description */}
          {event.description && (
            <div>
              <div
                style={{
                  fontSize: 12,
                  fontWeight: 600,
                  color: '#374151',
                  marginBottom: 4,
                }}
              >
                Description
              </div>
              <p
                style={{
                  fontSize: 13,
                  lineHeight: 1.5,
                  color: '#4b5563',
                  margin: 0,
                  whiteSpace: 'pre-wrap',
                }}
              >
                {event.description}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ViewEventModal;
