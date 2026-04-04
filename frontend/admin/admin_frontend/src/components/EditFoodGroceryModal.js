import React, { useState } from 'react';
import API_URL from '../config';
import { X, Upload, MapPin, Phone, Mail, Globe, Clock } from 'lucide-react';

const EditFoodGroceryModal = ({ item, onClose, onSuccess }) => {
  const [formData, setFormData] = useState({
    title: item.title || item.name || '',
    subCategory: item.subCategory || item.category || 'Restaurant',
    type: item.type || '',
    address: item.address || '',
    city: item.city || '',
    state: item.state || '',
    zipCode: item.zipCode || '',
    phone: item.phone || '',
    email: item.email || '',
    website: item.website || '',
    description: item.description || '',
    openingHours: item.openingHours || '',
    priceRange: item.priceRange || '$$',
    cuisine: item.cuisine || [],
    specialties: item.specialties || [],
    deliveryAvailable: item.deliveryAvailable || false,
    takeoutAvailable: item.takeoutAvailable || false,
    dineInAvailable: item.dineInAvailable || false,
    cateringAvailable: item.cateringAvailable || false,
    image: item.image || '',
    featured: item.featured || false,
    verified: item.verified || false
  });

  const [cuisineInput, setCuisineInput] = useState('');
  const [specialtyInput, setSpecialtyInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleAddCuisine = (e) => {
    e.preventDefault();
    if (cuisineInput.trim() && !formData.cuisine.includes(cuisineInput.trim())) {
      setFormData(prev => ({
        ...prev,
        cuisine: [...prev.cuisine, cuisineInput.trim()]
      }));
      setCuisineInput('');
    }
  };

  const handleRemoveCuisine = (cuisine) => {
    setFormData(prev => ({
      ...prev,
      cuisine: prev.cuisine.filter(c => c !== cuisine)
    }));
  };

  const handleAddSpecialty = (e) => {
    e.preventDefault();
    if (specialtyInput.trim() && !formData.specialties.includes(specialtyInput.trim())) {
      setFormData(prev => ({
        ...prev,
        specialties: [...prev.specialties, specialtyInput.trim()]
      }));
      setSpecialtyInput('');
    }
  };

  const handleRemoveSpecialty = (specialty) => {
    setFormData(prev => ({
      ...prev,
      specialties: prev.specialties.filter(s => s !== specialty)
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const token = localStorage.getItem('adminToken');
      // Prepare data with location field
      const submitData = {
        title: formData.title,
        subCategory: formData.subCategory,
        type: formData.type,
        location: `${formData.city}, ${formData.address}`,
        address: formData.address,
        city: formData.city,
        state: formData.state,
        zipCode: formData.zipCode,
        phone: formData.phone,
        email: formData.email,
        website: formData.website,
        description: formData.description,
        openingHours: formData.openingHours,
        priceRange: formData.priceRange,
        cuisine: formData.cuisine,
        specialties: formData.specialties,
        deliveryAvailable: formData.deliveryAvailable,
        takeoutAvailable: formData.takeoutAvailable,
        dineInAvailable: formData.dineInAvailable,
        cateringAvailable: formData.cateringAvailable,
        image: formData.image,
        featured: formData.featured,
        verified: formData.verified,
        category: 'Food'
      };
      
      const response = await fetch(`${API_URL}/api/admin/foodgrocery/${item._id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(submitData)
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Failed to update listing');
      }

      const data = await response.json();
      console.debug('EditFoodGroceryModal: update response', data);
      // pass updated item back to parent so it can update immediately
      onSuccess && onSuccess(data);
    } catch (err) {
      setError(err.message);
      console.error('Error updating listing:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content food-grocery-modal">
        <div className="modal-header">
          <h2>Edit Food & Grocery Listing</h2>
          <button className="close-btn" onClick={onClose} disabled={loading}>
            <X size={24} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="add-listing-form">
          {error && (
            <div className="error-message">
              {error}
            </div>
          )}

          {/* Basic Information */}
          <div className="form-section">
            <h3 className="section-title">Basic Information</h3>
            
            <div className="form-row">
              <div className="form-group">
                <label>Name <span className="required">*</span></label>
                <input
                  type="text"
                  name="title"
                  placeholder="Restaurant or Grocery Store name"
                  value={formData.title}
                  onChange={handleChange}
                  required
                />
              </div>
              <div className="form-group">
                <label>Category <span className="required">*</span></label>
                <select
                  name="subCategory"
                  value={formData.subCategory}
                  onChange={handleChange}
                  required
                >
                  <option value="Restaurant">Restaurant</option>
                  <option value="Grocery Store">Grocery Store</option>
                  <option value="Bakery">Bakery</option>
                  <option value="Cafe">Cafe</option>
                  <option value="Supermarket">Supermarket</option>
                  <option value="Food Truck">Food Truck</option>
                  <option value="Deli">Deli</option>
                </select>
              </div>
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Type</label>
                <input
                  type="text"
                  name="type"
                  placeholder="e.g., Indian, Italian, Organic, Veg/Non-Veg"
                  value={formData.type}
                  onChange={handleChange}
                />
              </div>
              <div className="form-group">
                <label>Price Range</label>
                <select
                  name="priceRange"
                  value={formData.priceRange}
                  onChange={handleChange}
                >
                  <option value="$">$ - Budget Friendly</option>
                  <option value="$$">$$ - Moderate</option>
                  <option value="$$$">$$$ - Expensive</option>
                  <option value="$$$$">$$$$ - Very Expensive</option>
                </select>
              </div>
            </div>
          </div>

          {/* Location */}
          <div className="form-section">
            <h3 className="section-title">
              <MapPin size={18} />
              Location Details
            </h3>
            
            <div className="form-group">
              <label>Address <span className="required">*</span></label>
              <input
                type="text"
                name="address"
                placeholder="Street address"
                value={formData.address}
                onChange={handleChange}
                required
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>City <span className="required">*</span></label>
                <input
                  type="text"
                  name="city"
                  placeholder="Munich"
                  value={formData.city}
                  onChange={handleChange}
                  required
                />
              </div>
              <div className="form-group">
                <label>State/Region</label>
                <input
                  type="text"
                  name="state"
                  placeholder="Bavaria"
                  value={formData.state}
                  onChange={handleChange}
                />
              </div>
              <div className="form-group">
                <label>Zip Code</label>
                <input
                  type="text"
                  name="zipCode"
                  placeholder="80331"
                  value={formData.zipCode}
                  onChange={handleChange}
                />
              </div>
            </div>
          </div>

          {/* Contact Information */}
          <div className="form-section">
            <h3 className="section-title">
              <Phone size={18} />
              Contact Information
            </h3>
            
            <div className="form-row">
              <div className="form-group">
                <label>Phone</label>
                <input
                  type="tel"
                  name="phone"
                  placeholder="+49 123 456 7890"
                  value={formData.phone}
                  onChange={handleChange}
                />
              </div>
              <div className="form-group">
                <label>Email</label>
                <input
                  type="email"
                  name="email"
                  placeholder="contact@restaurant.com"
                  value={formData.email}
                  onChange={handleChange}
                />
              </div>
            </div>

            <div className="form-group">
              <label>Website</label>
              <input
                type="url"
                name="website"
                placeholder="https://www.restaurant.com"
                value={formData.website}
                onChange={handleChange}
              />
            </div>
          </div>

          {/* Description & Hours */}
          <div className="form-section">
            <h3 className="section-title">Details</h3>
            
            <div className="form-group">
              <label>Description</label>
              <textarea
                name="description"
                placeholder="Enter a detailed description..."
                value={formData.description}
                onChange={handleChange}
                rows={4}
              />
            </div>

            <div className="form-group">
              <label>
                <Clock size={18} />
                Opening Hours
              </label>
              <input
                type="text"
                name="openingHours"
                placeholder="e.g., Mon-Fri: 9:00 AM - 10:00 PM, Sat-Sun: 10:00 AM - 11:00 PM"
                value={formData.openingHours}
                onChange={handleChange}
              />
            </div>
          </div>

          {/* Cuisine Types */}
          <div className="form-section">
            <h3 className="section-title">Cuisine & Specialties</h3>
            
            <div className="form-group">
              <label>Cuisine Types</label>
              <div className="tag-input-container">
                <input
                  type="text"
                  placeholder="Add cuisine type (e.g., Indian, Italian)"
                  value={cuisineInput}
                  onChange={(e) => setCuisineInput(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleAddCuisine(e)}
                />
                <button 
                  type="button" 
                  className="add-tag-btn"
                  onClick={handleAddCuisine}
                >
                  Add
                </button>
              </div>
              <div className="tags-list">
                {formData.cuisine.map((cuisine, idx) => (
                  <span key={idx} className="tag">
                    {cuisine}
                    <button 
                      type="button"
                      onClick={() => handleRemoveCuisine(cuisine)}
                    >
                      ×
                    </button>
                  </span>
                ))}
              </div>
            </div>

            <div className="form-group">
              <label>Specialties</label>
              <div className="tag-input-container">
                <input
                  type="text"
                  placeholder="Add specialty item"
                  value={specialtyInput}
                  onChange={(e) => setSpecialtyInput(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleAddSpecialty(e)}
                />
                <button 
                  type="button" 
                  className="add-tag-btn"
                  onClick={handleAddSpecialty}
                >
                  Add
                </button>
              </div>
              <div className="tags-list">
                {formData.specialties.map((specialty, idx) => (
                  <span key={idx} className="tag">
                    {specialty}
                    <button 
                      type="button"
                      onClick={() => handleRemoveSpecialty(specialty)}
                    >
                      ×
                    </button>
                  </span>
                ))}
              </div>
            </div>
          </div>

          {/* Services & Features */}
          <div className="form-section">
            <h3 className="section-title">Services Available</h3>
            
            <div className="checkbox-group">
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  name="dineInAvailable"
                  checked={formData.dineInAvailable}
                  onChange={handleChange}
                />
                <span>Dine-in</span>
              </label>
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  name="deliveryAvailable"
                  checked={formData.deliveryAvailable}
                  onChange={handleChange}
                />
                <span>Home Delivery</span>
              </label>
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  name="takeoutAvailable"
                  checked={formData.takeoutAvailable}
                  onChange={handleChange}
                />
                <span>Takeout</span>
              </label>
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  name="cateringAvailable"
                  checked={formData.cateringAvailable}
                  onChange={handleChange}
                />
                <span>Catering</span>
              </label>
            </div>
          </div>

          {/* Image URL */}
          <div className="form-section">
            <h3 className="section-title">
              <Upload size={18} />
              Image
            </h3>
            
            <div className="form-group">
              <label>Image URL</label>
              <input
                type="url"
                name="image"
                placeholder="https://example.com/image.jpg"
                value={formData.image}
                onChange={handleChange}
              />
              <p className="form-help">Enter the URL of the restaurant/store image</p>
              {formData.image && (
                <div className="image-preview">
                  <img src={formData.image} alt="Preview" />
                </div>
              )}
            </div>
          </div>

          {/* Form Actions */}
          <div className="form-actions">
            <button 
              type="button" 
              className="cancel-btn" 
              onClick={onClose}
              disabled={loading}
            >
              Cancel
            </button>
            <button 
              type="submit" 
              className="create-btn"
              disabled={loading}
            >
              {loading ? 'Updating...' : 'Update Listing'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default EditFoodGroceryModal;
