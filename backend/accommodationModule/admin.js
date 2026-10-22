const express = require("express");
const router = express.Router();
const prisma = require("../config/prisma");
const { notifyListingActivated } = require('../userModule/user/services/notificationService');
const upload = require('../middleware/upload');
const { uploadImage } = require('../services/cloudinaryService');

// Helper to map PostgreSQL Prisma accommodation to match frontend expectations
const mapAccommodation = (item) => {
  if (!item) return null;
  return {
    ...item,
    _id: String(item.id),
    website: item.website || item.externalUrl || null,
    externalUrl: item.externalUrl || item.website || null,
  };
};

const adminCheck = (req, res, next) => {
  if (!req.user || req.user.role !== "admin") {
    return res.status(403).json({ message: "Admin access required" });
  }
  next();
};

// GET ALL (with stats) with optional pagination: ?page=1&limit=20
router.get("/", adminCheck, async (req, res) => {
  const start = Date.now();
  console.log(`🚀 [START] GET /accommodation/admin/ called at ${new Date().toISOString()}`);
  try {
    // Pagination params
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 10);
    const skip = (page - 1) * limit;

    console.log(`📋 [PAGINATION] page=${page}, limit=${limit}, skip=${skip}`);

    // Get total counts
    console.log(`🔍 [DB QUERY] Fetching Accommodation count (all documents)`);
    const countStart = Date.now();
    const totalCount = await prisma.accommodation.count();
    console.log(`✅ [DB RESULT] Accommodation count returned ${totalCount} total documents in ${Date.now() - countStart}ms`);

    console.log(`🔍 [DB QUERY] Fetching Accommodation count (active documents with title and city)`);
    const activeStart = Date.now();
    const activeCount = await prisma.accommodation.count({
      where: {
        title: { not: "" },
        city: { not: "" },
        status: { equals: 'active', mode: 'insensitive' }
      }
    });
    console.log(`✅ [DB RESULT] Accommodation active count returned ${activeCount} documents in ${Date.now() - activeStart}ms`);

    // Fetch paginated data
    console.log(`🔍 [DB QUERY] Fetching paginated Accommodation data - limit=${limit}, skip=${skip}`);
    const findStart = Date.now();
    const accommodations = await prisma.accommodation.findMany({
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit
    });
    console.log(`✅ [DB RESULT] findMany returned ${(accommodations || []).length} documents in ${Date.now() - findStart}ms`);

    const mappedData = accommodations.map(mapAccommodation);
    console.log(`📤 [RESPONSE] Sending 200 response with ${mappedData.length} items after ${Date.now() - start}ms`);

    res.status(200).json({
      data: mappedData,
      count: mappedData.length,
      totalCount: totalCount || 0,
      page,
      limit,
      activeCount: activeCount || 0
    });
  } catch (error) {
    console.error(`❌ [ERROR] GET /accommodation/admin/ failed: ${error.message} after ${Date.now() - start}ms`);
    res.status(500).json({ message: error.message });
  }
});

// GET ONE
router.get("/:id", adminCheck, async (req, res) => {
  const start = Date.now();
  console.log(`🚀 [START] GET /accommodation/admin/:id called with id=${req.params.id} at ${new Date().toISOString()}`);
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: "Invalid ID format" });

    console.log(`🔍 [DB QUERY] Fetching Accommodation by ID: ${numericId}`);
    const queryStart = Date.now();
    const accommodation = await prisma.accommodation.findUnique({
      where: { id: numericId }
    });
    console.log(`✅ [DB RESULT] findUnique ${accommodation ? 'found' : 'not found'} in ${Date.now() - queryStart}ms`);

    if (!accommodation) {
      console.log(`📤 [RESPONSE] Sending 404 response after ${Date.now() - start}ms`);
      return res.status(404).json({ message: "Not found" });
    }

    console.log(`📤 [RESPONSE] Sending 200 response after ${Date.now() - start}ms`);
    res.status(200).json(mapAccommodation(accommodation));
  } catch (error) {
    console.error(`❌ [ERROR] GET /accommodation/admin/:id failed: ${error.message} after ${Date.now() - start}ms`);
    res.status(500).json({ message: error.message });
  }
});

