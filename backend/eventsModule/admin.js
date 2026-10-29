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

const parseArray = (val) => {
  if (!val) return [];
  if (Array.isArray(val)) return val;
  try {
    const parsed = JSON.parse(val);
    if (Array.isArray(parsed)) return parsed;
  } catch (_) {}
  if (typeof val === 'string') {
    return val.split(',').map(s => s.trim()).filter(Boolean);
  }
  return [];
};

const parseJson = (val) => {
  if (!val) return null;
  if (typeof val === 'object') return val;
  try {
    return JSON.parse(val);
  } catch (_) {
    return null;
  }
};

// Helper to map Prisma Event to frontend expectations
const mapEvent = (item) => {
  if (!item) return null;
  const link = item.ticketUrl || item.externalUrl || item.onlineLink || null;
  const poster = item.posterUrl || (item.images && item.images.length > 0 ? item.images[0] : null);

  return {
    ...item,
    _id: String(item.id),
    ticketUrl: link,
    externalUrl: link,
    posterUrl: poster,
    start_date: item.startsAt ? item.startsAt.toISOString() : null,
    end_date: item.endsAt ? item.endsAt.toISOString() : null,
    time_text: item.timeText,
    short_description: item.shortDescription || (item.description ? item.description.substring(0, 160) : ''),
    is_online: item.isOnline,
    venue_name: item.venue,
    price_type: item.priceType || 'paid',
    price_text: item.priceText || item.price,
    family_friendly: item.familyFriendly,
    days_of_week: item.daysOfWeek || [],
    organizer_name: item.organizer,
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

    const ticketLink = req.body.ticketUrl || req.body.externalUrl || req.body.onlineLink || null;
    const format = req.body.format || 'one_day';
    const startsAt = (req.body.startsAt || req.body.start_date) ? new Date(req.body.startsAt || req.body.start_date) : null;
    let endsAt = (req.body.endsAt || req.body.end_date) ? new Date(req.body.endsAt || req.body.end_date) : null;
    if (format === 'one_day' && startsAt && !endsAt) {
      endsAt = startsAt;
    }

    const doc = await prisma.event.create({
      data: {
        title: req.body.title.trim(),
        description: req.body.description ? String(req.body.description).trim() : null,
        shortDescription: req.body.shortDescription ? String(req.body.shortDescription).trim() : null,
        category: req.body.category || 'festivals',
        format,
        city: req.body.city ? String(req.body.city).trim() : null,
        venue: req.body.venue || req.body.venue_name ? String(req.body.venue || req.body.venue_name).trim() : null,
        address: req.body.address ? String(req.body.address).trim() : null,
        isOnline: req.body.isOnline === true || req.body.isOnline === 'true',
        onlineLink: req.body.onlineLink ? String(req.body.onlineLink).trim() : null,
        organizer: req.body.organizer || req.body.organizer_name ? String(req.body.organizer || req.body.organizer_name).trim() : null,
        contact: req.body.contact ? String(req.body.contact).trim() : null,
        timeText: req.body.timeText || req.body.time_text ? String(req.body.timeText || req.body.time_text).trim() : null,
        startsAt,
        endsAt,
        price: req.body.price ? String(req.body.price).trim() : null,
        priceType: req.body.priceType || req.body.price_type || 'paid',
        priceText: req.body.priceText || req.body.price_text ? String(req.body.priceText || req.body.price_text).trim() : null,
        ticketUrl: ticketLink,
        externalUrl: ticketLink,
        posterUrl: imageUrls.length > 0 ? imageUrls[0] : (req.body.posterUrl || null),
        images: imageUrls,
        languages: parseArray(req.body.languages),
        familyFriendly: req.body.familyFriendly === true || req.body.familyFriendly === 'true',
        daysOfWeek: parseArray(req.body.daysOfWeek || req.body.days_of_week).map(n => parseInt(n, 10)).filter(n => !isNaN(n)),
        ongoing: req.body.ongoing === true || req.body.ongoing === 'true',
        level: req.body.level ? String(req.body.level).trim() : null,
        ageGroup: req.body.ageGroup || req.body.age_group ? String(req.body.ageGroup || req.body.age_group).trim() : null,
        sessions: parseJson(req.body.sessions),
        subtitles: req.body.subtitles ? String(req.body.subtitles).trim() : null,
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
    if (req.body.shortDescription != null) updateData.shortDescription = String(req.body.shortDescription).trim();
    if (req.body.category != null) updateData.category = req.body.category;
    if (req.body.format != null) updateData.format = req.body.format;
    if (req.body.city != null) updateData.city = String(req.body.city).trim();
    if (req.body.venue != null || req.body.venue_name != null) updateData.venue = String(req.body.venue || req.body.venue_name).trim();
    if (req.body.address != null) updateData.address = String(req.body.address).trim();
    if (req.body.isOnline != null) updateData.isOnline = req.body.isOnline === true || req.body.isOnline === 'true';
    if (req.body.onlineLink != null) updateData.onlineLink = String(req.body.onlineLink).trim();
    if (req.body.organizer != null || req.body.organizer_name != null) updateData.organizer = String(req.body.organizer || req.body.organizer_name).trim();
    if (req.body.contact != null) updateData.contact = String(req.body.contact).trim();
    if (req.body.timeText != null || req.body.time_text != null) updateData.timeText = String(req.body.timeText || req.body.time_text).trim();
    if (req.body.startsAt != null || req.body.start_date != null) updateData.startsAt = new Date(req.body.startsAt || req.body.start_date);
    if (req.body.endsAt != null || req.body.end_date != null) updateData.endsAt = new Date(req.body.endsAt || req.body.end_date);
    if (req.body.price != null) updateData.price = String(req.body.price).trim();
    if (req.body.priceType != null || req.body.price_type != null) updateData.priceType = req.body.priceType || req.body.price_type;
    if (req.body.priceText != null || req.body.price_text != null) updateData.priceText = String(req.body.priceText || req.body.price_text).trim();
    if (req.body.ticketUrl != null || req.body.externalUrl != null || req.body.onlineLink != null) {
      const link = req.body.ticketUrl || req.body.externalUrl || req.body.onlineLink;
      updateData.ticketUrl = link;
      updateData.externalUrl = link;
    }
    if (req.body.languages != null) updateData.languages = parseArray(req.body.languages);
    if (req.body.familyFriendly != null) updateData.familyFriendly = req.body.familyFriendly === true || req.body.familyFriendly === 'true';
    if (req.body.daysOfWeek != null || req.body.days_of_week != null) updateData.daysOfWeek = parseArray(req.body.daysOfWeek || req.body.days_of_week).map(n => parseInt(n, 10)).filter(n => !isNaN(n));
    if (req.body.ongoing != null) updateData.ongoing = req.body.ongoing === true || req.body.ongoing === 'true';
    if (req.body.level != null) updateData.level = String(req.body.level).trim();
    if (req.body.ageGroup != null || req.body.age_group != null) updateData.ageGroup = String(req.body.ageGroup || req.body.age_group).trim();
    if (req.body.sessions != null) updateData.sessions = parseJson(req.body.sessions);
    if (req.body.subtitles != null) updateData.subtitles = String(req.body.subtitles).trim();
    if (imageUrls !== undefined) {
      updateData.images = imageUrls;
      if (imageUrls.length > 0) updateData.posterUrl = imageUrls[0];
    }
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
