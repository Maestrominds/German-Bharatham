import React from 'react';
import GenericCategoryListings from './GenericCategoryListings';
import API_URL from '../config';

const FOOD_FIELDS = {
  title: 'title',
  subKey: 'subCategory',
  subLabel: 'SUB CATEGORY',
  rows: [
    ['Name', 'title'],
    ['Sub Category', 'subCategory'],
    ['Type', 'type'],
    ['City', 'city'],
    ['State', 'state'],
    ['Zip Code', 'zipCode'],
    ['Address', 'address'],
    ['Phone', 'phone'],
    ['Email', 'email'],
    ['Website', 'website'],
    ['Price Range', 'priceRange'],
    ['Opening Hours', 'openingHours'],
    ['Cuisine', 'cuisine'],
    ['Specialties', 'specialties'],
    ['Description', 'description'],
    ['Status', 'status'],
  ],
};

export default function FoodListings() {
  return (
    <GenericCategoryListings
      category="Food"
      apiBase={`${API_URL}/api/admin/foodgrocery`}
      icon="🍴"
      viewFields={FOOD_FIELDS}
    />
  );
}
