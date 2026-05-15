/**
 * ═══════════════════════════════════════════════════════════════
 * DYNAMIC NOTIFICATION TEMPLATE ENGINE SUBSYSTEM
 * ═══════════════════════════════════════════════════════════════
 * 
 * Responsible for decoupling marketing and operational string templates
 * from static backend logic. Supports multi-locale variable injection
 * and graceful failsafes to ensure consistent dispatch deliveries.
 */

const admin = require('firebase-admin');

// In-memory cache to prevent redundant database operations during high-frequency trigger spikes
const templateCache = {};
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Built-in baseline enterprise templates ensuring Zero-Downtime resilience
 * if database seeding has not fully hydrated target keys yet.
 */
const DEFAULT_TEMPLATES = {
  ORDER_SHIPPED: {
    category: 'orders',
    level: 'transactional',
    locales: {
      en: {
        title: '🚚 Handcrafted elegance, en route.',
        body: 'Your custom piece {{productName}} has safely left our secure facilities. Track package: {{trackingNumber}}.'
      },
      vi: {
        title: '🚚 Kiệt tác trang sức đang trên đường giao đến bạn.',
        body: 'Sản phẩm {{productName}} đã được bàn giao cho đơn vị vận chuyển bảo hiểm. Mã vận đơn: {{trackingNumber}}.'
      }
    }
  },
  COMMISSION_UNLOCKED: {
    category: 'finance',
    level: 'transactional',
    locales: {
      en: {
        title: '💰 Commission Unlocked',
        body: '✨ Exclusive Milestone: Your accrued partnership dividend of ${{amount}} has matured for immediate extraction.'
      },
      vi: {
        title: '💰 Hoa hồng khả dụng',
        body: '✨ Cột mốc đối tác: Khoản cổ tức tích lũy ${{amount}} của bạn đã sẵn sàng để rút về tài khoản bảo mật.'
      }
    }
  },
  GROWTH_MILESTONE: {
    category: 'analytics',
    level: 'analytics',
    locales: {
      en: {
        title: '📈 Exceptional Showcase Reach',
        body: '🔥 Curated Momentum: Your personal portfolio generated over {{clickCount}} discerning client interactions today!'
      }
    }
  }
};

/**
 * Resolves a dynamic template by key, injecting replacement variables cleanly.
 * 
 * @param {string} templateKey Target key mapping e.g., ORDER_SHIPPED
 * @param {object} variables Map of key-value substitution bindings
 * @param {string} locale Preferred string localization code e.g., 'en'
 * @returns {Promise<{title: string, body: string, category: string, level: string}>}
 */
async function resolveTemplate(templateKey, variables = {}, locale = 'en') {
  const now = Date.now();
  let templateObj = null;

  // 1. Check resilient low-latency runtime caching layers
  if (templateCache[templateKey] && (now - templateCache[templateKey].timestamp < CACHE_TTL_MS)) {
    templateObj = templateCache[templateKey].data;
  } else {
    try {
      const db = admin.firestore();
      const docSnap = await db.collection('notification_templates').doc(templateKey).get();
      if (docSnap.exists) {
        templateObj = docSnap.data();
        templateCache[templateKey] = {
          timestamp: now,
          data: templateObj
        };
      }
    } catch (err) {
      console.warn(`Template database hydration skip for ${templateKey}, executing local drop-in recovery:`, err.message);
    }
  }

  // 2. Failsafe to immutable local constants if external fetch unfulfilled
  if (!templateObj) {
    templateObj = DEFAULT_TEMPLATES[templateKey] || {
      category: 'system',
      level: 'system',
      locales: {
        en: {
          title: '✨ Update Notice',
          body: 'System event triggered successfully. Target payload references preserved.'
        }
      }
    };
  }

  // 3. Extract locale maps safely
  const localeBlocks = templateObj.locales || {};
  const activeStrings = localeBlocks[locale] || localeBlocks['en'] || {
    title: '✨ System Notification',
    body: 'Operational parameters initialized.'
  };

  // 4. Perform pure string regex mutations parsing {{variableKeys}}
  let finalTitle = activeStrings.title || '';
  let finalBody = activeStrings.body || '';

  for (const [vKey, vVal] of Object.entries(variables)) {
    const pattern = new RegExp(`\\{\\{${vKey}\\}\\}`, 'g');
    finalTitle = finalTitle.replace(pattern, vVal !== null && vVal !== undefined ? String(vVal) : '');
    finalBody = finalBody.replace(pattern, vVal !== null && vVal !== undefined ? String(vVal) : '');
  }

  return {
    title: finalTitle,
    body: finalBody,
    category: templateObj.category || 'system',
    level: templateObj.level || 'system'
  };
}

module.exports = {
  resolveTemplate
};
