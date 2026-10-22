const express = require('express');
const router = express.Router();
const prisma = require('../config/prisma');
const { notifyListingActivated } = require('../userModule/user/services/notificationService');
const { uploadImage } = require('../services/cloudinaryService');

const adminCheck = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') return res.status(403).json({ message: 'Admin access required' });
  next();
};

const normalizeStatus = (value, fallback = 'Pending') => {
  const raw = String(value || '').trim().toLowerCase();
  if (raw === 'active') return 'Active';
  if (raw === 'pending') return 'Pending';
  if (raw === 'inactive' || raw === 'disabled') return 'Inactive';
  return fallback;
};

// Helper to map PostgreSQL Prisma job listing to match frontend _id expectations
const mapListing = (item) => {
  if (!item) return null;
  return {
    ...item,
    _id: String(item.id),
    website: item.externalUrl || null,
    externalUrl: item.externalUrl || null,
  };
};

// GET ALL (supports pagination: ?page=1&limit=20)
router.get('/', adminCheck, async (req, res) => {
  try {
    const { status } = req.query;
    const filter = status ? { status: normalizeStatus(status, String(status)) } : {};
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(200, parseInt(req.query.limit) || 10);
    const skip = (page - 1) * limit;

    const totalCount = await prisma.secondHandStore.count({ where: filter });
    const data = await prisma.secondHandStore.findMany({
      where: filter,
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });

    const mappedData = data.map(mapListing);
    res.json({ data: mappedData, count: mappedData.length, totalCount: totalCount || 0, page, limit });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// GET ONE
router.get('/:id', adminCheck, async (req, res) => {
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: 'Invalid ID format' });

    const doc = await prisma.secondHandStore.findUnique({
      where: { id: numericId }
    });
    
    if (!doc) {
      return res.status(404).json({ message: 'Not found' });
    }
    res.json(mapListing(doc));
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// CREATE
router.post('/', adminCheck, async (req, res) => {
  try {
    const { title } = req.body;
    if (!title || !title.trim()) return res.status(400).json({ message: 'Title is required' });

    req.body.status = 'Pending';
    
    let imageUrls = [];
    if (req.body.images && Array.isArray(req.body.images)) {
      const uploads = await Promise.all(
        req.body.images.map(async (base64Img) => {
          if (typeof base64Img === 'string' && base64Img.startsWith('http')) return { secure_url: base64Img };
          if (typeof base64Img !== 'string' || !base64Img.includes('base64')) return { secure_url: null };
          
          const base64Data = base64Img.replace(/^data:image\/\w+;base64,/, '');
          const buffer = Buffer.from(base64Data, 'base64');
          return uploadImage(buffer, 'second_hand_stores');
        })
      );
      imageUrls = uploads.map(r => r.secure_url).filter(url => url !== null);
    }

    const doc = await prisma.secondHandStore.create({
      data: {
        title: req.body.title,
        description: req.body.description,
        price: req.body.price,
        contactPhone: req.body.contactPhone,
        contactEmail: req.body.contactEmail,
        deliveryOption: req.body.deliveryOption,
        externalUrl: req.body.externalUrl || req.body.website || null,
        images: imageUrls,
        status: req.body.status,
        createdById: req.user ? parseInt(req.user.id, 10) : null,
        creatorType: 'admin'
      }
    });
    
    res.status(201).json(mapListing(doc));
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// UPDATE (full)
router.put('/:id', adminCheck, async (req, res) => {
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: 'Invalid ID format' });

    if (req.body && req.body.status != null) {
      req.body.status = normalizeStatus(req.body.status, req.body.status);
    }
    
    let imageUrls = [];
    if (req.body.images && Array.isArray(req.body.images)) {
      const uploads = await Promise.all(
        req.body.images.map(async (base64Img) => {
          if (typeof base64Img === 'string' && base64Img.startsWith('http')) return { secure_url: base64Img };
          if (typeof base64Img !== 'string' || !base64Img.includes('base64')) return { secure_url: null };
          
          const base64Data = base64Img.replace(/^data:image\/\w+;base64,/, '');
          const buffer = Buffer.from(base64Data, 'base64');
          return uploadImage(buffer, 'second_hand_stores');
        })
      );
      imageUrls = uploads.map(r => r.secure_url).filter(url => url !== null);
    }

    const doc = await prisma.secondHandStore.update({
      where: { id: numericId },
      data: {
        title: req.body.title,
        description: req.body.description,
        price: req.body.price,
        contactPhone: req.body.contactPhone,
        contactEmail: req.body.contactEmail,
        deliveryOption: req.body.deliveryOption,
        externalUrl: (req.body.externalUrl !== undefined ? req.body.externalUrl : req.body.website) !== undefined ? (req.body.externalUrl || req.body.website) : undefined,
        images: req.body.images !== undefined ? imageUrls : undefined,
        status: req.body.status,
      }
    });
    
    res.json(mapListing(doc));
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// PATCH status
router.patch('/:id/status', adminCheck, async (req, res) => {
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: 'Invalid ID format' });

    const { status } = req.body;
    const normalised = normalizeStatus(status, '');
    
    if (!['Active', 'Pending', 'Inactive'].includes(normalised)) return res.status(400).json({ message: 'Invalid status' });

    const before = await prisma.secondHandStore.findUnique({
      where: { id: numericId }
    });
    
    if (!before) {
      return res.status(404).json({ message: 'Not found' });
    }

    const doc = await prisma.secondHandStore.update({
      where: { id: numericId },
      data: { status: normalised }
    });

    const wasActive = String(before.status || '').toLowerCase() === 'active';
    const isActive = String(normalised || '').toLowerCase() === 'active';
    if (!wasActive && isActive) {
      notifyListingActivated({
        module: 'secondhandstore',
        entityId: String(doc.id),
        listingTitle: doc.title,
      }).catch(() => {});
    }

    res.json(mapListing(doc));
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// DELETE
router.delete('/:id', adminCheck, async (req, res) => {
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: 'Invalid ID format' });

    await prisma.secondHandStore.delete({
      where: { id: numericId }
    });
    
    res.json({ message: 'Deleted' });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

module.exports = router;
