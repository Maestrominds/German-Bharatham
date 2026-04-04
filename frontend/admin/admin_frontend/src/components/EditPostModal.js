import React, { useState, useEffect } from "react";
import { X, Upload } from "lucide-react";
import API_URL from '../config';

const EditPostModal = ({ post, onClose, onPostUpdated }) => {
  const [postData, setPostData] = useState({
    title: "",
    category: "",
    readTime: "",
    content: "",
  });

  const BASE = API_URL;

  // 🔥 Convert DB data back into textarea format
  const buildContentString = (post) => {
    return `
${post.description || ""}

KEYPOINTS:
${(post.keyPoints || []).join("\n")}

OFFICIAL:
${post.officialWebsites || ""}

COMMUNITY:
${post.communityDiscussions || ""}

AUTHOR:
${post.author || ""}
    `.trim();
  };

  // 🔥 Load existing data into form
  useEffect(() => {
    if (post) {
      setPostData({
        title: post.title,
        category: post.category,
        readTime: post.readTime,
        content: buildContentString(post),
      });
    }
  }, [post]);

  // 🔥 Parse textarea content again before updating
  const parseContent = (content) => {
    const description = content.split("KEYPOINTS:")[0].trim();

    const keyPointsSection =
      content.split("KEYPOINTS:")[1]?.split("OFFICIAL:")[0] || "";

    const keyPoints = keyPointsSection
      .split("\n")
      .map((k) => k.trim())
      .filter((k) => k.length > 0);

    const officialWebsites =
      content.split("OFFICIAL:")[1]?.split("COMMUNITY:")[0]?.trim() || "";

    const communityDiscussions =
      content.split("COMMUNITY:")[1]?.split("AUTHOR:")[0]?.trim() || "";

    const author =
      content.split("AUTHOR:")[1]?.trim() || "German Bharatham Team";

    return {
      description,
      keyPoints,
      officialWebsites,
      communityDiscussions,
      author,
    };
  };

  const handleUpdate = async (e) => {
    e.preventDefault();

    const token = localStorage.getItem("adminToken");
    const parsed = parseContent(postData.content);

    try {
      const response = await fetch(
        `${BASE}/api/admin/community/${post._id}`,
        {
          method: "PUT",   // 🔥 IMPORTANT
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            title: postData.title,
            category: postData.category,
            readTime: Number(postData.readTime),
            ...parsed,
          }),
        }
      );

      const data = await response.json();

      if (!response.ok) {
        alert(data.message);
        return;
      }

      alert("Post Updated Successfully ✅");

      if (onPostUpdated) {
        await onPostUpdated();
      }

      onClose();
    } catch (error) {
      console.error(error);
      alert("Error updating post ❌");
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content create-post-modal">
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
              onChange={(e) =>
                setPostData({ ...postData, title: e.target.value })
              }
              required
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Category</label>
              <select
                value={postData.category}
                onChange={(e) =>
                  setPostData({ ...postData, category: e.target.value })
                }
                required
              >
                <option value="Guide">Guide</option>
                <option value="Announcement">Announcement</option>
                <option value="News">News</option>
                <option value="Tips">Tips</option>
              </select>
            </div>

            <div className="form-group">
              <label>Estimated Read Time</label>
              <input
                type="number"
                value={postData.readTime}
                onChange={(e) =>
                  setPostData({ ...postData, readTime: e.target.value })
                }
                min="1"
                required
              />
            </div>
          </div>

          <div className="form-group">
            <label>Content</label>
            <textarea
            rows={12}
              value={postData.content}
              onChange={(e) =>
                setPostData({ ...postData, content: e.target.value })
              }
              required
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