// CREATE
router.post("/", adminCheck, upload.array('images', 5), async (req, res) => {
  const start = Date.now();
  console.log(`🚀 [START] POST /accommodation/admin/ called at ${new Date().toISOString()}`);
  try {
    const title = (req.body.title || '').trim();
    const city = (req.body.city || '').trim();
    const contactPhone = (req.body.contactPhone || req.body.phone || '').trim();
    const externalLink = (req.body.externalUrl || req.body.website || '').trim();

    if (!title || !city) {
      return res.status(400).json({ message: 'Title and City are required' });
    }
    if (!contactPhone && !externalLink) {
      return res.status(400).json({ message: 'Either Contact Phone or an External Source Link (URL) is required' });
    }

    console.log(`📝 [VALIDATION] Creating accommodation with title="${title}", city="${city}"`);

    // Upload any attached image files to Cloudinary 
    let imageUrls = [];
    if (req.files && req.files.length > 0) {
      const uploads = await Promise.all(
        req.files.map(f => uploadImage(f.buffer, 'accommodations'))
      );
      imageUrls = uploads.map(r => r.secure_url);
    } else if (req.body.images && Array.isArray(req.body.images)) {
      const uploads = await Promise.all(
        req.body.images.map(async (base64Img) => {
          if (typeof base64Img === 'string' && base64Img.startsWith('http')) return { secure_url: base64Img };
          if (typeof base64Img !== 'string' || !base64Img.includes('base64')) return { secure_url: null };

          const base64Data = base64Img.replace(/^data:image\/\w+;base64,/, '');
          const buffer = Buffer.from(base64Data, 'base64');
          return uploadImage(buffer, 'accommodations');
        })
      );
      imageUrls = uploads.map(r => r.secure_url).filter(url => url !== null);
    }

    // Extract flat helper fields for SQL search/sort performance safely
    const rentDetails = typeof req.body.rentDetails === 'string' ? JSON.parse(req.body.rentDetails) : (req.body.rentDetails || {});
    const propertyDetails = typeof req.body.propertyDetails === 'string' ? JSON.parse(req.body.propertyDetails) : (req.body.propertyDetails || {});
    const amenities = typeof req.body.amenities === 'string' ? JSON.parse(req.body.amenities) : (req.body.amenities || {});
    const adminControls = typeof req.body.adminControls === 'string' ? JSON.parse(req.body.adminControls) : (req.body.adminControls || {});

    const rentVal = rentDetails?.coldRent ? parseFloat(rentDetails.coldRent) : null;
    const depositVal = rentDetails?.deposit ? parseFloat(rentDetails.deposit) : null;
    const bedroomsVal = propertyDetails?.bedrooms ? parseInt(propertyDetails.bedrooms, 10) : null;
    const bathroomsVal = propertyDetails?.bathrooms ? parseInt(propertyDetails.bathrooms, 10) : null;
    const sizeVal = propertyDetails?.sizeSqm ? parseFloat(propertyDetails.sizeSqm) : null;
    const isFurnished = amenities?.furnished === true || amenities?.furnished === 'true';
    const isPetsAllowed = amenities?.petsAllowed === true || amenities?.petsAllowed === 'true';
    const isParking = amenities?.parking === true || amenities?.parking === 'true';
    const firstImg = imageUrls.length > 0 ? imageUrls[0] : null;

    console.log(`🔍 [DB QUERY] Creating new Accommodation document in Prisma`);
    const saveStart = Date.now();
    const newAccommodation = await prisma.accommodation.create({
      data: {
        title,
        category: req.body.category || "Accommodation",
        type: req.body.propertyType ? String(req.body.propertyType).trim() : null,
        address: req.body.address ? String(req.body.address).trim() : null,
        city,
        state: req.body.state ? String(req.body.state).trim() : null,
        zipCode: req.body.zipCode ? String(req.body.zipCode).trim() : null,
        phone: contactPhone || null,
        email: req.body.email ? String(req.body.email).trim() : null,
        website: externalLink || null,
        externalUrl: externalLink || null,
        description: req.body.description ? String(req.body.description).trim() : null,
        rent: rentVal,
        deposit: depositVal,
        bedrooms: bedroomsVal,
        bathrooms: bathroomsVal,
        area: sizeVal,
        furnished: isFurnished,
        petsAllowed: isPetsAllowed,
        parkingAvailable: isParking,
        utilities: req.body.utilities ? String(req.body.utilities).trim() : null,
        availableFrom: req.body.availableFrom ? new Date(req.body.availableFrom) : null,
        image: firstImg,
        latitude: req.body.latitude ? parseFloat(req.body.latitude) : null,
        longitude: req.body.longitude ? parseFloat(req.body.longitude) : null,
        averageRating: 0,
        totalRatings: 0,
        ratingDistribution: req.body.ratingDistribution || {},
        lastRatedAt: null,
        status: 'pending',
        createdById: req.user ? parseInt(req.user.id, 10) : null,
        creatorType: req.body.creatorType || "admin",

        // JSON configurations
        rentDetails: rentDetails,
        propertyDetails: propertyDetails,
        amenities: amenities,
        locationHighlights: typeof req.body.locationHighlights === 'string' ? JSON.parse(req.body.locationHighlights) : (req.body.locationHighlights || {}),
        media: { images: imageUrls },
        adminControls: adminControls,
        contactPhone,
      }
    });

    console.log(`✅ [DB RESULT] Accommodation document saved with ID ${newAccommodation.id} in ${Date.now() - saveStart}ms`);
    console.log(`📤 [RESPONSE] Sending 201 response after ${Date.now() - start}ms`);
    res.status(201).json(mapAccommodation(newAccommodation));
  } catch (error) {
    console.error(`❌ [ERROR] POST /accommodation/admin/ failed: ${error.message} after ${Date.now() - start}ms`);
    res.status(500).json({ message: error.message });
  }
});

