const express = require('express');
const router = express.Router();
const prisma = require('../config/prisma');

const userCheck = (req, res, next) => {
  if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
  next();
};

const mapListing = (item) => {
  if (!item) return null;
  return {
    ...item,
    _id: String(item.id),
    website: item.externalUrl || null,
    externalUrl: item.externalUrl || null,
  };
};

// GET ALL for a specific user OR GET ALL active if no user filter
router.get('/', async (req, res) => {
  try {
    const { userId } = req.query;
    const filter = {};
    if (userId) {
      filter.createdById = parseInt(userId);
    } else {
      filter.status = 'Active';
    }

    const data = await prisma.secondHandStore.findMany({
      where: filter,
      orderBy: { createdAt: 'desc' }
    });

    res.json({ data: data.map(mapListing) });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// GET ONE
router.get('/:id', async (req, res) => {
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

// CREATE is handled by /api/user/listings route which accepts multipart data and JSON.
// But we might need an endpoint here if they ever call it directly. Let's just leave it empty for now, as user listing creation seems centralized.

module.exports = router;
