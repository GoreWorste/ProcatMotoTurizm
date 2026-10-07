#!/usr/bin/env node
/**
 * Учебный REST API для ПР4 (прокат). Запуск:
 * node mock-server.js --port 8080 --origin http://localhost:5555
 */
const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const args = process.argv.slice(2);
const port = Number(args[args.indexOf('--port') + 1] || 8080);
const origin =
  args[args.indexOf('--origin') + 1] || 'http://localhost:5555';
const ttlIdx = args.indexOf('--ttl');
const accessTtlSec =
  ttlIdx >= 0 ? Number(args[ttlIdx + 1] || 60) : 15 * 60;
const refreshTtlSec = 7 * 24 * 3600;
const JWT_SECRET = 'procat-pr5-dev-secret';
const refreshStore = new Map();

const dbPath = path.join(__dirname, 'db.json');
let db = JSON.parse(fs.readFileSync(dbPath, 'utf8'));
if (!db.users) db.users = [];
if (!db.meta.userNextId) db.meta.userNextId = db.users.length + 1;

function save() {
  fs.writeFileSync(dbPath, JSON.stringify(db, null, 2));
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}

function send(res, status, body, extra = {}) {
  const payload = body === undefined ? '' : JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    ...corsHeaders(),
    ...extra,
  });
  res.end(payload);
}

function parseBody(req) {
  return new Promise((resolve) => {
    let data = '';
    req.on('data', (c) => (data += c));
    req.on('end', () => {
      if (!data) return resolve({});
      try {
        resolve(JSON.parse(data));
      } catch {
        resolve({});
      }
    });
  });
}

function delay(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function hashPassword(pw) {
  return crypto.createHash('sha256').update(`procat:${pw}`).digest('hex');
}

function b64urlJson(obj) {
  return Buffer.from(JSON.stringify(obj)).toString('base64url');
}

function signJwt(payload, ttlSec) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const body = { ...payload, exp: Math.floor(Date.now() / 1000) + ttlSec };
  const p1 = b64urlJson(header);
  const p2 = b64urlJson(body);
  const sig = crypto
    .createHmac('sha256', JWT_SECRET)
    .update(`${p1}.${p2}`)
    .digest('base64url');
  return `${p1}.${p2}.${sig}`;
}

function verifyJwt(token) {
  const parts = String(token).split('.');
  if (parts.length !== 3) return null;
  const [p1, p2, sig] = parts;
  const expected = crypto
    .createHmac('sha256', JWT_SECRET)
    .update(`${p1}.${p2}`)
    .digest('base64url');
  if (sig !== expected) return null;
  try {
    const body = JSON.parse(Buffer.from(p2, 'base64url').toString());
    if (body.exp && body.exp < Math.floor(Date.now() / 1000)) return null;
    return body;
  } catch {
    return null;
  }
}

function userPublic(u) {
  return {
    id: u.id,
    username: u.username,
    displayName: u.displayName || u.username,
    role: u.role,
  };
}

function findUser(username) {
  return db.users.find((u) => u.username === username);
}

function issueTokens(user) {
  const accessToken = signJwt({ sub: user.id, role: user.role }, accessTtlSec);
  const refreshToken = crypto.randomBytes(32).toString('hex');
  refreshStore.set(refreshToken, {
    userId: user.id,
    exp: Date.now() + refreshTtlSec * 1000,
  });
  return { accessToken, refreshToken, user: userPublic(user) };
}

function authFromRequest(req) {
  const h = req.headers.authorization || req.headers.Authorization;
  if (!h || !String(h).startsWith('Bearer ')) return null;
  const payload = verifyJwt(String(h).slice(7));
  if (!payload) return null;
  return db.users.find((u) => u.id === payload.sub) || null;
}

function roleAllows(role, method, resource) {
  const m = method.toUpperCase();
  if (m === 'GET') return true;
  if (role === 'admin') return true;
  if (role === 'viewer') return false;
  if (role === 'manager') {
    return resource === 'equipment' || resource === 'clients';
  }
  return false;
}

