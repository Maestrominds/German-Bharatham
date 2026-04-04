const User = require("../models/User");

// 🌐 Public-safe user profiles (role=user only)
exports.getPublicUsers = async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 1));
    const skip = (page - 1) * limit;

    const filter = { role: "user", isActive: true };
    const [total, users] = await Promise.all([
      User.countDocuments(filter),
      User.find(filter).select("name email phone photo role isActive createdAt location preferredCity").skip(skip).limit(limit)
    ]);
    const totalPages = Math.ceil(total / limit);
    res.json({ data: users, count: total, page, limit, totalPages });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 👀 Get All Users (only role = user)
exports.getAllUsers = async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 1));
    const skip = (page - 1) * limit;

    const filter = { role: "user" };
    const [total, users] = await Promise.all([
      User.countDocuments(filter),
      User.find(filter).select("-password").skip(skip).limit(limit)
    ]);
    const totalPages = Math.ceil(total / limit);
    res.json({ data: users, count: total, page, limit, totalPages });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ✅ Activate User
exports.activateUser = async (req, res) => {
  try {
    await User.findByIdAndUpdate(req.params.id, { isActive: true });
    res.json({ message: "User activated" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ❌ Deactivate User
exports.deactivateUser = async (req, res) => {
  try {
    await User.findByIdAndUpdate(req.params.id, { isActive: false });
    res.json({ message: "User deactivated" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};