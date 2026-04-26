import React, { useState, useEffect } from "react";
import { X, Upload } from "lucide-react";
import API_URL from '../config';

const EditPostModal = ({ post, onClose, onPostUpdated }) => {
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

  const BASE = API_URL;

  // 🔥 Load existing data into form
  useEffect(() => {
    if (post) {
      setPostData({
        title: post.title || "",
        category: post.category || "Guide",
        readTime: post.readTime || "5",
        description: post.description || "",
        keyPoints: Array.isArray(post.keyPoints) ? post.keyPoints.join("\n") : "",
        officialWebsites: post.officialWebsites || "",
        communityDiscussions: post.communityDiscussions || "",
        author: post.author || "German Bharatham Team",
      });
    }
  }, [post]);

  const handleUpdate = async (e) => {
    e.preventDefault();

    const token = localStorage.getItem("adminToken");
    
    // Convert keyPoints back to array
    const keyPointsArray = postData.keyPoints
      .split("\n")
      .map((k) => k.trim())
      .filter((k) => k.length > 0);

    try {
      const response = await fetch(
        `${BASE}/api/admin/community/${post._id}`,
        {
          method: "PUT",
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
          }),
        }
      );

      const data = await response.json();

      if (!response.ok) {
        alert(data.message);
        return;
      }

      alert("Post Updated Successfully ✅");
      if (onPostUpdated) await onPostUpdated();
      onClose();
    } catch (error) {
      console.error(error);
      alert("Error updating post ❌");
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content create-post-modal" style={{ maxWidth: '700px', width: '90%' }}>
        <div className="modal-header">
          <div>
            <h2>Edit Post</h2>
            <p>Update community post details</p>
          </div>
          <button className="close-btn" onClick={onClose}>
            <X size={24} />
          </button>
        </div>

        <form onSubmit={handleUpdate} className="create-post-form">
          <div className="form-group">
            <label>Title</label>
            <input
              type="text"
              value={postData.title}
              onChange={(e) => setPostData({ ...postData, title: e.target.value })}
              required
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Category</label>
              <select
                value={postData.category}
                onChange={(e) => setPostData({ ...postData, category: e.target.value })}
                required
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
                required
              />
            </div>
          </div>

          <div className="form-group">
            <label>Description (Short Intro)</label>
            <textarea
              rows={3}
              value={postData.description}
              onChange={(e) => setPostData({ ...postData, description: e.target.value })}
              required
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
              <label>Official Resource Link</label>
              <input
                type="url"
                value={postData.officialWebsites}
                onChange={(e) => setPostData({ ...postData, officialWebsites: e.target.value })}
                placeholder="https://..."
              />
            </div>
            <div className="form-group">
              <label>Community Link / Discussion</label>
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
            <button type="submit" className="publish-btn">
              <Upload size={20} />
              Update Post
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default EditPostModal;
