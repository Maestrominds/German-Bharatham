import React, { useEffect, useState } from "react";
import axios from "axios";
import { Edit, Trash2 } from "lucide-react";
import AddListingModal from "./AddListingModal";

const JobListings = () => {
  const [jobs, setJobs] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [editJob, setEditJob] = useState(null);

  const fetchJobs = async () => {
    try {
      const res = await axios.get(
        "https://german-bharatham-backend.onrender.com/api/admin/jobs"
      );
      setJobs(res.data);
    } catch (error) {
      console.error(error);
    }
  };

  useEffect(() => {
    fetchJobs();
  }, []);

  const handleEdit = (job) => {
    setEditJob(job);
    setShowModal(true);
  };

  const handleDelete = async (id) => {
    try {
      await axios.delete(
        `https://german-bharatham-backend.onrender.com/api/admin/jobs/${id}`
      );
      fetchJobs();
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <div className="listings">
      <div className="listings-header">
        <div>
          <h1>Jobs</h1>
          <p>Manage all your job listings in one place.</p>
        </div>
        <div className="listings-filters">
          <select className="filter-select">
            <option>Newest first</option>
            <option>Oldest first</option>
            <option>A-Z</option>
            <option>Z-A</option>
          </select>
          <button className="add-listing-btn"
            onClick={() => {
              setEditJob(null);
              setShowModal(true);
            }}
          >
            + New Job
          </button>
        </div>
      </div>

      <table>
        <thead>
          <tr>
            <th>TITLE</th>
            <th>CATEGORY</th>
            <th>LOCATION</th>
            <th>STATUS</th>
            <th>CREATED</th>
            <th>ACTION</th>
          </tr>
        </thead>

        <tbody>
          {jobs.map((job) => (
            <tr key={job._id}>
              <td>{job.title}</td>
              <td>{job.category}</td>
              <td>{job.location}</td>
              <td>
                <span className={`status ${job.status?.toLowerCase()}`}>
                  {job.status}
                </span>
              </td>
              <td>{new Date(job.createdAt).toISOString().split('T')[0]}</td>
              <td>
                <button className="action-btn edit-btn" onClick={() => handleEdit(job)} title="Edit">
                  <Edit size={16} />
                </button>

                <button className="action-btn delete-btn" onClick={() => handleDelete(job._id)} title="Delete">
                  <Trash2 size={16} />
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {showModal && (
        <AddListingModal
          onClose={() => setShowModal(false)}
          refreshJobs={fetchJobs}
          editJob={editJob}
        />
      )}
    </div>
  );
};

export default JobListings;
