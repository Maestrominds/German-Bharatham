import React from 'react';
import GenericCategoryListings from './GenericCategoryListings';import API_URL from '../config';
const SERVICES_FIELDS = {
  title: 'serviceName',
  subKey: 'providerName',
  subLabel: 'PROVIDER',
  rows: [
    ['Service Name', 'serviceName'],
    ['Provider', 'providerName'],
    ['Service Type', 'serviceType'],
    ['Services Offered', 'amenities'],
    ['City', 'city'],
    ['Area', 'area'],
    ['Postal Code', 'postalCode'],
    ['Address', 'address'],
    ['Contact Phone', 'contactPhone'],
    ['WhatsApp', 'whatsapp'],
    ['Email', 'email'],
    ['Website', 'website'],
    ['Latitude', 'latitude'],
    ['Longitude', 'longitude'],
    ['Price Range', 'priceRange'],
    ['Description', 'description'],
    ['Status', 'status'],
  ],
};

export default function ServicesListings() {
  return (
    <GenericCategoryListings
      category="Services"
      apiBase={`${API_URL}/api/services/admin`}
      icon="🔧"
      viewFields={SERVICES_FIELDS}
    />
  );
}
