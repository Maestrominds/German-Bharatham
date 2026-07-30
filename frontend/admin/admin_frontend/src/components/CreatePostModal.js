import React, { useState } from 'react';
import { X, Upload } from 'lucide-react';
import API_URL from '../config';

const CreatePostModal = ({ onClose, onPostCreated }) => {
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState(null);
  const [postData, setPostData] = useState({
    title: "",
    category: "Guide",
    readTime: "5",
    description: "",
    keyPoints: "",
    officialWebsites: "",
    communityDiscussions: "",
    author: "German Bharatham Team"
  });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setStatus(null);

    const token = localStorage.getItem("adminToken");
    
    // Convert keyPoints back to array
    const keyPointsArray = postData.keyPoints
      .split("\n")
      .map((k) => k.trim())
      .filter((k) => k.length > 0);

    try {
      const response = await fetch(`${API_URL}/api/admin/community`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          title: postData.title,
          category: postData.category,
          readTime: Number(postData.readTime),
          description: postData.description,
          keyPoints: keyPointsArray,
          officialWebsites: postData.officialWebsites,
          communityDiscussions: postData.communityDiscussions,
          author: postData.author,
          date: new Date().toDateString(),
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        setStatus({ type: 'error', message: data.message || "Failed to create post." });
        setLoading(false);
        return;
      }

      setStatus({ type: 'success', message: "Post Created Successfully ✅" });
      if (onPostCreated) await onPostCreated();
      
      setTimeout(() => {
        onClose();
      }, 1500);
    } catch (error) {
      console.error(error);
      setStatus({ type: 'error', message: "Error creating post ❌" });
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content create-post-modal" style={{ maxWidth: '700px', width: '90%' }}>
        <div className="modal-header">
          <div>
            <h2>Create New Post</h2>
            <p>Create a new post for the community</p>
          </div>
          <button className="close-btn" onClick={onClose}>
            <X size={24} />
          </button>
        </div>

        {status && (
          <div style={{
            margin: '0 24px', padding: '12px', borderRadius: '6px', fontSize: '14px',
            backgroundColor: status.type === 'error' ? '#fef2f2' : '#f0fdf4',
            color: status.type === 'error' ? '#991b1b' : '#166534',
            border: `1px solid ${status.type === 'error' ? '#fecaca' : '#bbf7d0'}`
          }}>
            {status.message}
          </div>
        )}

        <form onSubmit={handleSubmit} className="create-post-form">
          <div className="form-group">
            <label>Title</label>
            <input
              type="text"
              placeholder="e.g., Complete Guide to Germany - Anmeldung"
              value={postData.title}
              onChange={(e) => setPostData({ ...postData, title: e.target.value })}
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Category</label>
              <select
                value={postData.category}
                onChange={(e) => setPostData({ ...postData, category: e.target.value })}
              >
                <option value="Guide">Guide</option>
                <option value="Announcement">Announcement</option>
                <option value="News">News</option>
                <option value="Tips">Tips</option>
              </select>
            </div>

            <div className="form-group">
              <label>Estimated Read Time (min)</label>
              <input
                type="number"
                value={postData.readTime}
                onChange={(e) => setPostData({ ...postData, readTime: e.target.value })}
                min="1"
              />
            </div>
          </div>

          <div className="form-group">
            <label>Description (Short Intro)</label>
            <textarea
              rows={3}
              value={postData.description}
              onChange={(e) => setPostData({ ...postData, description: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label>Key Points (One per line)</label>
            <textarea
              rows={5}
              value={postData.keyPoints}
              onChange={(e) => setPostData({ ...postData, keyPoints: e.target.value })}
              placeholder="Point 1&#10;Point 2&#10;Point 3"
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Official Resource Link <span style={{ color: '#aaa', fontWeight: 400 }}>(optional)</span></label>
              <input
                type="url"
                value={postData.officialWebsites}
                onChange={(e) => setPostData({ ...postData, officialWebsites: e.target.value })}
                placeholder="https://..."
              />
            </div>
            <div className="form-group">
              <label>Community Link / Discussion <span style={{ color: '#aaa', fontWeight: 400 }}>(optional)</span></label>
              <input
                type="url"
                value={postData.communityDiscussions}
                onChange={(e) => setPostData({ ...postData, communityDiscussions: e.target.value })}
                placeholder="https://..."
              />
            </div>
          </div>

          <div className="form-group">
            <label>Author Name</label>
            <input
              type="text"
              value={postData.author}
              onChange={(e) => setPostData({ ...postData, author: e.target.value })}
            />
          </div>

          <div className="form-actions">
            <button type="submit" className="publish-btn" disabled={loading} style={{ opacity: loading ? 0.7 : 1 }}>
              <Upload size={20} />
              {loading ? "Publishing..." : "Publish Post"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CreatePostModal;
