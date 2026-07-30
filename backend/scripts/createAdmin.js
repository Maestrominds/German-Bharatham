const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  // 👇 CHANGE THESE TO YOUR PREFERRED ADMIN DETAILS
  const newEmail = "admin@german.com";
  const newPassword = "temPassword123";
  const newName = "Super Admin";

  console.log("⏳ Hashing password...");
  const hashedPassword = await bcrypt.hash(newPassword, 10);

  // 1. Delete the old default admin
  console.log("🗑️ Deleting old admin@german.com...");
  await prisma.user.deleteMany({
    where: { email: "admin@german.com" }
  });

  // 2. Create the new admin account
  console.log(`✨ Creating new admin: ${newEmail}...`);
  const tenYearsFromNow = new Date();
  tenYearsFromNow.setFullYear(tenYearsFromNow.getFullYear() + 10);

  const adminUser = await prisma.user.upsert({
    where: { email: newEmail },
    update: {
      password: hashedPassword,
      role: "admin",
      isActive: true,
      name: newName
    },
    create: {
      email: newEmail,
      name: newName,
      password: hashedPassword,
      role: "admin",
      isActive: true,
      subscriptionPlan: "free",
      subscriptionStatus: "active",
      subscriptionExpiresAt: tenYearsFromNow
    }
  });

  console.log("✅ SUCCESS! Your new admin account is ready.");
  console.log(`📧 Email: ${adminUser.email}`);
  console.log(`🔐 Password: (The one you typed in this file)`);
}

main()
  .catch((e) => {
    console.error("❌ Error:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
