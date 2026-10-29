const express = require('express');
const router = express.Router();
const prisma = require('../config/prisma');

// Helper to compute card date label matching the spec format rules
const computeCardDateLabel = (item) => {
  const start = item.startsAt ? new Date(item.startsAt) : null;
  const end = item.endsAt ? new Date(item.endsAt) : null;
  const format = item.format || 'one_day';
  const timeText = item.timeText ? item.timeText.trim() : '';

  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  if (!start) return '';

  const sDay = dayNames[start.getDay()];
  const sDate = start.getDate();
  const sMonth = monthNames[start.getMonth()];

  if (format === 'one_day') {
    if (item.sessions && Array.isArray(item.sessions) && item.sessions.length > 0) {
      return `${sDay} ${sDate} ${sMonth} · ${item.sessions.length} slots`;
    }
    return `${sDay} ${sDate} ${sMonth}${timeText ? ' · ' + timeText : ''}`;
  }

  if (format === 'multi_day') {
    if (end) {
      const eDay = dayNames[end.getDay()];
      const eDate = end.getDate();
      const eMonth = monthNames[end.getMonth()];
      if (start.getMonth() === end.getMonth()) {
        return `${sDay} ${sDate} – ${eDay} ${eDate} ${sMonth}`;
      }
      return `${sDate} ${sMonth} – ${eDate} ${eMonth}`;
    }
    return `${sDay} ${sDate} ${sMonth}`;
  }

  if (format === 'course') {
    if (item.ongoing) {
      const days = (item.daysOfWeek || [])
        .map(d => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1] || '')
        .filter(Boolean)
        .join(', ');
      return `Ongoing${days ? ' · ' + days : ''} · from ${sDate} ${sMonth}`;
    }
    return `From ${sDate} ${sMonth}`;
  }

  if (format === 'screening') {
    const sessionCount = (item.sessions && Array.isArray(item.sessions)) ? item.sessions.length : 0;
    const cinemas = new Set(
      (item.sessions && Array.isArray(item.sessions))
        ? item.sessions.map(s => s.label || s.cinema).filter(Boolean)
        : []
    );
    const cinemaCount = cinemas.size > 0 ? cinemas.size : 1;
    const langStr = (item.languages && item.languages.length > 0) ? item.languages.join(', ') : '';

    if (end && start.getTime() !== end.getTime()) {
      return `${sDate}–${end.getDate()} ${sMonth} · ${cinemaCount} cinema${cinemaCount > 1 ? 's' : ''}${langStr ? ' · ' + langStr : ''}`;
    }
    return `${sDate} ${sMonth} · ${cinemaCount} cinema${cinemaCount > 1 ? 's' : ''}${langStr ? ' · ' + langStr : ''}`;
  }

  if (format === 'deadline') {
    if (end) {
      const eDay = dayNames[end.getDay()];
      const eDate = end.getDate();
      const eMonth = monthNames[end.getMonth()];
      return `Submit by ${eDay} ${eDate} ${eMonth}`;
    }
    return `Submit by ${sDay} ${sDate} ${sMonth}`;
  }

  return `${sDay} ${sDate} ${sMonth}`;
};

// Helper to map Prisma Event to frontend expectations
const mapEvent = (item) => {
  if (!item) return null;
  const link = item.ticketUrl || item.externalUrl || item.onlineLink || null;
  const poster = item.posterUrl || (item.images && item.images.length > 0 ? item.images[0] : null);

  return {
    ...item,
    _id: String(item.id),
    ticketUrl: link,
    externalUrl: link,
    posterUrl: poster,
    start_date: item.startsAt ? item.startsAt.toISOString() : null,
    end_date: item.endsAt ? item.endsAt.toISOString() : null,
    time_text: item.timeText,
    short_description: item.shortDescription || (item.description ? item.description.substring(0, 160) : ''),
    is_online: item.isOnline,
    venue_name: item.venue,
    price_type: item.priceType || 'paid',
    price_text: item.priceText || item.price,
    family_friendly: item.familyFriendly,
    days_of_week: item.daysOfWeek || [],
    organizer_name: item.organizer,
    cardDateLabel: computeCardDateLabel(item),
  };
};

