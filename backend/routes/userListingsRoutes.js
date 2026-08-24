const express = require("express");
const router = express.Router();
const prisma = require("../config/prisma");
const upload = require('../middleware/upload');
const { uploadImage } = require('../services/cloudinaryService');

const mapItem = (item) => {
  if (!item) return null;
  return {
    ...item,
    _id: String(item.id),
    createdBy: String(item.createdById)
  };
};

// GET all listings submitted by the current user
router.get("/", async (req, res) => {
  try {
    const numericUserId = parseInt(req.user.id);
    if (isNaN(numericUserId)) return res.status(401).json({ message: "Invalid session" });

    const [accommodations, foods, jobs, services, secondHandStores] = await Promise.all([
      prisma.accommodation.findMany({ where: { createdById: numericUserId } }),
      prisma.foodGrocery.findMany({ where: { createdById: numericUserId } }),
      prisma.jobListing.findMany({ where: { createdById: numericUserId } }),
      prisma.service.findMany({ where: { createdById: numericUserId } }),
      prisma.secondHandStore.findMany({ where: { createdById: numericUserId } }),
    ]);

    res.json({
      Accommodation: accommodations.map(mapItem),
      Food: foods.map(mapItem),
      Jobs: jobs.map(mapItem),
      Services: services.map(mapItem),
      "Second Hand Store": secondHandStores.map(mapItem),
    });
  } catch (error) {
    console.error("❌ GET user listings error:", error.message);
    res.status(500).json({ message: "Server error" });
  }
});

