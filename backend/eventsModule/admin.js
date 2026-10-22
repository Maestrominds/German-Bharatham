const express = require('express');
const router = express.Router();
const prisma = require('../config/prisma');
const upload = require('../middleware/upload');
const { uploadImage } = require('../services/cloudinaryService');

const adminCheck = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Admin access required' });
  }
  next();
};

const normalizeStatus = (value, fallback = 'Pending') => {
  const raw = String(value || '').trim().toLowerCase();
  if (raw === 'active') return 'Active';
  if (raw === 'pending') return 'Pending';
  if (raw === 'inactive' || raw === 'disabled') return 'Inactive';
  if (raw === 'rejected') return 'Rejected';
  return fallback;
};

// Helper to map Prisma Event to frontend expectations
const mapEvent = (item) => {
  if (!item) return null;
  return {
    ...item,
    _id: String(item.id),
    ticketUrl: item.ticketUrl || item.externalUrl || null,
    externalUrl: item.externalUrl || item.ticketUrl || null,
  };
};

// GET ALL events for admin (supports pagination: ?page=1&limit=20&status=Active)
router.get('/', adminCheck, async (req, res) => {
  const start = Date.now();
  try {
    const { status, city } = req.query;
    const filter = {};
    if (status) {
      filter.status = normalizeStatus(status, String(status));
    }
    if (city && city.trim()) {
      filter.city = { contains: city.trim(), mode: 'insensitive' };
    }

    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(200, parseInt(req.query.limit) || 20);
    const skip = (page - 1) * limit;

    const [totalCount, data] = await Promise.all([
      prisma.event.count({ where: filter }),
      prisma.event.findMany({
        where: filter,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
    ]);

    const mappedData = data.map(mapEvent);
    res.json({
      data: mappedData,
      count: mappedData.length,
      totalCount,
      page,
      limit,
      totalPages: Math.ceil(totalCount / limit),
    });
  } catch (e) {
    console.error(`❌ [ERROR] GET /events/admin/ failed: ${e.message} after ${Date.now() - start}ms`);
    res.status(500).json({ message: e.message });
  }
});

// GET ONE event
router.get('/:id', adminCheck, async (req, res) => {
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: 'Invalid ID format' });

    const doc = await prisma.event.findUnique({
      where: { id: numericId },
    });

    if (!doc) return res.status(404).json({ message: 'Event not found' });
    res.json(mapEvent(doc));
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// CREATE event (admin)
router.post('/', adminCheck, upload.any(), async (req, res) => {
  try {
    const { title } = req.body;
    if (!title || !title.trim()) {
      return res.status(400).json({ message: 'Event title is required' });
    }

    let imageUrls = [];
    if (req.files && req.files.length > 0) {
      const uploads = await Promise.all(
        req.files.map((f) => uploadImage(f.buffer, 'events'))
      );
      imageUrls = uploads.map((r) => r.secure_url);
    } else if (req.body.images && Array.isArray(req.body.images)) {
      const uploads = await Promise.all(
        req.body.images.map(async (base64Img) => {
          if (typeof base64Img === 'string' && base64Img.startsWith('http')) return { secure_url: base64Img };
          if (typeof base64Img !== 'string' || !base64Img.includes('base64')) return { secure_url: null };

          const base64Data = base64Img.replace(/^data:image\/\w+;base64,/, '');
          const buffer = Buffer.from(base64Data, 'base64');
          return uploadImage(buffer, 'events');
        })
      );
      imageUrls = uploads.map((r) => r.secure_url).filter((url) => url !== null);
    }

    const ticketLink = req.body.ticketUrl || req.body.externalUrl || null;

    const doc = await prisma.event.create({
      data: {
        title: req.body.title.trim(),
        description: req.body.description ? String(req.body.description).trim() : null,
        category: req.body.category || 'Event',
        city: req.body.city ? String(req.body.city).trim() : null,
        venue: req.body.venue ? String(req.body.venue).trim() : null,
        organizer: req.body.organizer ? String(req.body.organizer).trim() : null,
        contact: req.body.contact ? String(req.body.contact).trim() : null,
        startsAt: req.body.startsAt ? new Date(req.body.startsAt) : null,
        endsAt: req.body.endsAt ? new Date(req.body.endsAt) : null,
        price: req.body.price ? String(req.body.price).trim() : null,
        ticketUrl: ticketLink,
        externalUrl: ticketLink,
        images: imageUrls,
        status: req.body.status ? normalizeStatus(req.body.status, 'Active') : 'Active',
        featured: req.body.featured === true || req.body.featured === 'true',
        createdById: req.user ? parseInt(req.user.id, 10) : null,
        creatorType: 'admin',
      },
    });

    res.status(201).json(mapEvent(doc));
  } catch (e) {
    console.error('❌ POST /events/admin failed:', e.message);
    res.status(500).json({ message: e.message });
  }
});

// UPDATE event (admin)
router.put('/:id', adminCheck, upload.any(), async (req, res) => {
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: 'Invalid ID format' });

    let imageUrls = undefined;
    if (req.files && req.files.length > 0) {
      const uploads = await Promise.all(
        req.files.map((f) => uploadImage(f.buffer, 'events'))
      );
      imageUrls = uploads.map((r) => r.secure_url);
    } else if (req.body.images && Array.isArray(req.body.images)) {
      const uploads = await Promise.all(
        req.body.images.map(async (base64Img) => {
          if (typeof base64Img === 'string' && base64Img.startsWith('http')) return { secure_url: base64Img };
          if (typeof base64Img !== 'string' || !base64Img.includes('base64')) return { secure_url: null };

          const base64Data = base64Img.replace(/^data:image\/\w+;base64,/, '');
          const buffer = Buffer.from(base64Data, 'base64');
          return uploadImage(buffer, 'events');
        })
      );
      imageUrls = uploads.map((r) => r.secure_url).filter((url) => url !== null);
    }

    const updateData = {};
    if (req.body.title != null) updateData.title = String(req.body.title).trim();
    if (req.body.description != null) updateData.description = String(req.body.description).trim();
    if (req.body.category != null) updateData.category = req.body.category;
    if (req.body.city != null) updateData.city = String(req.body.city).trim();
    if (req.body.venue != null) updateData.venue = String(req.body.venue).trim();
    if (req.body.organizer != null) updateData.organizer = String(req.body.organizer).trim();
    if (req.body.contact != null) updateData.contact = String(req.body.contact).trim();
    if (req.body.startsAt != null) updateData.startsAt = new Date(req.body.startsAt);
    if (req.body.endsAt != null) updateData.endsAt = new Date(req.body.endsAt);
    if (req.body.price != null) updateData.price = String(req.body.price).trim();
    if (req.body.ticketUrl != null || req.body.externalUrl != null) {
      const link = req.body.ticketUrl || req.body.externalUrl;
      updateData.ticketUrl = link;
      updateData.externalUrl = link;
    }
    if (imageUrls !== undefined) updateData.images = imageUrls;
    if (req.body.status != null) updateData.status = normalizeStatus(req.body.status, req.body.status);
    if (req.body.featured != null) updateData.featured = req.body.featured === true || req.body.featured === 'true';

    const doc = await prisma.event.update({
      where: { id: numericId },
      data: updateData,
    });

    res.json(mapEvent(doc));
  } catch (e) {
    console.error('❌ PUT /events/admin failed:', e.message);
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
    if (!['Active', 'Pending', 'Inactive', 'Rejected'].includes(normalised)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const doc = await prisma.event.update({
      where: { id: numericId },
      data: { status: normalised },
    });

    res.json(mapEvent(doc));
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// DELETE event
router.delete('/:id', adminCheck, async (req, res) => {
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: 'Invalid ID format' });

    await prisma.event.delete({
      where: { id: numericId },
    });

    res.json({ message: 'Event deleted successfully' });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

module.exports = router;
