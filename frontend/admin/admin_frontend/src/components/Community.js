import React, { useState, useEffect } from "react";
import { Plus, ChevronRight } from "lucide-react";
import CreatePostModal from "./CreatePostModal";
import EditPostModal from "./EditPostModal";
import API_URL from '../config';

const Community = () => {
  const [view, setView] = useState("list");
  const [posts, setPosts] = useState([]);
  const [selectedPost, setSelectedPost] = useState(null);
  const [showEditModal, setShowEditModal] = useState(false);

  const BASE = API_URL;

  useEffect(() => {
    fetchPosts();
  }, []);

  const fetchPosts = async () => {
    try {
      const response = await fetch(`${BASE}/api/community?limit=100&page=1`);
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
        onClose={() => {
          setView("list");
          fetchPosts();
        }}
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
        {posts.map((post) => (
          <div key={post._id} className="post-item">

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

            {/* Edit Button */}
            <div className="post-actions">
              <button
                className="action-btn chevron-btn"
                onClick={() => handleEditClick(post)}
              >
                <ChevronRight size={20} />
              </button>
            </div>

          </div>
        ))}
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