async function handleAuth(req, res, parts) {
  const action = parts[1];
  const body = await parseBody(req);

  if (action === 'login' && req.method === 'POST') {
    const user = findUser(body.username);
    if (!user || user.passwordHash !== hashPassword(body.password || '')) {
      return send(res, 401, { message: 'Неверный логин или пароль' });
    }
    return send(res, 200, issueTokens(user));
  }

  if (action === 'register' && req.method === 'POST') {
    const username = String(body.username || '').trim();
    if (username.length < 3) {
      return send(res, 422, { message: 'Логин слишком короткий' });
    }
    if (findUser(username)) {
      return send(res, 409, { message: 'Пользователь уже существует' });
    }
    const user = {
      id: db.meta.userNextId++,
      username,
      passwordHash: hashPassword(body.password || ''),
      role: 'viewer',
      displayName: body.displayName || username,
    };
    db.users.push(user);
    save();
    return send(res, 201, issueTokens(user));
  }

  if (action === 'refresh' && req.method === 'POST') {
    const entry = refreshStore.get(body.refreshToken);
    if (!entry || entry.exp < Date.now()) {
      return send(res, 401, { message: 'Refresh-токен недействителен' });
    }
    const user = db.users.find((u) => u.id === entry.userId);
    if (!user) return send(res, 401, { message: 'Пользователь не найден' });
    refreshStore.delete(body.refreshToken);
    return send(res, 200, issueTokens(user));
  }

  if (action === 'me' && req.method === 'GET') {
    const user = authFromRequest(req);
    if (!user) return send(res, 401, { message: 'Требуется вход' });
    return send(res, 200, userPublic(user));
  }

  return send(res, 404, { message: 'Not found' });
}

async function handleAdmin(req, res, parts) {
  const user = authFromRequest(req);
  if (!user) return send(res, 401, { message: 'Требуется вход' });
  if (user.role !== 'admin') {
    return send(res, 403, { message: 'Недостаточно прав' });
  }
  if (parts[1] === 'users' && req.method === 'GET') {
    return send(res, 200, { items: db.users.map(userPublic) });
  }
  return send(res, 404, { message: 'Not found' });
}

function pageSlice(list, q) {
  const page = Math.max(1, Number(q.page || 1));
  const size = Math.max(1, Number(q.size || 10));
  const start = (page - 1) * size;
  return {
    items: list.slice(start, start + size),
    page,
    size,
    total: list.length,
  };
}

function sortList(list, sort) {
  const [field, dir] = String(sort || 'name,asc').split(',');
  const asc = (dir || 'asc') !== 'desc';
  return [...list].sort((a, b) => {
    const av = a[field];
    const bv = b[field];
    if (av === bv) return 0;
    if (av == null) return 1;
    if (bv == null) return -1;
    const cmp = av < bv ? -1 : 1;
    return asc ? cmp : -cmp;
  });
}

function active(list, includeDeleted) {
  if (includeDeleted) return list;
  return list.filter((x) => !x.deletedAt);
}

function equipmentFilters(list, q) {
  let out = list;
  const search = (q.search || '').trim().toLowerCase();
  if (search) {
    out = out.filter(
      (e) =>
        e.name.toLowerCase().includes(search) ||
        e.inventoryNumber.toLowerCase().includes(search),
    );
  }
  if (q.categoryId) out = out.filter((e) => e.categoryId === Number(q.categoryId));
  if (q.brandId) out = out.filter((e) => e.brandId === Number(q.brandId));
  if (q.dailyRateFrom) out = out.filter((e) => e.dailyRate >= Number(q.dailyRateFrom));
  if (q.dailyRateTo) out = out.filter((e) => e.dailyRate <= Number(q.dailyRateTo));
  if (q.yearFrom) out = out.filter((e) => e.purchaseYear >= Number(q.yearFrom));
  if (q.yearTo) out = out.filter((e) => e.purchaseYear <= Number(q.yearTo));
  return out;
}

