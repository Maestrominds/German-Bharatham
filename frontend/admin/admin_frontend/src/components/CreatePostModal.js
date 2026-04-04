import React, { useState } from 'react';
import { X, Upload } from 'lucide-react';
import API_URL from '../config';

const CreatePostModal = ({ onClose, onPostCreated }) => {
  const [postData, setPostData] = useState({
  title: "",
  category: "",
  readTime: "",
  content: ""   // 🔥 ADD THIS
});

const parseContent = (content) => {
  const description = content.split("KEYPOINTS:")[0].trim();

  const keyPointsSection = content.split("KEYPOINTS:")[1]?.split("OFFICIAL:")[0] || "";
  const keyPoints = keyPointsSection
    .split("\n")
    .map(k => k.trim())
    .filter(k => k.length > 0);

  const officialWebsites = content.split("OFFICIAL:")[1]?.split("COMMUNITY:")[0]?.trim() || "";

  const communityDiscussions = content.split("COMMUNITY:")[1]?.split("AUTHOR:")[0]?.trim() || "";

  const author = content.split("AUTHOR:")[1]?.trim() || "German Bharatham Team";

  return {
    description,
    keyPoints,
    officialWebsites,
    communityDiscussions,
    author
  };
};

const handleSubmit = async (e) => {
  e.preventDefault();

  const token = localStorage.getItem("adminToken");
  console.log("TOKEN:", token);

  const parsed = parseContent(postData.content);

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
        ...parsed,
        date: new Date().toDateString(),
      }),
    });

    const data = await response.json();

    if (!response.ok) {
  alert(data.message);
  return;
}

alert("Post Created Successfully ✅");

// Refresh posts in parent page
if (onPostCreated) {
  await onPostCreated();
}

// Close modal
onClose();

  } catch (error) {
    console.error(error);
    alert("Error creating post ❌");
  }
};
  return (
    <div className="modal-overlay">
      <div className="modal-content create-post-modal">
        <div className="modal-header">
          <div>
            <h2>Create New Post</h2>
            <p>Create a new post for the community</p>
          </div>
          <div className="header-actions">
            <button className="show-all-btn">Show All Posts</button>
            <button className="close-btn" onClick={onClose}>
              <X size={24} />
            </button>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="create-post-form">
          <div className="form-group">
            <label>Title</label>
            <input
              type="text"
              placeholder="e.g., Complete Guide to Germany - Anmeldung"
              value={postData.title}
              onChange={(e) => setPostData(prev => ({...prev, title: e.target.value}))}
              required
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Category</label>
              <select
  value={postData.category}
  onChange={(e) =>
    setPostData(prev => ({ ...prev, category: e.target.value }))
  }
  required
>
  <option value="">Select Category</option>
  <option value="Guide">Guide</option>
  <option value="Announcement">Announcement</option>
  <option value="News">News</option>
  <option value="Tips">Tips</option>
</select>
            </div>
            <div className="form-group">
              <label>Estimated Read Time (minutes)</label>
              <input
  type="number"
  placeholder="Enter read time in minutes"
  value={postData.readTime}
  onChange={(e) =>
    setPostData(prev => ({ ...prev, readTime: e.target.value }))
  }
  min="1"
  required
/>
            </div>
          </div>

          <div className="form-group">
            <label>Content</label>
            <textarea rows={10} value={postData.content} onChange={(e) =>setPostData({ ...postData, content: e.target.value })}/>
          </div>

          <div className="form-actions">
            <button type="submit" className="publish-btn">
              <Upload size={20} />
              Publish Post
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CreatePostModal;
