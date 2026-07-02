const express = require("express");
const router = express.Router();
const prisma = require("../config/prisma");

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

    const [accommodations, foods, jobs, services] = await Promise.all([
      prisma.accommodation.findMany({ where: { createdById: numericUserId } }),
      prisma.foodGrocery.findMany({ where: { createdById: numericUserId } }),
      prisma.jobListing.findMany({ where: { createdById: numericUserId } }),
      prisma.service.findMany({ where: { createdById: numericUserId } }),
    ]);

    res.json({
      Accommodation: accommodations.map(mapItem),
      Food: foods.map(mapItem),
      Jobs: jobs.map(mapItem),
      Services: services.map(mapItem),
    });
  } catch (error) {
    console.error("❌ GET user listings error:", error.message);
    res.status(500).json({ message: "Server error" });
  }
});

// POST submit a new listing
router.post("/", async (req, res) => {
  try {
    const { category, data } = req.body;
    const numericUserId = parseInt(req.user.id);
    if (isNaN(numericUserId)) return res.status(401).json({ message: "Invalid session" });

    const allowed = ["Accommodation", "Food", "Jobs", "Services"];
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
        area:             data.area && !isNaN(parseFloat(data.area)) ? parseFloat(data.area) : null,
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
        image:             data.image || null,
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
router.put("/:category/:id", async (req, res) => {
  try {
    const { category, id } = req.params;
    const { data } = req.body;
    const numericId = parseInt(id);
    const numericUserId = parseInt(req.user.id);

    if (isNaN(numericId) || isNaN(numericUserId)) {
      return res.status(400).json({ message: "Invalid ID format" });
    }

    const allowed = ["Accommodation", "Food", "Jobs", "Services"];
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
        area:             data.area && !isNaN(parseFloat(data.area)) ? parseFloat(data.area) : null,
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
        image:             data.image || null,
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

    const allowed = ["Accommodation", "Food", "Jobs", "Services"];
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
    }

    res.json({ message: "Listing deleted successfully" });
  } catch (error) {
    console.error("❌ DELETE user listing error:", error.message);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;
