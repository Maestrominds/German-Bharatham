const express = require('express');
const router = express.Router();
const prisma = require('../config/prisma');

const PLAYSTORE_URL = process.env.PLAYSTORE_URL || 'https://play.google.com/store/apps/details?id=com.german.german_bharatham_admin';
const APP_NAME = 'German Bharatham';

// Helper to escape HTML characters in strings for meta tags
const escapeHtml = (unsafe) => {
  if (!unsafe) return '';
  return String(unsafe)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
};

// GET /share/:category/:id or /l/:category/:id
router.get('/:category/:id', async (req, res) => {
  const { category, id } = req.params;
  const numericId = parseInt(id, 10);

  if (isNaN(numericId)) {
    return res.redirect(PLAYSTORE_URL);
  }

  const catLower = String(category || '').toLowerCase().trim();

  let title = APP_NAME;
  let description = 'Discover community listings, jobs, accommodations, and events for Indian expats in Germany.';
  let imageUrl = 'https://germanbharatham.cloud/Logo_V2.png';
  let categoryLabel = 'Listing';
  let location = '';

  try {
    if (catLower.includes('job')) {
      categoryLabel = 'Job Opportunity';
      const item = await prisma.jobListing.findUnique({ where: { id: numericId } });
      if (item) {
        title = item.title ? `${item.title} - ${item.companyName || APP_NAME}` : title;
        description = item.description || description;
        imageUrl = item.companyLogo || imageUrl;
        location = item.location || '';
      }
    } else if (catLower.includes('accommodat')) {
      categoryLabel = 'Accommodation';
      const item = await prisma.accommodation.findUnique({ where: { id: numericId } });
      if (item) {
        title = item.title ? `${item.title} - ${APP_NAME}` : title;
        description = item.description || description;
        imageUrl = item.image || (item.media?.images && item.media.images[0]) || imageUrl;
        location = item.city || '';
      }
    } else if (catLower.includes('event')) {
      categoryLabel = 'Event';
      const item = await prisma.event.findUnique({ where: { id: numericId } });
      if (item) {
        title = item.title ? `${item.title} - ${APP_NAME}` : title;
        description = item.shortDescription || item.description || description;
        imageUrl = item.posterUrl || (item.images && item.images[0]) || imageUrl;
        location = item.city || item.venue || (item.isOnline ? 'Online' : '');
      }
    } else if (catLower.includes('second') || catLower.includes('store')) {
      categoryLabel = 'Second Hand Item';
      const item = await prisma.secondHandStore.findUnique({ where: { id: numericId } });
      if (item) {
        title = item.title ? `${item.title} - ${APP_NAME}` : title;
        description = item.description || description;
        imageUrl = (item.images && item.images[0]) || imageUrl;
      }
    } else if (catLower.includes('food') || catLower.includes('grocery')) {
      categoryLabel = 'Food & Grocery';
      const item = await prisma.foodGrocery.findUnique({ where: { id: numericId } });
      if (item) {
        title = item.title ? `${item.title} - ${APP_NAME}` : title;
        description = item.description || description;
        imageUrl = item.image || imageUrl;
        location = item.city || '';
      }
    } else if (catLower.includes('service')) {
      categoryLabel = 'Expat Service';
      const item = await prisma.service.findUnique({ where: { id: numericId } });
      if (item) {
        title = (item.serviceName || item.title) ? `${item.serviceName || item.title} - ${APP_NAME}` : title;
        description = item.description || description;
        imageUrl = (item.images && item.images[0]) || imageUrl;
        location = item.city || '';
      }
    }
  } catch (err) {
    console.error('Error fetching listing for share preview:', err.message);
  }

  // Deep link custom URI scheme
  const appScheme = `germanbharatham://listing/${encodeURIComponent(catLower)}/${numericId}`;

  // Build responsive smart landing page with OpenGraph preview tags
  const safeTitle = escapeHtml(title);
  const safeDescription = escapeHtml(description.length > 200 ? description.substring(0, 197) + '...' : description);
  const safeImageUrl = escapeHtml(imageUrl);
  const safeLocation = escapeHtml(location);

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${safeTitle}</title>

  <!-- OpenGraph Meta Tags for WhatsApp, Telegram, Facebook, iMessage previews -->
  <meta property="og:title" content="${safeTitle}">
  <meta property="og:description" content="${safeDescription}">
  <meta property="og:image" content="${safeImageUrl}">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="${APP_NAME}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${safeTitle}">
  <meta name="twitter:description" content="${safeDescription}">
  <meta name="twitter:image" content="${safeImageUrl}">

  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
    body { background: #f4f6f8; color: #1e293b; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 16px; }
    .card { background: #ffffff; max-width: 440px; width: 100%; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.08); overflow: hidden; text-align: center; }
    .hero-img { width: 100%; height: 220px; object-fit: cover; background: #e2e8f0; }
    .content { padding: 24px; }
    .badge { display: inline-block; background: #e6f4ea; color: #137333; font-weight: 600; font-size: 12px; padding: 4px 12px; border-radius: 20px; margin-bottom: 12px; text-transform: uppercase; letter-spacing: 0.5px; }
    h1 { font-size: 20px; font-weight: 700; color: #0f172a; margin-bottom: 8px; line-height: 1.3; }
    .location { font-size: 14px; color: #64748b; margin-bottom: 12px; }
    p { font-size: 14px; color: #475569; line-height: 1.5; margin-bottom: 24px; }
    .btn-primary { display: block; width: 100%; background: #2e7d32; color: #ffffff; text-decoration: none; padding: 14px; border-radius: 10px; font-weight: 600; font-size: 15px; margin-bottom: 10px; transition: background 0.2s; border: none; cursor: pointer; }
    .btn-primary:hover { background: #256628; }
    .btn-secondary { display: block; width: 100%; background: #f1f5f9; color: #334155; text-decoration: none; padding: 12px; border-radius: 10px; font-weight: 500; font-size: 14px; border: 1px solid #cbd5e1; }
    .footer { font-size: 12px; color: #94a3b8; margin-top: 16px; }
  </style>
</head>
<body>
  <div class="card">
    <img class="hero-img" src="${safeImageUrl}" alt="${safeTitle}" onerror="this.src='https://germanbharatham.cloud/Logo_V2.png';">
    <div class="content">
      <span class="badge">${categoryLabel}</span>
      <h1>${safeTitle}</h1>
      ${safeLocation ? `<div class="location">📍 ${safeLocation}</div>` : ''}
      <p>${safeDescription}</p>

      <button id="openAppBtn" class="btn-primary" onclick="openApp()">Open in German Bharatham App</button>
      <a href="${PLAYSTORE_URL}" class="btn-secondary">Download on Google Play Store</a>

      <div class="footer">Connect & thrive in Germany with German Bharatham</div>
    </div>
  </div>

  <script>
    const appScheme = "${appScheme}";
    const playStoreUrl = "${PLAYSTORE_URL}";

    function isMobile() {
      return /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
    }

    function openApp() {
      const start = Date.now();
      window.location.href = appScheme;

      // If app isn't installed, the browser stays on this tab; redirect to Play Store after 1.5s
      setTimeout(function() {
        if (Date.now() - start < 2000) {
          window.location.href = playStoreUrl;
        }
      }, 1500);
    }

    // Auto-attempt opening the app if viewed on mobile phone
    if (isMobile()) {
      openApp();
    }
  </script>
</body>
</html>`;

  res.send(html);
});

module.exports = router;