function clientFilters(list, q) {
  let out = list;
  const search = (q.search || '').trim().toLowerCase();
  if (search) {
    out = out.filter(
      (c) =>
        c.fullName.toLowerCase().includes(search) ||
        c.email.toLowerCase().includes(search) ||
        c.phone.includes(search),
    );
  }
  if (q.city) out = out.filter((c) => c.city === q.city);
  return out;
}

function namedFilters(list, q) {
  const search = (q.search || '').trim().toLowerCase();
  if (!search) return list;
  return list.filter((x) => x.name.toLowerCase().includes(search));
}

function countEquipment(field, id) {
  return db.equipment.filter((e) => !e.deletedAt && e[field] === id).length;
}

async function handle(req, res) {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders());
    return res.end();
  }

  const url = new URL(req.url, `http://localhost:${port}`);
  const q = Object.fromEntries(url.searchParams.entries());

  if (q.__fail) {
    const code = Number(q.__fail) || 500;
    return send(res, code, { message: `Учебная ошибка ${code}` });
  }
  if (q.__delay) {
    await delay(Number(q.__delay) || 1500);
  }

  const pathname = url.pathname.replace(/\/+$/, '') || '/';

  if (pathname === '/api/__health') {
    return send(res, 200, { ok: true, origin });
  }

  if (!pathname.startsWith('/api/')) {
    return send(res, 404, { message: 'Not found' });
  }

  const parts = pathname.slice('/api/'.length).split('/').filter(Boolean);

  if (parts[0] === 'auth') {
    return handleAuth(req, res, parts);
  }

  if (parts[0] === 'admin') {
    return handleAdmin(req, res, parts);
  }

  const user = authFromRequest(req);
  if (!user) {
    return send(res, 401, {
      message: 'Требуется вход. Выполните POST /api/auth/login',
    });
  }

  const resource = parts[0];
  const isBulk = parts[1] === 'bulk-delete';

  if (!roleAllows(user.role, req.method, resource)) {
    return send(res, 403, { message: 'Недостаточно прав для этой операции' });
  }
  const id =
    !isBulk && parts[1] && /^\d+$/.test(parts[1]) ? Number(parts[1]) : null;
  const action = parts[2];

  if (resource === 'equipment' && parts[1] === 'meta' && parts[2] === 'brand-ids') {
    const categoryId = Number(q.categoryId);
    const ids = [
      ...new Set(
        db.equipment
          .filter((e) => !e.deletedAt && e.categoryId === categoryId)
          .map((e) => e.brandId),
      ),
    ];
    return send(res, 200, { brandIds: ids });
  }

  const collections = {
    equipment: 'equipment',
    clients: 'clients',
    categories: 'categories',
    brands: 'brands',
    tags: 'tags',
  };
  const key = collections[resource];
  if (!key) return send(res, 404, { message: 'Unknown resource' });

  const list = db[key];

  if (parts[1] === 'bulk-delete' && req.method === 'POST') {
    const body = await parseBody(req);
    const ids = body.ids || [];
    let deleted = 0;
    for (const rawId of ids) {
      const idx = list.findIndex((e) => e.id === rawId);
      if (idx >= 0) {
        list.splice(idx, 1);
        deleted++;
      }
    }
    save();
    return send(res, 200, { deleted });
  }

  if (id && action === 'restore' && req.method === 'POST') {
    const item = list.find((x) => x.id === id);
    if (!item) return send(res, 404, { message: 'Запись не найдена' });
    item.deletedAt = null;
    save();
    return send(res, 200, item);
  }

  if (req.method === 'GET' && !id) {
    let filtered = active(list, q.includeDeleted === 'true');
    if (resource === 'equipment') filtered = equipmentFilters(filtered, q);
    if (resource === 'clients') filtered = clientFilters(filtered, q);
    if (['categories', 'brands', 'tags'].includes(resource)) {
      filtered = namedFilters(filtered, q);
    }
    filtered = sortList(filtered, q.sort);
    return send(res, 200, pageSlice(filtered, q));
  }

  if (req.method === 'GET' && id) {
    const item = list.find((x) => x.id === id);
    if (!item) return send(res, 404, { message: 'Запись не найдена' });
    return send(res, 200, item);
  }

  if (req.method === 'POST' && !id) {
    const body = await parseBody(req);
    if (resource === 'equipment') {
      const dup = list.some(
        (e) =>
          e.inventoryNumber === body.inventoryNumber && !e.deletedAt,
      );
      if (dup) {
        return send(res, 422, {
          message: 'Ошибка валидации',
          errors: { inventoryNumber: 'Инвентарный номер уже используется' },
        });
      }
      if (body.unitsAvailable === 0 && body.unitsTotal === 0) {
        return send(res, 409, {
          message: 'Нет доступных единиц для проката',
        });
      }
      const created = { ...body, id: db.meta.equipmentNextId++ };
      list.push(created);
      save();
      return send(res, 201, created);
    }
    if (resource === 'clients') {
      const dup = list.some((c) => c.email === body.email && !c.deletedAt);
      if (dup) {
        return send(res, 422, {
          message: 'Ошибка валидации',
          errors: { email: 'Email уже зарегистрирован' },
        });
      }
      const created = { ...body, id: db.meta.clientNextId++ };
      list.push(created);
      save();
      return send(res, 201, created);
    }
    const created = {
      name: body.name,
      id: list.length ? Math.max(...list.map((x) => x.id)) + 1 : 1,
      deletedAt: null,
    };
    list.push(created);
    save();
    return send(res, 201, created);
  }

  if (req.method === 'PUT' && id) {
    const body = await parseBody(req);
    const idx = list.findIndex((x) => x.id === id);
    if (idx < 0) return send(res, 404, { message: 'Запись не найдена' });
    if (resource === 'equipment') {
      const dup = list.some(
        (e) =>
          e.inventoryNumber === body.inventoryNumber &&
          e.id !== id &&
          !e.deletedAt,
      );
      if (dup) {
        return send(res, 422, {
          message: 'Ошибка валидации',
          errors: { inventoryNumber: 'Инвентарный номер уже используется' },
        });
      }
      list[idx] = { ...list[idx], ...body, id };
    } else if (resource === 'clients') {
      list[idx] = { ...list[idx], ...body, id };
    } else {
      list[idx] = { ...list[idx], name: body.name, id };
    }
    save();
    return send(res, 200, list[idx]);
  }

  if (req.method === 'DELETE' && id) {
    const idx = list.findIndex((x) => x.id === id);
    if (idx < 0) return send(res, 404, { message: 'Запись не найдена' });
    const hard = q.hard === 'true';
    if (hard && (resource === 'brands' || resource === 'categories')) {
      const field = resource === 'brands' ? 'brandId' : 'categoryId';
      const count = countEquipment(field, id);
      if (count > 0) {
        return send(res, 409, {
          message: `Нельзя удалить: связано единиц оборудования — ${count}`,
        });
      }
    }
    if (hard) {
      list.splice(idx, 1);
    } else {
      list[idx].deletedAt = new Date().toISOString();
    }
    save();
    return send(res, 204);
  }

  if (req.method === 'POST' && id && action === 'bulk-delete') {
    // not used
  }

  const bulkKey = `${resource}/bulk-delete`;
  if (pathname.endsWith(bulkKey) && req.method === 'POST') {
    const body = await parseBody(req);
    const ids = body.ids || [];
    let deleted = 0;
    for (const rawId of ids) {
      const idx = list.findIndex((e) => e.id === rawId);
      if (idx >= 0) {
        list.splice(idx, 1);
        deleted++;
      }
    }
    save();
    return send(res, 200, { deleted });
  }

  return send(res, 405, { message: 'Method not allowed' });
}

const server = http.createServer((req, res) => {
  handle(req, res).catch((err) => {
    console.error(err);
    send(res, 500, { message: 'Internal error' });
  });
});

server.listen(port, () => {
  console.log(
    `Mock API http://localhost:${port}/api  CORS origin=${origin}  accessTTL=${accessTtlSec}s`,
  );
});
