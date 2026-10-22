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
    const limit = Math.min(500, Math.max(1, parseInt(req.query.limit) || 10));
    const skip = (page - 1) * limit;

    const excludeIds = req.query.exclude ? req.query.exclude.split(',').map(id => id.trim()).filter(Boolean) : [];
    
    // We try to parse the excluded IDs as Ints since Prisma expects Ints for IDs
    const parsedExcludeIds = excludeIds.map(id => parseInt(id, 10)).filter(id => !isNaN(id));

    const where = { 
      role: "user", 
      isActive: true,
      ...(parsedExcludeIds.length > 0 && {
        id: { notIn: parsedExcludeIds }
      })
    };

    const { city, language, domain, search, query } = req.query;
    if (city && city.trim()) {
      const cleanCity = city.trim();
      where.OR = [
        { preferredCity: { contains: cleanCity, mode: 'insensitive' } },
        { location: { contains: cleanCity, mode: 'insensitive' } },
      ];
    }
    if (language && language.trim()) {
      where.motherTongue = { contains: language.trim(), mode: 'insensitive' };
    }
    if (domain && domain.trim()) {
      where.industry = { contains: domain.trim(), mode: 'insensitive' };
    }

    const q = (search || query || '').trim();
    if (q) {
      const searchConditions = [
        { name: { contains: q, mode: 'insensitive' } },
        { preferredCity: { contains: q, mode: 'insensitive' } },
        { location: { contains: q, mode: 'insensitive' } },
        { industry: { contains: q, mode: 'insensitive' } },
        { motherTongue: { contains: q, mode: 'insensitive' } },
      ];
      if (where.OR) {
        where.AND = [
          { OR: where.OR },
          { OR: searchConditions }
        ];
        delete where.OR;
      } else {
        where.OR = searchConditions;
      }
    }
    
    const [total, users] = await Promise.all([
      prisma.user.count({ where }),
      prisma.user.findMany({
        where,
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          photo: true,
          role: true,
          isActive: true,
          createdAt: true,
          location: true,
          preferredCity: true,
          motherTongue: true,
          industry: true,
          linkedinUrl: true,
          instagramUrl: true
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
          photo: true,
          location: true,
          preferredCity: true,
          motherTongue: true,
          industry: true,
          linkedinUrl: true,
          instagramUrl: true,
          subscriptionStatus: true,
          subscriptionPlan: true,
          subscriptionExpiresAt: true,
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

// 📥 Streamed CSV Export of all users (Memory-safe streaming with cursor pagination)
exports.exportUsersCsv = async (req, res) => {
  try {
    const filename = `users-export-${new Date().toISOString().slice(0, 10)}.csv`;
    res.setHeader("Content-Type", "text/csv; charset=utf-8");
    res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
    res.setHeader("Transfer-Encoding", "chunked");
    res.setHeader("Cache-Control", "no-cache");

    // Send UTF-8 Byte Order Mark (BOM) for correct Excel / spreadsheet character display
    res.write("\uFEFF");

    const headers = [
      "ID",
      "Name",
      "Email",
      "Phone",
      "Role",
      "Status",
      "Auth Provider",
      "City / Location",
      "Preferred City",
      "Mother Tongue",
      "Industry",
      "Career Level",
      "Education",
      "Profession",
      "German Level",
      "State of Origin",
      "LinkedIn URL",
      "Instagram URL",
      "Subscription Status",
      "Subscription Plan",
      "Subscription Expiry",
      "Registered At"
    ];

    res.write(headers.join(",") + "\r\n");

    const escapeCsv = (val) => {
      if (val === null || val === undefined) return '""';
      if (val instanceof Date) return `"${val.toISOString()}"`;
      let str = String(val);
      // Sanitize against CSV formula injection (=, +, -, @)
      if (/^[=\+\-@]/.test(str)) {
        str = "'" + str;
      }
      return `"${str.replace(/"/g, '""')}"`;
    };

    const BATCH_SIZE = 500;
    let cursor = null;
    let hasMore = true;

    // Stream batches of 500 users at a time using primary key cursor pagination
    while (hasMore) {
      const queryArgs = {
        take: BATCH_SIZE,
        orderBy: { id: "asc" },
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          role: true,
          isActive: true,
          authProvider: true,
          location: true,
          preferredCity: true,
          motherTongue: true,
          industry: true,
          careerLevel: true,
          education: true,
          profession: true,
          germanLevel: true,
          stateOfOrigin: true,
          linkedinUrl: true,
          instagramUrl: true,
          subscriptionStatus: true,
          subscriptionPlan: true,
          subscriptionExpiresAt: true,
          createdAt: true,
        }
      };

      if (cursor) {
        queryArgs.skip = 1;
        queryArgs.cursor = { id: cursor };
      }

      const batch = await prisma.user.findMany(queryArgs);

      if (!batch || batch.length === 0) {
        hasMore = false;
        break;
      }

      let chunk = "";
      for (const u of batch) {
        const row = [
          u.id,
          escapeCsv(u.name),
          escapeCsv(u.email),
          escapeCsv(u.phone),
          escapeCsv(u.role),
          escapeCsv(u.isActive ? "Active" : "Inactive"),
          escapeCsv(u.authProvider),
          escapeCsv(u.location),
          escapeCsv(u.preferredCity),
          escapeCsv(u.motherTongue),
          escapeCsv(u.industry),
          escapeCsv(u.careerLevel),
          escapeCsv(u.education),
          escapeCsv(u.profession),
          escapeCsv(u.germanLevel),
          escapeCsv(u.stateOfOrigin),
          escapeCsv(u.linkedinUrl),
          escapeCsv(u.instagramUrl),
          escapeCsv(u.subscriptionStatus),
          escapeCsv(u.subscriptionPlan),
          escapeCsv(u.subscriptionExpiresAt),
          escapeCsv(u.createdAt)
        ].join(",");
        chunk += row + "\r\n";
      }

      res.write(chunk);

      cursor = batch[batch.length - 1].id;
      if (batch.length < BATCH_SIZE) {
        hasMore = false;
      }
    }

    res.end();
  } catch (error) {
    console.error("Error streaming users CSV:", error);
    if (!res.headersSent) {
      res.status(500).json({ message: "Failed to export users CSV: " + error.message });
    } else {
      res.end();
    }
  }
};