import React, { useState } from "react";
import { X } from "lucide-react";
import API_URL from '../config';

const DEFAULT_AMENITIES = ["WiFi", "Parking", "Balcony", "Garden", "Elevator"];

const SimpleAddListingModal = ({ onClose, onSuccess }) => {
  const [form, setForm] = useState({
    title: "",
    category: "Accommodation",
    propertyType: "Apartment",
    location: "",
    contact: "",
    description: "",
    price: "",
    status: "Active",
  });

  const handleCategoryChange = (e) => {
    const cat = e.target.value;
    setForm((prev) => ({
      ...prev,
      category: cat,
      propertyType: cat === "Accommodation" ? "Apartment" : "",
    }));
  };

  const [selectedAmenities, setSelectedAmenities] = useState([]);
  const [customAmenity, setCustomAmenity] = useState("");
  const [images, setImages] = useState([]);
  const [previews, setPreviews] = useState([]);
  const [submitting, setSubmitting] = useState(false);

  const handleChange = (e) =>
    setForm({ ...form, [e.target.name]: e.target.value });

  const toggleAmenity = (amenity) => {
    setSelectedAmenities((prev) =>
      prev.includes(amenity)
        ? prev.filter((a) => a !== amenity)
        : [...prev, amenity]
    );
  };

  const addCustomAmenity = () => {
    const trimmed = customAmenity.trim();
    if (trimmed && !selectedAmenities.includes(trimmed)) {
      setSelectedAmenities([...selectedAmenities, trimmed]);
      setCustomAmenity("");
    }
  };

  const handleImageUpload = (e) => {
    const files = Array.from(e.target.files).filter((f) =>
      ["image/png", "image/jpeg", "image/jpg"].includes(f.type)
    );
    if (files.length !== e.target.files.length) {
      alert("Only JPG, JPEG, and PNG files are allowed.");
    }
    setImages(files);
    setPreviews(files.map((f) => URL.createObjectURL(f)));
    e.target.value = "";
  };

  const removeImage = (idx) => {
    setImages((prev) => prev.filter((_, i) => i !== idx));
    setPreviews((prev) => prev.filter((_, i) => i !== idx));
  };

  const validate = () => {
    if (!form.title.trim()) return "Title is required";
    if (!form.location.trim()) return "Location is required";
    if (!form.contact.trim()) return "Contact is required";
    if (!form.description.trim()) return "Description is required";
    if (!form.price.trim()) return "Price is required";
    return null;
  };

  const toBase64 = (file) =>
    new Promise((resolve, reject) => {
      const r = new FileReader();
      r.onloadend = () => resolve(r.result);
      r.onerror = reject;
      r.readAsDataURL(file);
    });

  const handleSubmit = async () => {
    const err = validate();
    if (err) { alert(err); return; }

    setSubmitting(true);
    try {
      const token = localStorage.getItem("adminToken");

      // Convert image files to base64 so we can send JSON
      const base64Images = await Promise.all(images.map(toBase64));

      const payload = {
        title: form.title.trim(),
        city: form.location.trim(),
        propertyType: form.propertyType || undefined,
        contactPhone: form.contact.trim(),
        description: form.description.trim(),
        status: form.status.toLowerCase(),
        rentDetails: { warmRent: parseFloat(form.price) || 0 },
        amenities: selectedAmenities.reduce((acc, a) => {
          const key = a.toLowerCase().replace(/\s+/g, "_");
          acc[key] = true;
          return acc;
        }, {}),
        media: { images: base64Images },
        adminControls: { isActive: form.status.toLowerCase() === "active" },
      };

      const res = await fetch(`${API_URL}/api/accommodation/admin`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        onSuccess && onSuccess();
        onClose();
      } else {
        const data = await res.json().catch(() => ({}));
        alert("Error: " + (data.message || "Failed to create listing"));
      }
    } catch (ex) {
      alert("Error connecting to server: " + ex.message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div
        className="modal-content modal-large"
        style={{ maxHeight: "90vh", overflowY: "auto" }}
      >
        {/* Header */}
        <div className="modal-header">
          <h2>Add New Listing</h2>
          <button className="close-btn" onClick={onClose}>
            <X size={22} />
          </button>
        </div>

        <div className="add-listing-form">
          {/* Row 1: Title + Category */}
          <div className="form-row">
            <div className="form-group">
              <label>
                Title <span style={{ color: "red" }}>*</span>
              </label>
              <input
                name="title"
                placeholder="Room"
                value={form.title}
                onChange={handleChange}
              />
            </div>
            <div className="form-group">
              <label>Category</label>
              <select name="category" value={form.category} onChange={handleCategoryChange}>
                <option>Accommodation</option>
                <option>Food</option>
                <option>Jobs</option>
                <option>Services</option>
              </select>
            </div>
          </div>

          {/* Property Type — only for Accommodation */}
          {form.category === "Accommodation" && (
            <div className="form-row">
              <div className="form-group">
                <label>
                  Property Type <span style={{ color: "red" }}>*</span>
                </label>
                <select name="propertyType" value={form.propertyType} onChange={handleChange}>
                  <option value="Apartment">Apartment</option>
                  <option value="Shared Room">Shared Room</option>
                  <option value="Temporary Stays">Temporary Stays</option>
                </select>
              </div>
            </div>
          )}

          {/* Row 2: Location + Contact */}
          <div className="form-row">
            <div className="form-group">
              <label>
                Location <span style={{ color: "red" }}>*</span>
              </label>
              <input
                name="location"
                placeholder="Munich"
                value={form.location}
                onChange={handleChange}
              />
            </div>
            <div className="form-group">
              <label>
                Contact <span style={{ color: "red" }}>*</span>
              </label>
              <input
                name="contact"
                placeholder="+49 52148 765397"
                value={form.contact}
                onChange={handleChange}
              />
            </div>
          </div>

          {/* Description */}
          <div className="form-group">
            <label>
              Description <span style={{ color: "red" }}>*</span>
            </label>
            <textarea
              name="description"
              rows={3}
              placeholder="Enter Description"
              value={form.description}
              onChange={handleChange}
            />
          </div>

          {/* Row 3: Price + Status */}
          <div className="form-row">
            <div className="form-group">
              <label>
                Price <span style={{ color: "red" }}>*</span>
              </label>
              <input
                name="price"
                placeholder="€1,000/month"
                value={form.price}
                onChange={handleChange}
              />
            </div>
            <div className="form-group">
              <label>Status</label>
              <select name="status" value={form.status} onChange={handleChange}>
                <option value="Active">Active</option>
                <option value="Pending">Pending</option>
                <option value="Inactive">Inactive</option>
              </select>
            </div>
          </div>

          {/* Amenities */}
          <div className="form-group">
            <label>Amenities</label>
            <p style={{ fontSize: 12, color: "#6b7280", marginBottom: 8, marginTop: 0 }}>
              Enter any Amenities or Choose Below
            </p>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginBottom: 10 }}>
              {[...DEFAULT_AMENITIES, ...selectedAmenities.filter(
                (a) => !DEFAULT_AMENITIES.includes(a)
              )].map((amenity) => (
                <button
                  key={amenity}
                  type="button"
                  onClick={() => toggleAmenity(amenity)}
                  style={{
                    padding: "5px 14px",
                    borderRadius: 20,
                    fontSize: 13,
                    cursor: "pointer",
                    border: "1px solid #6b9976",
                    background: selectedAmenities.includes(amenity) ? "#6b9976" : "#fff",
                    color: selectedAmenities.includes(amenity) ? "#fff" : "#374151",
                    fontWeight: 500,
                  }}
                >
                  {amenity}
                </button>
              ))}
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              <input
                placeholder="Type custom amenity…"
                value={customAmenity}
                onChange={(e) => setCustomAmenity(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") { e.preventDefault(); addCustomAmenity(); }
                }}
                style={{ flex: 1 }}
              />
              <button
                type="button"
                onClick={addCustomAmenity}
                style={{
                  padding: "7px 14px",
                  background: "#6b9976",
                  color: "#fff",
                  border: "none",
                  borderRadius: 6,
                  cursor: "pointer",
                  fontWeight: 600,
                }}
              >
                Add
              </button>
            </div>
          </div>

          {/* Image Upload */}
          <div className="form-group">
            <label>
              Photos{" "}
              <span style={{ color: "#6b7280", fontSize: 12 }}>
                (JPG, JPEG, PNG)
              </span>
            </label>
            <input
              type="file"
              multiple
              accept=".png,.jpg,.jpeg,image/jpeg,image/png"
              onChange={handleImageUpload}
            />
            {previews.length > 0 && (
              <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 8 }}>
                {previews.map((src, i) => (
                  <div key={i} style={{ position: "relative" }}>
                    <img
                      src={src}
                      alt={`preview-${i}`}
                      style={{
                        width: 80,
                        height: 65,
                        objectFit: "cover",
                        borderRadius: 6,
                        border: "2px solid #6b9976",
                      }}
                    />
                    <button
                      type="button"
                      onClick={() => removeImage(i)}
                      style={{
                        position: "absolute",
                        top: -6,
                        right: -6,
                        background: "#ef4444",
                        color: "#fff",
                        border: "none",
                        borderRadius: "50%",
                        width: 18,
                        height: 18,
                        fontSize: 11,
                        cursor: "pointer",
                        padding: 0,
                        lineHeight: "18px",
                        textAlign: "center",
                      }}
                    >
                      ✕
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="form-actions">
            <button
              type="button"
              className="cancel-btn"
              onClick={onClose}
              disabled={submitting}
            >
              Cancel
            </button>
            <button
              type="button"
              className="create-btn"
              onClick={handleSubmit}
              disabled={submitting}
            >
              {submitting ? "Creating…" : "Create"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SimpleAddListingModal;
