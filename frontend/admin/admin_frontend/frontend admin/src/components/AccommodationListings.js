import React, { useState, useEffect } from 'react';
import { Plus, Trash2, ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import AddAccommodationModal from './AddAccommodationModal';

const AccommodationListings = () => {
  const navigate = useNavigate();
  const [accommodations, setAccommodations] = useState([]);
  const [showAddModal, setShowAddModal] = useState(false);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({ count: 0, activeCount: 0 });
  const [selectedAccommodation, setSelectedAccommodation] = useState(null);

  useEffect(() => {
    fetchAccommodations();
  }, []);

  const fetchAccommodations = async () => {
    setLoading(true);
    try {
      const response = await fetch('https://german-bharatham-backend.onrender.com/api/accommodation/admin', {
        headers: {
          'x-user-role': 'admin',
          'x-user-id': 'admin123'
        }
      });
      if (response.ok) {
        const result = await response.json();
        // Only display accommodations that have valid title and city (mongo-saved records)
        const validAccommodations = (result.data || []).filter(acc => 
          acc && acc._id && acc.title && acc.city
        );
        setAccommodations(validAccommodations);
        setStats({ 
          count: result.count || 0,
          activeCount: result.activeCount || 0
        });
      } else {
        console.error('Failed to fetch:', response.status);
        alert('Failed to fetch accommodations');
        setAccommodations([]);
      }
    } catch (error) {
      console.error('Error fetching accommodations:', error);
      alert('Error connecting to server: ' + error.message);
      setAccommodations([]);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id, title) => {
    if (!window.confirm(`Delete "${title}"?`)) return;

    try {
      const response = await fetch(`https://german-bharatham-backend.onrender.com/api/accommodation/admin/${id}`, {
        method: 'DELETE',
        headers: {
          'x-user-role': 'admin',
          'x-user-id': 'admin123'
        }
      });

      if (response.ok) {
        alert('Deleted successfully!');
        fetchAccommodations();
      } else {
        alert('Failed to delete');
      }
    } catch (error) {
      alert('Error: ' + error.message);
    }
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleDateString('en-GB');
  };

  const formatPrice = (accommodation) => {
    if (accommodation.rentDetails?.warmRent) {
      return `€${accommodation.rentDetails.warmRent}/mo`;
    }
    if (accommodation.rentDetails?.coldRent) {
      return `€${accommodation.rentDetails.coldRent}/mo`;
    }
    return 'N/A';
  };

  return (
    <div className="listings">
      <div className="listings-header">
        <div>
          <button 
            onClick={() => navigate('/categories')} 
            style={{ 
              background: 'none', 
              border: 'none', 
              color: '#6b9976', 
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              marginBottom: '10px',
              fontSize: '14px'
            }}
          >
            <ArrowLeft size={16} /> Back to Categories
          </button>
          <h1>Accommodation Listings</h1>
          <p>Total: {stats.count}</p>
        </div>
        <div className="header-actions">
          <button 
            className="add-listing-btn"
            onClick={() => setShowAddModal(true)}
          >
            <Plus size={20} />
            New Accommodation
          </button>
        </div>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px' }}>Loading...</div>
      ) : accommodations.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '40px' }}>
          <p>No accommodations found. Add your first one!</p>
        </div>
      ) : (
        <div className="listings-table">
          <table>
            <thead>
              <tr>
                <th>TITLE</th>
                <th>PROPERTY TYPE</th>
                <th>LOCATION</th>
                <th>PRICE</th>
                <th>SIZE</th>
                <th>HIGHLIGHTS</th>
                <th>CREATED</th>
                <th>ACTION</th>
              </tr>
            </thead>
            <tbody>
              {accommodations.map((accommodation) => (
                <tr key={accommodation._id}>
                  <td className="listing-title">{accommodation.title || 'Untitled'}</td>
                  <td style={{ textTransform: 'capitalize' }}>
                    {accommodation.propertyType?.replace(/_/g, ' ') || 'N/A'}
                  </td>
                  <td>
                    <div>
                      {accommodation.city || 'N/A'}, {accommodation.area || ''}
                      {accommodation.latitude && accommodation.longitude && (
                        <button
                          onClick={() => {
                            const url = `https://www.google.com/maps/dir/?api=1&destination=${accommodation.latitude},${accommodation.longitude}`;
                            window.open(url, '_blank');
                          }}
                          style={{
                            display: 'block',
                            marginTop: '5px',
                            padding: '3px 8px',
                            background: '#28a745',
                            color: 'white',
                            border: 'none',
                            borderRadius: '3px',
                            cursor: 'pointer',
                            fontSize: '11px'
                          }}
                        >
                          📍 Get Directions
                        </button>
                      )}
                    </div>
                  </td>
                  <td>{formatPrice(accommodation)}</td>
                  <td>{accommodation.propertyDetails?.sizeSqm ? `${accommodation.propertyDetails.sizeSqm} sqm` : 'N/A'}</td>
                  <td>
                    <div style={{ maxWidth: '200px' }}>
                      {accommodation.highlights && accommodation.highlights.length > 0 ? (
                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '5px' }}>
                          {accommodation.highlights.slice(0, 3).map((highlight, idx) => (
                            <span key={idx} style={{
                              padding: '3px 8px',
                              background: '#28a745',
                              color: 'white',
                              borderRadius: '10px',
                              fontSize: '11px',
                              display: 'inline-block'
                            }}>
                              <span style={{ color: 'red' }}>★</span> {highlight}
                            </span>
                          ))}
                          {accommodation.highlights.length > 3 && (
                            <span style={{ fontSize: '11px', color: '#666' }}>+{accommodation.highlights.length - 3} more</span>
                          )}
                        </div>
                      ) : (
                        <span style={{ fontSize: '12px', color: '#999' }}>No highlights</span>
                      )}
                    </div>
                  </td>
                  <td>{formatDate(accommodation.createdAt)}</td>
                  <td>
                    <div className="action-buttons">
                      <button 
                        className="action-btn view-btn"
                        onClick={() => setSelectedAccommodation(accommodation)}
                        style={{
                          background: '#28a745',
                          color: 'white',
                          padding: '8px 12px',
                          border: 'none',
                          borderRadius: '4px',
                          cursor: 'pointer',
                          marginRight: '8px'
                        }}
                      >
                        View Details
                      </button>
                      <button 
                        className="action-btn delete-btn"
                        onClick={() => handleDelete(accommodation._id, accommodation.title)}
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
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

      {selectedAccommodation && (
        <div className="modal-overlay" onClick={() => setSelectedAccommodation(null)}>
          <div className="modal-content modal-large" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '800px', maxHeight: '90vh', overflow: 'auto' }}>
            <div className="modal-header">
              <h2>{selectedAccommodation.title}</h2>
              <button className="close-btn" onClick={() => setSelectedAccommodation(null)}>×</button>
            </div>
            
            <div style={{ padding: '20px' }}>
              {/* Property Type Badge */}
              <div style={{ marginBottom: '20px' }}>
                <span style={{ 
                  padding: '8px 16px', 
                  background: '#28a745', 
                  color: 'white', 
                  borderRadius: '20px',
                  fontSize: '14px',
                  fontWeight: 'bold',
                  textTransform: 'capitalize'
                }}>
                  {selectedAccommodation.propertyType?.replace(/_/g, ' ')}
                </span>
              </div>

              {/* Key Highlights Section */}
              {selectedAccommodation.highlights && selectedAccommodation.highlights.length > 0 && (
                <div style={{ 
                  marginBottom: '25px', 
                  padding: '20px', 
                  background: '#28a745',
                  borderRadius: '12px',
                  boxShadow: '0 4px 15px rgba(0,0,0,0.2)'
                }}>
                  <h3 style={{ color: 'white', marginBottom: '15px', fontSize: '18px' }}>Key Highlights</h3>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '10px' }}>
                    {selectedAccommodation.highlights.map((highlight, idx) => (
                      <span key={idx} style={{
                        padding: '10px 16px',
                        background: 'white',
                        color: '#333',
                        borderRadius: '20px',
                        fontSize: '14px',
                        fontWeight: '600',
                        boxShadow: '0 2px 8px rgba(0,0,0,0.15)'
                      }}>
                        <span style={{ color: 'red' }}>★</span> {highlight}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Description */}
              <div style={{ marginBottom: '20px' }}>
                <h3 style={{ fontSize: '16px', marginBottom: '10px', color: '#333' }}>Description</h3>
                <p style={{ color: '#666', lineHeight: '1.6' }}>{selectedAccommodation.description || 'No description available'}</p>
              </div>

              {/* Location with Map */}
              <div style={{ marginBottom: '20px', padding: '15px', background: '#f8f9fa', borderRadius: '8px' }}>
                <h3 style={{ fontSize: '16px', marginBottom: '10px', color: '#333' }}>📍 Location</h3>
                <p style={{ marginBottom: '10px' }}>{selectedAccommodation.address || ''}, {selectedAccommodation.area || ''}, {selectedAccommodation.city || ''} {selectedAccommodation.postalCode || ''}</p>
                {selectedAccommodation.latitude && selectedAccommodation.longitude && (
                  <button
                    onClick={() => {
                      const url = `https://www.google.com/maps/dir/?api=1&destination=${selectedAccommodation.latitude},${selectedAccommodation.longitude}`;
                      window.open(url, '_blank');
                    }}
                    style={{
                      padding: '10px 20px',
                      background: '#28a745',
                      color: 'white',
                      border: 'none',
                      borderRadius: '6px',
                      cursor: 'pointer',
                      fontWeight: '600'
                    }}
                  >
                    🗺️ Open Map & Get Directions
                  </button>
                )}
              </div>

              {/* Rent Details */}
              <div style={{ marginBottom: '20px', padding: '15px', background: 'white', border: '2px solid #28a745', borderRadius: '8px' }}>
                <h3 style={{ fontSize: '16px', marginBottom: '10px', color: '#333' }}>💰 Rent Details</h3>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '10px' }}>
                  {selectedAccommodation.rentDetails?.coldRent && <p><strong>Cold Rent:</strong> €{selectedAccommodation.rentDetails.coldRent}/mo</p>}
                  {selectedAccommodation.rentDetails?.warmRent && <p><strong>Warm Rent:</strong> €{selectedAccommodation.rentDetails.warmRent}/mo</p>}
                  {selectedAccommodation.rentDetails?.additionalCosts && <p><strong>Additional Costs:</strong> €{selectedAccommodation.rentDetails.additionalCosts}/mo</p>}
                  {selectedAccommodation.rentDetails?.deposit && <p><strong>Deposit <span style={{ color: 'red' }}>★</span>:</strong> €{selectedAccommodation.rentDetails.deposit}</p>}
                </div>
                <div style={{ marginTop: '10px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                  {selectedAccommodation.rentDetails?.electricityIncluded && <span style={{ padding: '5px 10px', background: '#d4edda', borderRadius: '5px', fontSize: '12px' }}>⚡ Electricity Included</span>}
                  {selectedAccommodation.rentDetails?.heatingIncluded && <span style={{ padding: '5px 10px', background: '#d4edda', borderRadius: '5px', fontSize: '12px' }}>🔥 Heating Included</span>}
                  {selectedAccommodation.rentDetails?.internetIncluded && <span style={{ padding: '5px 10px', background: '#d4edda', borderRadius: '5px', fontSize: '12px' }}>📶 Internet Included</span>}
                </div>
              </div>

              {/* Property Details */}
              <div style={{ marginBottom: '20px', padding: '15px', background: 'white', border: '2px solid #28a745', borderRadius: '8px' }}>
                <h3 style={{ fontSize: '16px', marginBottom: '10px', color: '#333' }}>🏠 Property Details</h3>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '10px' }}>
                  {selectedAccommodation.propertyDetails?.sizeSqm && <p><strong>Size:</strong> {selectedAccommodation.propertyDetails.sizeSqm} sqm</p>}
                  {selectedAccommodation.propertyDetails?.bedrooms && <p><strong>Bedrooms:</strong> {selectedAccommodation.propertyDetails.bedrooms}</p>}
                  {selectedAccommodation.propertyDetails?.bathrooms && <p><strong>Bathrooms:</strong> {selectedAccommodation.propertyDetails.bathrooms}</p>}
                  {selectedAccommodation.propertyDetails?.floorNumber && <p><strong>Floor:</strong> {selectedAccommodation.propertyDetails.floorNumber}/{selectedAccommodation.propertyDetails.totalFloors}</p>}
                  {selectedAccommodation.propertyDetails?.availableFrom && <p><strong>Available:</strong> {formatDate(selectedAccommodation.propertyDetails.availableFrom)}</p>}
                  {selectedAccommodation.propertyDetails?.furnished && <p><strong>Furnished:</strong> Yes</p>}
                </div>
              </div>

              {/* Amenities */}
              <div style={{ marginBottom: '20px', padding: '15px', background: 'white', border: '2px solid #28a745', borderRadius: '8px' }}>
                <h3 style={{ fontSize: '16px', marginBottom: '15px', color: '#333' }}>🛋️ Amenities</h3>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '10px' }}>
                  {selectedAccommodation.amenities && Object.entries(selectedAccommodation.amenities).map(([key, value]) => 
                    value && (
                      <div key={key} style={{ 
                        padding: '8px 12px', 
                        background: '#d4edda', 
                        borderRadius: '6px',
                        fontSize: '13px',
                        fontWeight: '500'
                      }}>
                        ✅ {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                      </div>
                    )
                  )}
                </div>
              </div>

              {/* Location Highlights */}
              {selectedAccommodation.locationHighlights && (
                <div style={{ padding: '15px', background: 'white', border: '2px solid #28a745', borderRadius: '8px' }}>
                  <h3 style={{ fontSize: '16px', marginBottom: '10px', color: '#333' }}>🎯 Nearby Amenities</h3>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '10px' }}>
                    {selectedAccommodation.locationHighlights.nearUniversity && <span style={{ padding: '6px 12px', background: '#fff', borderRadius: '5px', fontSize: '13px', border: '1px solid #ddd' }}>🎓 Near University</span>}
                    {selectedAccommodation.locationHighlights.nearSupermarket && <span style={{ padding: '6px 12px', background: '#fff', borderRadius: '5px', fontSize: '13px', border: '1px solid #ddd' }}>🛒 Near Supermarket</span>}
                    {selectedAccommodation.locationHighlights.nearHospital && <span style={{ padding: '6px 12px', background: '#fff', borderRadius: '5px', fontSize: '13px', border: '1px solid #ddd' }}>🏥 Near Hospital</span>}
                    {selectedAccommodation.locationHighlights.nearPublicTransport && <span style={{ padding: '6px 12px', background: '#fff', borderRadius: '5px', fontSize: '13px', border: '1px solid #ddd' }}>🚇 Near Public Transport</span>}
                  </div>
                  {(selectedAccommodation.locationHighlights.ubahnDistanceMeters || selectedAccommodation.locationHighlights.sbahnDistanceMeters || selectedAccommodation.locationHighlights.busDistanceMeters) && (
                    <div style={{ marginTop: '10px', fontSize: '13px', color: '#666' }}>
                      {selectedAccommodation.locationHighlights.ubahnDistanceMeters && <p>U-Bahn: {selectedAccommodation.locationHighlights.ubahnDistanceMeters}m</p>}
                      {selectedAccommodation.locationHighlights.sbahnDistanceMeters && <p>S-Bahn: {selectedAccommodation.locationHighlights.sbahnDistanceMeters}m</p>}
                      {selectedAccommodation.locationHighlights.busDistanceMeters && <p>Bus: {selectedAccommodation.locationHighlights.busDistanceMeters}m</p>}
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AccommodationListings;