// PATCH status
router.patch('/:id/status', adminCheck, async (req, res) => {
  const start = Date.now();
  console.log(`🚀 [START] PATCH /accommodation/admin/:id/status called with id=${req.params.id} at ${new Date().toISOString()}`);
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: "Invalid ID format" });

    const { status } = req.body;
    const normalised = status === 'inactive' ? 'disabled' : status;
    console.log(`📝 [VALIDATION] Status change requested: ${status} -> ${normalised}`);

    if (!['active', 'disabled', 'pending'].includes(normalised)) return res.status(400).json({ message: 'Invalid status' });
    const isActive = normalised === 'active';

    console.log(`🔍 [DB QUERY] Fetching Accommodation before update: ${numericId}`);
    const fetchStart = Date.now();
    const before = await prisma.accommodation.findUnique({
      where: { id: numericId }
    });
    console.log(`✅ [DB RESULT] Before-state fetched in ${Date.now() - fetchStart}ms`);

    if (!before) return res.status(404).json({ message: 'Not found' });

    // Update nested adminControls object safely
    const existingAdminControls = before.adminControls || {};
    const updatedAdminControls = {
      ...existingAdminControls,
      isActive
    };

    console.log(`🔍 [DB QUERY] Updating Accommodation status: ${numericId} -> ${normalised}`);
    const updateStart = Date.now();
    const doc = await prisma.accommodation.update({
      where: { id: numericId },
      data: {
        status: normalised,
        adminControls: updatedAdminControls
      }
    });
    console.log(`✅ [DB RESULT] Accommodation updated in ${Date.now() - updateStart}ms`);

    const wasActive = String(before.status || '').toLowerCase() === 'active';
    const isNowActive = String(normalised || '').toLowerCase() === 'active';
    if (!wasActive && isNowActive) {
      console.log(`🔔 [NOTIFICATION] Notifying activation for listing: ${doc.id}`);
      notifyListingActivated({
        module: 'accommodation',
        entityId: String(doc.id),
        listingTitle: doc.title,
      }).catch(() => { });
    }

    console.log(`📤 [RESPONSE] Sending 200 response after ${Date.now() - start}ms`);
    res.json(mapAccommodation(doc));
  } catch (e) {
    console.error(`❌ [ERROR] PATCH /accommodation/admin/:id/status failed: ${e.message} after ${Date.now() - start}ms`);
    res.status(500).json({ message: e.message });
  }
});