// POST submit a new listing
router.post("/", upload.any(), async (req, res) => {
  try {
    // Support both JSON body and multipart/form-data (Flutter sends multipart when images are attached)
    let category = req.body.category;
    if (category === "Expat Services") category = "Services";
    let data = req.body.data;
    if (typeof data === 'string') {
      try { data = JSON.parse(data); } catch (_) { data = {}; }
    }
    data = data || {};

    // Upload any attached images to Cloudinary and inject URLs into data
    if (req.files && req.files.length > 0) {
      const uploads = await Promise.all(req.files.map(f => uploadImage(f.buffer, 'listings')));
      const urls = uploads.map(r => r.secure_url);
      if (category === 'Jobs') {
        data.companyLogo = urls[0];
      } else {
        data.media = { images: [...(data.media?.images || []), ...urls] };
        data.images = [...(data.images || []), ...urls];
      }
    }

    const numericUserId = parseInt(req.user.id);
    if (isNaN(numericUserId)) return res.status(401).json({ message: "Invalid session" });

    const allowed = ["Accommodation", "Food", "Jobs", "Services", "Second Hand Store"];
    if (!category || !allowed.includes(category)) {
      return res.status(400).json({ message: "Invalid or missing category" });
    }

    // Base meta fields added to all listings
    const meta = {
      status: "Pending",
      createdById: numericUserId,
      creatorType: "user",
    };

    let doc = null;
    if (category === "Accommodation") {
      // Map propertyType → type (Prisma schema uses 'type', Flutter sends 'propertyType')
      const accPayload = {
        title:            data.title || "",
        type:             data.propertyType || data.type || null,
        city:             data.city || null,
        address:          data.address || null,
        zipCode:          data.postalCode || data.zipCode || null,
        phone:            data.contactPhone || data.phone || null,
        contactPhone:     data.contactPhone || null,
        description:      data.description || null,
        rentDetails:      data.rentDetails || null,
        propertyDetails:  data.propertyDetails || null,
        amenities:        data.amenities || null,
        media:            data.media || null,
        area:             data.propertyDetails?.sizeSqm ? parseFloat(data.propertyDetails.sizeSqm) : (data.sizeSqm ? parseFloat(data.sizeSqm) : null),
        state:            data.area || null,
        ...meta,
      };
      doc = await prisma.accommodation.create({ data: accPayload });

    } else if (category === "Food") {
      const foodPayload = {
        title:             data.title || "",
        category:          "Food",
        subCategory:       data.subCategory || null,
        type:              data.type || null,
        location:          data.location || null,
        address:           data.address || null,
        city:              data.city || null,
        state:             data.state || null,
        zipCode:           data.zipCode || null,
        phone:             data.phone || null,
        website:           data.website || null,
        description:       data.description || null,
        openingHours:      data.openingHours || null,
        priceRange:        data.priceRange || null,
        cuisine:           Array.isArray(data.cuisine) ? data.cuisine : [],
        specialties:       Array.isArray(data.specialties) ? data.specialties : [],
        deliveryAvailable: !!data.deliveryAvailable,
        takeoutAvailable:  !!data.takeoutAvailable,
        dineInAvailable:   !!data.dineInAvailable,
        cateringAvailable: !!data.cateringAvailable,
        image:             (data.images && data.images.length > 0) ? data.images[0] : (data.image || null),
        ...meta,
      };
      doc = await prisma.foodGrocery.create({ data: foodPayload });

    } else if (category === "Jobs") {
      const jobPayload = {
        title:       data.title || "",
        companyName: data.companyName || data.company || null,
        companyLogo: data.companyLogo || null,
        location:    data.location || data.city || null,
        description: data.description || null,
        contact:     data.contact || data.phone || null,
        salary:      data.salary || null,
        jobType:     data.jobType || data.type || "Full Time",
        requirements: data.requirements || null,
        benefits:    data.benefits || null,
        applyUrl:    data.applyUrl || null,
        amenities:   Array.isArray(data.amenities) ? data.amenities : [],
        ...meta,
      };
      doc = await prisma.jobListing.create({ data: jobPayload });

    } else if (category === "Services") {
      const svcPayload = {
        title:        data.serviceName || data.title || null,
        serviceName:  data.serviceName || data.title || null,
        providerName: data.providerName || null,
        serviceType:  data.serviceType || null,
        city:         data.city || null,
        area:         data.area || null,
        postalCode:   data.postalCode || null,
        address:      data.address || null,
        phone:        data.contactPhone || data.phone || null,
        contactPhone: data.contactPhone || null,
        whatsapp:     data.whatsapp || null,
        email:        data.email || null,
        website:      data.website || null,
        latitude:     data.latitude ? parseFloat(data.latitude) : null,
        longitude:    data.longitude ? parseFloat(data.longitude) : null,
        description:  data.description || null,
        priceRange:   data.priceRange || null,
        images:       Array.isArray(data.images) ? data.images : [],
        amenities:    Array.isArray(data.amenities) ? data.amenities : [],
        ...meta,
      };
      doc = await prisma.service.create({ data: svcPayload });
    } else if (category === "Second Hand Store") {
      const shsPayload = {
        title:          data.title || "",
        description:    data.description || null,
        price:          data.price || null,
        contactPhone:   data.contactPhone || null,
        contactEmail:   data.contactEmail || null,
        deliveryOption: data.deliveryOption || null,
        images:         Array.isArray(data.images) ? data.images : [],
        ...meta,
      };
      doc = await prisma.secondHandStore.create({ data: shsPayload });
    }

    res.status(201).json({ message: "Listing submitted successfully", data: mapItem(doc) });
  } catch (error) {
    let msg = error.message || String(error);
    // Strip long base64 data so the error reason isn't truncated in console logs
    msg = msg.replace(/data:image\/[^;]+;base64,[^\s"}]+/g, '[BASE64_IMAGE_TRUNCATED]');
    console.error("❌ POST user listing error:", msg);
    res.status(400).json({ message: msg });
  }
});

// PUT update a pending listing
router.put("/:category/:id", upload.any(), async (req, res) => {
  try {
    let { category, id } = req.params;
    if (category === "Expat Services") category = "Services";
    // Support both JSON body and multipart/form-data
    let data = req.body.data;
    if (typeof data === 'string') {
      try { data = JSON.parse(data); } catch (_) { data = {}; }
    }
    data = data || req.body;

    // Upload any attached images to Cloudinary and inject URLs into data
    if (req.files && req.files.length > 0) {
      const uploads = await Promise.all(req.files.map(f => uploadImage(f.buffer, 'listings')));
      const urls = uploads.map(r => r.secure_url);
      if (category === 'Jobs') {
        data.companyLogo = urls[0];
      } else {
        data.media = { images: [...(data.media?.images || []), ...urls] };
        data.images = [...(data.images || []), ...urls];
      }
    }

    const numericId = parseInt(id);
    const numericUserId = parseInt(req.user.id);

    if (isNaN(numericId) || isNaN(numericUserId)) {
      return res.status(400).json({ message: "Invalid ID format" });
    }

    const allowed = ["Accommodation", "Food", "Jobs", "Services", "Second Hand Store"];
    if (!category || !allowed.includes(category)) {
      return res.status(400).json({ message: "Invalid category" });
    }

    let existing = null;
    if (category === "Accommodation") {
      existing = await prisma.accommodation.findUnique({ where: { id: numericId } });
    } else if (category === "Food") {
      existing = await prisma.foodGrocery.findUnique({ where: { id: numericId } });
    } else if (category === "Jobs") {
      existing = await prisma.jobListing.findUnique({ where: { id: numericId } });
    } else if (category === "Services") {
      existing = await prisma.service.findUnique({ where: { id: numericId } });
    } else if (category === "Second Hand Store") {
      existing = await prisma.secondHandStore.findUnique({ where: { id: numericId } });
    }

    if (!existing) {
      return res.status(404).json({ message: "Listing not found" });
    }

    // Check ownership
    if (existing.createdById !== numericUserId) {
      return res.status(403).json({ message: "Not authorized to edit this listing" });
    }

    // Check status
    const statusLower = String(existing.status || "").toLowerCase();
    if (statusLower !== "pending") {
      return res.status(400).json({ message: "Only pending listings can be edited" });
    }

    const meta = {
      status: "Pending",
      createdById: numericUserId,
      creatorType: "user",
    };

    let updatedDoc = null;
    if (category === "Accommodation") {
      const accPayload = {
        title:            data.title || "",
        type:             data.propertyType || data.type || null,
        city:             data.city || null,
        address:          data.address || null,
        zipCode:          data.postalCode || data.zipCode || null,
        phone:            data.contactPhone || data.phone || null,
        contactPhone:     data.contactPhone || null,
        description:      data.description || null,
        rentDetails:      data.rentDetails || null,
        propertyDetails:  data.propertyDetails || null,
        amenities:        data.amenities || null,
        media:            data.media || null,
        area:             data.propertyDetails?.sizeSqm ? parseFloat(data.propertyDetails.sizeSqm) : (data.sizeSqm ? parseFloat(data.sizeSqm) : null),
        state:            data.area || null,
        ...meta,
      };
      updatedDoc = await prisma.accommodation.update({ where: { id: numericId }, data: accPayload });
    } else if (category === "Food") {
      const foodPayload = {
        title:             data.title || "",
        category:          "Food",
        subCategory:       data.subCategory || null,
        type:              data.type || null,
        location:          data.location || null,
        address:           data.address || null,
        city:              data.city || null,
        state:             data.state || null,
        zipCode:           data.zipCode || null,
        phone:             data.phone || null,
        website:           data.website || null,
        description:       data.description || null,
        openingHours:      data.openingHours || null,
        priceRange:        data.priceRange || null,
        cuisine:           Array.isArray(data.cuisine) ? data.cuisine : [],
        specialties:       Array.isArray(data.specialties) ? data.specialties : [],
        deliveryAvailable: !!data.deliveryAvailable,
        takeoutAvailable:  !!data.takeoutAvailable,
        dineInAvailable:   !!data.dineInAvailable,
        cateringAvailable: !!data.cateringAvailable,
        image:             (data.images && data.images.length > 0) ? data.images[0] : (data.image || null),
        ...meta,
      };
      updatedDoc = await prisma.foodGrocery.update({ where: { id: numericId }, data: foodPayload });
    } else if (category === "Jobs") {
      const jobPayload = {
        title:       data.title || "",
        companyName: data.companyName || data.company || null,
        companyLogo: data.companyLogo || null,
        location:    data.location || data.city || null,
        description: data.description || null,
        contact:     data.contact || data.phone || null,
        salary:      data.salary || null,
        jobType:     data.jobType || data.type || "Full Time",
        requirements: data.requirements || null,
        benefits:    data.benefits || null,
        applyUrl:    data.applyUrl || null,
        amenities:   Array.isArray(data.amenities) ? data.amenities : [],
        ...meta,
      };
      updatedDoc = await prisma.jobListing.update({ where: { id: numericId }, data: jobPayload });
    } else if (category === "Services") {
      const svcPayload = {
        title:        data.serviceName || data.title || null,
        serviceName:  data.serviceName || data.title || null,
        providerName: data.providerName || null,
        serviceType:  data.serviceType || null,
        city:         data.city || null,
        area:         data.area || null,
        postalCode:   data.postalCode || null,
        address:      data.address || null,
        phone:        data.contactPhone || data.phone || null,
        contactPhone: data.contactPhone || null,
        whatsapp:     data.whatsapp || null,
        email:        data.email || null,
        website:      data.website || null,
        latitude:     data.latitude ? parseFloat(data.latitude) : null,
        longitude:    data.longitude ? parseFloat(data.longitude) : null,
        description:  data.description || null,
        priceRange:   data.priceRange || null,
        images:       Array.isArray(data.images) ? data.images : [],
        amenities:    Array.isArray(data.amenities) ? data.amenities : [],
        ...meta,
      };
      updatedDoc = await prisma.service.update({ where: { id: numericId }, data: svcPayload });
    } else if (category === "Second Hand Store") {
      const shsPayload = {
        title:          data.title || "",
        description:    data.description || null,
        price:          data.price || null,
        contactPhone:   data.contactPhone || null,
        contactEmail:   data.contactEmail || null,
        deliveryOption: data.deliveryOption || null,
        images:         Array.isArray(data.images) ? data.images : [],
        ...meta,
      };
      updatedDoc = await prisma.secondHandStore.update({ where: { id: numericId }, data: shsPayload });
    }

    res.json({ message: "Listing updated successfully", data: mapItem(updatedDoc) });
  } catch (error) {
    let msg = error.message || String(error);
    // Strip long base64 data so the error reason isn't truncated in console logs
    msg = msg.replace(/data:image\/[^;]+;base64,[^\s"}]+/g, '[BASE64_IMAGE_TRUNCATED]');
    console.error("❌ PUT user listing error:", msg);
    res.status(400).json({ message: msg });
  }
});

// DELETE a listing (only allowed if pending or rejected)
router.delete("/:category/:id", async (req, res) => {
  try {
    const { category, id } = req.params;
    const numericId = parseInt(id);
    const numericUserId = parseInt(req.user.id);

    if (isNaN(numericId) || isNaN(numericUserId)) {
      return res.status(400).json({ message: "Invalid ID format" });
    }

    const allowed = ["Accommodation", "Food", "Jobs", "Services", "Second Hand Store"];
    if (!category || !allowed.includes(category)) {
      return res.status(400).json({ message: "Invalid category" });
    }

    let existing = null;
    if (category === "Accommodation") {
      existing = await prisma.accommodation.findUnique({ where: { id: numericId } });
    } else if (category === "Food") {
      existing = await prisma.foodGrocery.findUnique({ where: { id: numericId } });
    } else if (category === "Jobs") {
      existing = await prisma.jobListing.findUnique({ where: { id: numericId } });
    } else if (category === "Services") {
      existing = await prisma.service.findUnique({ where: { id: numericId } });
    } else if (category === "Second Hand Store") {
      existing = await prisma.secondHandStore.findUnique({ where: { id: numericId } });
    }

    if (!existing) {
      return res.status(404).json({ message: "Listing not found" });
    }

    // Check ownership
    if (existing.createdById !== numericUserId) {
      return res.status(403).json({ message: "Not authorized to delete this listing" });
    }

    // Check status
    const statusLower = String(existing.status || "").toLowerCase();
    if (statusLower === "active") {
      return res.status(400).json({ message: "Approved/Active listings cannot be deleted by users" });
    }

    if (category === "Accommodation") {
      await prisma.accommodation.delete({ where: { id: numericId } });
    } else if (category === "Food") {
      await prisma.foodGrocery.delete({ where: { id: numericId } });
    } else if (category === "Jobs") {
      await prisma.jobListing.delete({ where: { id: numericId } });
    } else if (category === "Services") {
      await prisma.service.delete({ where: { id: numericId } });
    } else if (category === "Second Hand Store") {
      await prisma.secondHandStore.delete({ where: { id: numericId } });
    }

    res.json({ message: "Listing deleted successfully" });
  } catch (error) {
    console.error("❌ DELETE user listing error:", error.message);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;
