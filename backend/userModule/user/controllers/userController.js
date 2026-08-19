const prisma = require("../../../config/prisma");

const mapUser = (u) => {
  if (!u) return null;
  return {
    ...u,
    _id: String(u.id)
  };
};

// 🌐 Public-safe user profiles (role=user only)
exports.getPublicUsers = async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 10));
    const skip = (page - 1) * limit;

    const where = { role: "user", isActive: true };
    const [total, users] = await Promise.all([
      prisma.user.count({ where }),
      prisma.user.findMany({
        where,
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          // Note: photo intentionally excluded - heavy base64 data not needed for user cards
          role: true,
          isActive: true,
          createdAt: true,
          location: true,
          preferredCity: true,
          motherTongue: true,
          industry: true,
          linkedinUrl: true
        },
        skip,
        take: limit
      })
    ]);
    const totalPages = Math.ceil(total / limit);
    res.json({ data: users.map(mapUser), count: total, page, limit, totalPages });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 👀 Get All Users (only role = user)
exports.getAllUsers = async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 10));
    const skip = (page - 1) * limit;

    const where = { role: "user" };
    
    // Sort logic
    let orderBy = { createdAt: 'desc' }; // Default: newest
    const sortBy = req.query.sortBy;
    if (sortBy === 'oldest') orderBy = { createdAt: 'asc' };
    else if (sortBy === 'alphabetical') orderBy = { name: 'asc' };

    const [total, users] = await Promise.all([
      prisma.user.count({ where }),
      prisma.user.findMany({
        where,
        orderBy,
        select: {
          id: true,
          name: true,
          email: true,
          isActive: true,
          createdAt: true,
          location: true,
          preferredCity: true,
          subscriptionStatus: true,
          subscriptionPlan: true,
          subscriptionExpiresAt: true,
          // Note: photo & password intentionally excluded for fast API response
        },
        skip,
        take: limit
      })
    ]);

    // Strip password fields
    const sanitized = users.map(u => {
      const copy = { ...u };
      delete copy.password;
      return mapUser(copy);
    });

    const totalPages = Math.ceil(total / limit);
    res.json({ data: sanitized, count: total, page, limit, totalPages });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ✅ Activate User
exports.activateUser = async (req, res) => {
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: "Invalid ID format" });

    const user = await prisma.user.update({
      where: { id: numericId },
      data: { isActive: true }
    });
    console.log(`🟢 [ADMIN] User activated: ${user.email} (${user.id})`);
    res.json({ message: "User activated", isActive: true });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ❌ Deactivate User
exports.deactivateUser = async (req, res) => {
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: "Invalid ID format" });

    const user = await prisma.user.update({
      where: { id: numericId },
      data: { isActive: false }
    });
    console.log(`🔴 [ADMIN] User deactivated: ${user.email} (${user.id})`);
    res.json({ message: "User deactivated", isActive: false });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 🎁 Grant Lifetime Free Access
exports.grantFreeAccess = async (req, res) => {
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: "Invalid ID format" });

    // Set expiry to 10 years from now
    const tenYearsFromNow = new Date();
    tenYearsFromNow.setFullYear(tenYearsFromNow.getFullYear() + 10);

    const user = await prisma.user.update({
      where: { id: numericId },
      data: { 
        subscriptionStatus: "active",
        subscriptionPlan: "free",
        subscriptionExpiresAt: tenYearsFromNow
      }
    });
    console.log(`🎁 [ADMIN] Granted lifetime free access to: ${user.email} (${user.id})`);
    res.json({ message: "Lifetime free access granted", user });
  } catch (error) {
    console.error("Error granting free access:", error);
    res.status(500).json({ message: error.message });
  }
};