const express = require('express');
const router = express.Router();
const prisma = require('../config/prisma');

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

// GET ALL VISIBLE EVENTS (Public / User)
router.get('/', async (req, res) => {
  try {
    const { city, upcoming, search, category } = req.query;

    const where = {
      status: { equals: 'Active', mode: 'insensitive' },
    };

    if (city && city.trim()) {
      where.city = { contains: city.trim(), mode: 'insensitive' };
    }

    if (category && category.trim()) {
      where.category = { contains: category.trim(), mode: 'insensitive' };
    }

    if (upcoming === 'true' || upcoming === true) {
      const now = new Date();
      where.OR = [
        { startsAt: { gte: now } },
        { endsAt: { gte: now } },
      ];
    }

    if (search && search.trim()) {
      const q = search.trim();
      where.OR = [
        { title: { contains: q, mode: 'insensitive' } },
        { description: { contains: q, mode: 'insensitive' } },
        { venue: { contains: q, mode: 'insensitive' } },
        { organizer: { contains: q, mode: 'insensitive' } },
      ];
    }

    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 20);
    const skip = (page - 1) * limit;

    const [total, data] = await Promise.all([
      prisma.event.count({ where }),
      prisma.event.findMany({
        where,
        orderBy: [
          { startsAt: 'asc' },
          { createdAt: 'desc' },
        ],
        skip,
        take: limit,
      }),
    ]);

    const mappedData = data.map(mapEvent);
    res.json({
      data: mappedData,
      count: mappedData.length,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    });
  } catch (e) {
    console.error('❌ GET /events/user error:', e.message);
    res.status(500).json({ message: e.message });
  }
});

// GET ONE EVENT BY ID
router.get('/:id', async (req, res) => {
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

module.exports = router;
