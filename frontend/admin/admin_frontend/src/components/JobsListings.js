import React from 'react';
import GenericCategoryListings from './GenericCategoryListings';
import API_URL from '../config';

const JOBS_FIELDS = {
  title: 'title',
  subKey: 'companyName',
  subLabel: 'COMPANY',
  rows: [
    ['Job Title', 'title'],
    ['Company', 'companyName'],
    ['Job Type', 'jobType'],
    ['Location', 'location'],
    ['Contact', 'contact'],
    ['Salary', 'salary'],
    ['Requirements', 'requirements'],
    ['Benefits', 'benefits'],
    ['Apply URL', 'applyUrl'],
    ['Description', 'description'],
    ['Status', 'status'],
  ],
};

export default function JobsListings() {
  return (
    <GenericCategoryListings
      category="Jobs"
      apiBase={`${API_URL}/api/jobs/admin`}
      icon="💼"
      viewFields={JOBS_FIELDS}
    />
  );
}