// GET ALL VISIBLE EVENTS (Public / User)
router.get('/', async (req, res) => {
  try {
    const {
      city,
      category,
      format,
      when,
      from,
      to,
      language,
      free,
      family_friendly,
      english_subtitles,
      search,
      section,
      grouped,
    } = req.query;

    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const todayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);

    const where = {
      status: { in: ['Active', 'active', 'ACTIVE'] },
    };

    // 1. Date filter (When)
    let periodFrom = todayStart;
    let periodTo = null;
    let weekdaysInPeriod = null;

    if (when === 'today') {
      periodFrom = todayStart;
      periodTo = todayEnd;
      const jsDay = now.getDay(); // 0 is Sun
      weekdaysInPeriod = [jsDay === 0 ? 7 : jsDay];
    } else if (when === 'this_weekend') {
      const currentDay = now.getDay(); // 0 is Sun, 6 is Sat
      const diffToFri = (5 - currentDay + 7) % 7;
      const fri = new Date(now);
      fri.setDate(now.getDate() + diffToFri);
      fri.setHours(0, 0, 0, 0);

      const sun = new Date(fri);
      sun.setDate(fri.getDate() + 2);
      sun.setHours(23, 59, 59, 999);

      periodFrom = fri;
      periodTo = sun;
      weekdaysInPeriod = [5, 6, 7];
    } else if (when === 'this_week') {
      const currentDay = now.getDay();
      const diffToMon = currentDay === 0 ? -6 : 1 - currentDay;
      const mon = new Date(now);
      mon.setDate(now.getDate() + diffToMon);
      mon.setHours(0, 0, 0, 0);

      const sun = new Date(mon);
      sun.setDate(mon.getDate() + 6);
      sun.setHours(23, 59, 59, 999);

      periodFrom = mon;
      periodTo = sun;
      weekdaysInPeriod = [1, 2, 3, 4, 5, 6, 7];
    } else if (when === 'this_month') {
      const firstDay = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);
      const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
      periodFrom = firstDay;
      periodTo = lastDay;
      weekdaysInPeriod = [1, 2, 3, 4, 5, 6, 7];
    } else if (from || to) {
      if (from) periodFrom = new Date(from);
      if (to) periodTo = new Date(to);
    }

    // Apply date overlap: endsAt >= periodFrom AND (startsAt <= periodTo if defined)
    // Also auto-hide past events: endsAt >= periodFrom
    const dateConditions = [{ endsAt: { gte: periodFrom } }];
    if (periodTo) {
      dateConditions.push({ startsAt: { lte: periodTo } });
    }
    where.AND = (where.AND || []).concat(dateConditions);

    // 2. City filter: includes online events
    if (city && city.trim()) {
      const c = city.trim().toLowerCase();
      if (c === 'online') {
        where.isOnline = true;
      } else {
        where.OR = [
          { city: { contains: city.trim(), mode: 'insensitive' } },
          { isOnline: true },
        ];
      }
    }

    // 3. Category
    if (category && category.trim()) {
      where.category = { contains: category.trim(), mode: 'insensitive' };
    }

    // 4. Format
    if (format && format.trim()) {
      where.format = format.trim().toLowerCase();
    }

    // 5. Language filter
    if (language && language.trim()) {
      where.languages = { has: language.trim() };
    }

    // 6. Free filter
    if (free === 'true' || free === true) {
      where.priceType = 'free';
    }

    // 7. Family friendly
    if (family_friendly === 'true' || family_friendly === true) {
      where.familyFriendly = true;
    }

    // 8. English Subtitles
    if (english_subtitles === 'true' || english_subtitles === true) {
      where.subtitles = { equals: 'english', mode: 'insensitive' };
    }

    // 9. Search
    if (search && search.trim()) {
      const q = search.trim();
      const searchOR = [
        { title: { contains: q, mode: 'insensitive' } },
        { description: { contains: q, mode: 'insensitive' } },
        { shortDescription: { contains: q, mode: 'insensitive' } },
        { venue: { contains: q, mode: 'insensitive' } },
        { organizer: { contains: q, mode: 'insensitive' } },
      ];
      where.AND = (where.AND || []).concat([{ OR: searchOR }]);
    }

    // Fetch all matching events
    const allMatching = await prisma.event.findMany({
      where,
      orderBy: [
        { startsAt: 'asc' },
        { createdAt: 'desc' },
      ],
    });

    const mapped = allMatching.map(mapEvent);

    // If caller wants grouped response for the 4-section layout:
    if (grouped === 'true' || grouped === true) {
      const happeningNow = [];
      const upcoming = [];
      const movies = [];
      const classes = [];

      mapped.forEach((evt) => {
        const start = evt.startsAt ? new Date(evt.startsAt) : null;
        const end = evt.endsAt ? new Date(evt.endsAt) : null;
        const fmt = (evt.format || '').toLowerCase();
        const cat = (evt.category || '').toLowerCase();

        // Movies / Screenings
        if (cat === 'movies' || fmt === 'screening') {
          movies.push(evt);
        }

        // Classes & Courses
        if (cat === 'classes' || fmt === 'course' || fmt === 'workshop') {
          classes.push(evt);
        }

        // Happening Now: startsAt < now <= endsAt (multi-day, festivals, or active screenings)
        if (start && end && start < now && end >= now) {
          happeningNow.push(evt);
        } else if (fmt !== 'course') {
          // Upcoming: everything else except courses
          upcoming.push(evt);
        }
      });

      return res.json({
        happeningNow,
        upcoming,
        movies,
        classes,
        total: mapped.length,
      });
    }

    // Section filtering
    let result = mapped;
    if (section === 'happening_now') {
      result = mapped.filter(evt => {
        const s = evt.startsAt ? new Date(evt.startsAt) : null;
        const e = evt.endsAt ? new Date(evt.endsAt) : null;
        return s && e && s < now && e >= now;
      });
    } else if (section === 'movies') {
      result = mapped.filter(evt => evt.category === 'movies' || evt.format === 'screening');
    } else if (section === 'classes') {
      result = mapped.filter(evt => evt.category === 'classes' || evt.format === 'course' || evt.format === 'workshop');
    } else if (section === 'upcoming') {
      result = mapped.filter(evt => evt.format !== 'course');
    }

    // Pagination
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 20);
    const startIndex = (page - 1) * limit;
    const paginated = result.slice(startIndex, startIndex + limit);

    res.json({
      data: paginated,
      count: paginated.length,
      total: result.length,
      page,
      limit,
      totalPages: Math.ceil(result.length / limit),
    });
  } catch (e) {
    console.error('❌ GET /events/user error:', e.message);
    res.status(500).json({ message: e.message });
  }
});

// GET ONE EVENT BY ID
router.get('/:id', async (req, res) => {
  try {
    const numericId = parseInt(req.params.id);
    if (isNaN(numericId)) return res.status(400).json({ message: 'Invalid ID format' });

    const doc = await prisma.event.findUnique({
      where: { id: numericId },
    });

    if (!doc) return res.status(404).json({ message: 'Event not found' });
    res.json(mapEvent(doc));
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

module.exports = router;
