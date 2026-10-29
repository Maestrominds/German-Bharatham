const express = require("express");
const router = express.Router();
const prisma = require("../config/prisma");
const { protect, adminOnly } = require("../middleware/auth");

const DEFAULT_OPTIONS = {
  domain: [
    "IT / Technology",
    "Computer Science / Software",
    "Biotechnology / Life Sciences",
    "Healthcare / Medicine",
    "Finance / Banking",
    "Mechanical / Automotive",
    "Electrical / Electronics",
    "Engineering / Manufacturing",
    "Marketing / Sales",
    "Business / Management",
    "Legal / Law",
    "Education / Academia",
    "Other"
  ],
  language: [
    "English",
    "German",
    "Tamil",
    "Hindi",
    "Telugu",
    "Malayalam",
    "Kannada",
    "Marathi",
    "Bengali",
    "Gujarati",
    "Punjabi",
    "Other"
  ],
  city: [
    "Berlin",
    "Munich",
    "Frankfurt",
    "Hamburg",
    "Stuttgart",
    "Düsseldorf",
    "Cologne",
    "Leipzig",
    "Dresden",
    "Nuremberg",
    "Hanover",
    "Bonn",
    "Mannheim",
    "Karlsruhe",
    "Aachen",
    "Other"
  ]
};

// Helper: Seed defaults for missing types safely
async function ensureDefaults() {
  try {
    for (const [type, items] of Object.entries(DEFAULT_OPTIONS)) {
      const count = await prisma.profileOption.count({ where: { type } });
      if (count === 0) {
        console.log(`🌱 Seeding default options for ${type}...`);
        await prisma.profileOption.createMany({
          data: items.map(name => ({ type, name })),
          skipDuplicates: true
        });
      }
    }
  } catch (err) {
    console.error("Warning in ensureDefaults:", err.message);
  }
}

// ── GET all profile options (Public - for Flutter app & Admin Panel) ─────────
router.get("/", async (req, res) => {
  try {
    await ensureDefaults();

    const options = await prisma.profileOption.findMany({
      orderBy: { id: "asc" }
    });

    const domains = [];
    const languages = [];
    const cities = [];

    for (const opt of options) {
      if (opt.type === "domain") domains.push(opt);
      else if (opt.type === "language") languages.push(opt);
      else if (opt.type === "city") cities.push(opt);
    }

    res.json({
      domains,
      languages,
      cities
    });
  } catch (err) {
    console.error("Error in GET /api/profile-options:", err.message);
    // Safe fallback if database table not yet pushed in local/test
    res.json({
      domains: DEFAULT_OPTIONS.domain.map((name, i) => ({ id: i + 1, type: "domain", name })),
      languages: DEFAULT_OPTIONS.language.map((name, i) => ({ id: i + 100, type: "language", name })),
      cities: DEFAULT_OPTIONS.city.map((name, i) => ({ id: i + 200, type: "city", name }))
    });
  }
});

// ── POST create a new option (Admin only) ───────────────────────────────────
router.post("/", protect, adminOnly, async (req, res) => {
  try {
    const { type, name } = req.body;

    if (!type || !["domain", "language", "city"].includes(type.trim())) {
      return res.status(400).json({ message: "Invalid type. Must be domain, language, or city." });
    }

    const cleanName = (name || "").trim();
    if (!cleanName) {
      return res.status(400).json({ message: "Option name cannot be empty." });
    }

    // Check if already exists (case-insensitive)
    const existing = await prisma.profileOption.findFirst({
      where: {
        type: type.trim(),
        name: { equals: cleanName, mode: "insensitive" }
      }
    });

    if (existing) {
      return res.status(400).json({ message: `"${cleanName}" already exists in ${type} options.` });
    }

    const created = await prisma.profileOption.create({
      data: {
        type: type.trim(),
        name: cleanName
      }
    });

    res.status(201).json(created);
  } catch (err) {
    console.error("Error creating profile option:", err.message);
    res.status(500).json({ message: err.message });
  }
});

// ── DELETE an option by ID (Admin only) ──────────────────────────────────────
router.delete("/:id", protect, adminOnly, async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    if (isNaN(id)) {
      return res.status(400).json({ message: "Invalid ID format." });
    }

    await prisma.profileOption.delete({
      where: { id }
    });

    res.json({ message: "Option deleted successfully." });
  } catch (err) {
    console.error("Error deleting profile option:", err.message);
    res.status(500).json({ message: err.message });
  }
});

// ── POST reset defaults (Admin only) ────────────────────────────────────────
router.post("/reset-defaults", protect, adminOnly, async (req, res) => {
  try {
    const { type } = req.body;
    const typesToReset = type && ["domain", "language", "city"].includes(type)
      ? [type]
      : ["domain", "language", "city"];

    for (const t of typesToReset) {
      await prisma.profileOption.deleteMany({ where: { type: t } });
      await prisma.profileOption.createMany({
        data: DEFAULT_OPTIONS[t].map(name => ({ type: t, name })),
        skipDuplicates: true
      });
    }

    const options = await prisma.profileOption.findMany({
      orderBy: { id: "asc" }
    });

    res.json({
      message: "Defaults restored successfully",
      domains: options.filter(o => o.type === "domain"),
      languages: options.filter(o => o.type === "language"),
      cities: options.filter(o => o.type === "city")
    });
  } catch (err) {
    console.error("Error resetting defaults:", err.message);
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;