// UPDATE
router.put("/:id", adminCheck, async (req, res) => {
  const start = Date.now();
  console.log(`🚀 [START] PUT /accommodation/admin/:id called with id=${req.params.id} at ${new Date().toISOString()}`);
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: "Invalid ID format" });

    console.log(`🔍 [DB QUERY] Updating Accommodation with ID: ${numericId}`);

    const b = req.body;

    // Build update safely — only whitelist known Prisma schema fields
    const updateData = {};
    if (b.title != null) updateData.title = String(b.title).trim();
    if (b.city != null) updateData.city = String(b.city).trim();
    if (b.address != null) updateData.address = String(b.address).trim() || null;
    if (b.area != null) updateData.area = String(b.area).trim() || null;
    if (b.state != null) updateData.state = String(b.state).trim() || null;
    if (b.zipCode != null) updateData.zipCode = String(b.zipCode).trim() || null;
    if (b.postalCode != null) updateData.zipCode = String(b.postalCode).trim() || null;
    if (b.type != null) updateData.type = String(b.type).trim() || null;
    if (b.description != null) updateData.description = String(b.description).trim() || null;
    if (b.status != null) updateData.status = b.status;
    if (b.externalUrl !== undefined || b.website !== undefined) {
      const urlVal = String((b.externalUrl !== undefined ? b.externalUrl : b.website) || '').trim() || null;
      updateData.externalUrl = urlVal;
      updateData.website = urlVal;
    }
    if (b.contactPhone || b.phone) {
      updateData.contactPhone = String(b.contactPhone || b.phone).trim();
      updateData.phone = String(b.contactPhone || b.phone).trim();
    }

    // Nested JSON fields — store as-is (Prisma Json type)
    if (b.rentDetails) updateData.rentDetails = b.rentDetails;
    if (b.propertyDetails) updateData.propertyDetails = b.propertyDetails;
    if (b.amenities) updateData.amenities = b.amenities;
    if (b.media) updateData.media = b.media;
    if (b.adminControls) updateData.adminControls = b.adminControls;

    // Derived image
    if (b.media?.images && Array.isArray(b.media.images)) {
      updateData.image = b.media.images.length > 0 ? b.media.images[0] : null;
    } else if (b.image !== undefined) {
      updateData.image = b.image ? String(b.image).trim() : null;
    }

    // Flat derived fields from nested
    if (b.rentDetails?.coldRent != null) updateData.rent = parseFloat(b.rentDetails.coldRent) || null;
    if (b.rentDetails?.deposit != null) updateData.deposit = parseFloat(b.rentDetails.deposit) || null;
    if (b.propertyDetails?.bedrooms != null) updateData.bedrooms = parseInt(b.propertyDetails.bedrooms, 10) || null;
    if (b.propertyDetails?.bathrooms != null) updateData.bathrooms = parseInt(b.propertyDetails.bathrooms, 10) || null;
    if (b.propertyDetails?.sizeSqm != null) updateData.area = parseFloat(b.propertyDetails.sizeSqm) || null;
    if (b.amenities?.furnished != null) updateData.furnished = !!b.amenities.furnished;
    if (b.amenities?.petsAllowed != null) updateData.petsAllowed = !!b.amenities.petsAllowed;
    if (b.amenities?.parking != null) updateData.parkingAvailable = !!b.amenities.parking;

    const updateStart = Date.now();
    const updated = await prisma.accommodation.update({
      where: { id: numericId },
      data: updateData
    });
    console.log(`✅ [DB RESULT] Accommodation update completed in ${Date.now() - updateStart}ms`);

    console.log(`📤 [RESPONSE] Sending 200 response after ${Date.now() - start}ms`);
    res.status(200).json(mapAccommodation(updated));
  } catch (error) {
    console.error(`❌ [ERROR] PUT /accommodation/admin/:id failed: ${error.message} after ${Date.now() - start}ms`);
    res.status(500).json({ message: error.message });
  }
});

// DELETE
router.delete("/:id", adminCheck, async (req, res) => {
  const start = Date.now();
  console.log(`🚀 [START] DELETE /accommodation/admin/:id called with id=${req.params.id} at ${new Date().toISOString()}`);
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: "Invalid ID format" });

    console.log(`🔍 [DB QUERY] Deleting Accommodation with ID: ${numericId}`);
    const deleteStart = Date.now();
    await prisma.accommodation.delete({
      where: { id: numericId }
    });
    console.log(`✅ [DB RESULT] Accommodation delete completed in ${Date.now() - deleteStart}ms`);

    console.log(`📤 [RESPONSE] Sending 200 response after ${Date.now() - start}ms`);
    res.status(200).json({ message: "Deleted successfully" });
  } catch (error) {
    console.error(`❌ [ERROR] DELETE /accommodation/admin/:id failed: ${error.message} after ${Date.now() - start}ms`);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;