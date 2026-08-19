const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const prisma = require('../config/prisma');
const { uploadBase64 } = require('../services/cloudinaryService');

async function migratePhotos() {
  console.log('🚀 Starting migration of Base64 user photos to Cloudinary...');

  try {
    // 1. Fetch all users whose photo starts with 'data:image'
    const users = await prisma.user.findMany({
      where: {
        photo: {
          startsWith: 'data:image',
        },
      },
      select: {
        id: true,
        email: true,
        photo: true,
      },
    });

    console.log(`🔍 Found ${users.length} users with Base64 profile pictures.`);

    if (users.length === 0) {
      console.log('✅ No users to migrate. Exiting...');
      return;
    }

    let successCount = 0;
    let failCount = 0;

    // 2. Iterate and upload to Cloudinary
    for (const user of users) {
      console.log(`\n☁️ Uploading photo for user: ${user.email} (ID: ${user.id})...`);
      
      try {
        const result = await uploadBase64(user.photo, 'german_bharatham/users');
        
        // 3. Update the user record with the new Cloudinary URL
        await prisma.user.update({
          where: { id: user.id },
          data: { photo: result.secure_url },
        });

        console.log(`✅ Success: ${user.email} -> ${result.secure_url}`);
        successCount++;
      } catch (uploadError) {
        console.error(`❌ Failed to upload photo for ${user.email}:`, uploadError.message);
        failCount++;
      }
    }

    console.log('\n🎉 Migration Complete!');
    console.log(`📊 Summary: ${successCount} successful, ${failCount} failed.`);
    
  } catch (error) {
    console.error('❌ Migration script failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

migratePhotos();
