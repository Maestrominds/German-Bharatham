import React, { useState, useEffect, useCallback } from "react";
import { Plus, ChevronRight, Trash2 } from "lucide-react";
import CreatePostModal from "./CreatePostModal";
import EditPostModal from "./EditPostModal";
import API_URL from '../config';

const Community = () => {
  const [view, setView] = useState("list");
  const [posts, setPosts] = useState([]);
  const [selectedPost, setSelectedPost] = useState(null);
  const [showEditModal, setShowEditModal] = useState(false);
  const [deletingId, setDeletingId] = useState(null);

  const BASE = API_URL;

  const fetchPosts = useCallback(async () => {
    try {
      const response = await fetch(`${BASE}/api/admin/community`);
      const payload = await response.json();
      const list = Array.isArray(payload)
        ? payload
        : Array.isArray(payload?.data)
          ? payload.data
          : [];
      setPosts(list);
    } catch (error) {
      console.error("Error fetching posts:", error);
    }
  }, [BASE]);

  useEffect(() => {
    fetchPosts();
  }, [fetchPosts]);

  // 🔥 Delete Post
  const handleDelete = async (e, post) => {
    e.stopPropagation();
    const postId = post._id || post.id;
    if (!window.confirm(`Are you sure you want to delete "${post.title}"? This cannot be undone.`)) {
      return;
    }

    try {
      setDeletingId(postId);
      const token = localStorage.getItem("adminToken");
      const response = await fetch(`${BASE}/api/admin/community/${postId}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const err = await response.json().catch(() => ({}));
        alert(err.message || "Failed to delete post");
        return;
      }

      setPosts((prev) => prev.filter((p) => String(p._id || p.id) !== String(postId)));
    } catch (error) {
      console.error("Error deleting post:", error);
      alert("An error occurred while deleting the post: " + error.message);
    } finally {
      setDeletingId(null);
    }
  };

  // 🔥 Open Edit Modal
  const handleEditClick = (post) => {
    setSelectedPost(post);
    setShowEditModal(true);
  };

  // 🔥 Close Edit Modal
  const closeEditModal = () => {
    setShowEditModal(false);
    setSelectedPost(null);
  };

  // 🔥 CREATE VIEW
  if (view === "create") {
    return (
      <CreatePostModal
        onClose={() => setView("list")}
        onPostCreated={fetchPosts}
      />
    );
  }

  return (
    <div className="community">
      <div className="community-header">
        <div>
          <h1>Posts by you</h1>
          <p>Posts for the community</p>
        </div>

        <button
          className="new-post-btn"
          onClick={() => setView("create")}
        >
          <Plus size={20} />
          New Post
        </button>
      </div>

      <div className="posts-list">
        {posts.map((post) => {
          const postId = post._id || post.id;
          const isDeleting = deletingId === postId;

          return (
            <div key={postId} className="post-item">

              {/* Main Post Info */}
              <div className="post-content">
                <div className="post-header">
                  <h3 className="post-title">{post.title}</h3>
                  <span
                    className={`post-category ${post.category?.toLowerCase()}`}
                  >
                    {post.category}
                  </span>
                </div>

                <div className="post-meta">
                  <span className="post-date">
                    {new Date(post.createdAt).toDateString()}
                  </span>
                  <span className="post-separator">•</span>
                  <span className="post-read-time">
                    {post.readTime} min read
                  </span>
                </div>
              </div>

              {/* Action Buttons: Delete & Edit */}
              <div className="post-actions">
                <button
                  className="action-btn delete-btn"
                  title="Delete Post"
                  onClick={(e) => handleDelete(e, post)}
                  disabled={isDeleting}
                  style={{
                    opacity: isDeleting ? 0.5 : 1,
                    cursor: isDeleting ? "not-allowed" : "pointer"
                  }}
                >
                  <Trash2 size={18} />
                </button>
                <button
                  className="action-btn chevron-btn"
                  title="Edit Post"
                  onClick={() => handleEditClick(post)}
                >
                  <ChevronRight size={20} />
                </button>
              </div>

            </div>
          );
        })}
      </div>

      {/* 🔥 EDIT MODAL */}
      {showEditModal && selectedPost && (
        <EditPostModal
          post={selectedPost}
          onClose={closeEditModal}
          onPostUpdated={fetchPosts}
        />
      )}
    </div>
  );
};

export default Community;
