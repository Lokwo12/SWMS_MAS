const apiBaseInput = document.getElementById('apiBase');
const opResult = document.getElementById('opResult');
const eventCards = document.getElementById('eventCards');
const wsState = document.getElementById('wsState');
const connectWsBtn = document.getElementById('connectWs');
const clearEventsBtn = document.getElementById('clearEvents');
const exportJsonBtn = document.getElementById('exportJson');
const exportCsvBtn = document.getElementById('exportCsv');
const exportFilteredJsonBtn = document.getElementById('exportFilteredJson');
const exportFilteredCsvBtn = document.getElementById('exportFilteredCsv');
const typeFilter = document.getElementById('typeFilter');
const agentFilter = document.getElementById('agentFilter');
const totalCount = document.getElementById('totalCount');
const visibleCount = document.getElementById('visibleCount');
const binBoard = document.getElementById('binBoard');
const truckBoard = document.getElementById('truckBoard');
const ccCard = document.getElementById('ccCard');
const loggerCard = document.getElementById('loggerCard');
const flowTopology = document.getElementById('flowTopology');
const flowLinks = document.getElementById('flowLinks');
const diagWaitingCount = document.getElementById('diagWaitingCount');
const diagRefusedCount = document.getElementById('diagRefusedCount');
const diagBlockedCount = document.getElementById('diagBlockedCount');
const diagCooldownCount = document.getElementById('diagCooldownCount');
const diagPendingBins = document.getElementById('diagPendingBins');
const diagLastTs = document.getElementById('diagLastTs');
const collectionLineChart = document.getElementById('collectionLineChart');
const collectionPieChart = document.getElementById('collectionPieChart');
const collectionPieLegend = document.getElementById('collectionPieLegend');
const lineTotal = document.getElementById('lineTotal');
const pieWindow = document.getElementById('pieWindow');
const slaWindow = document.getElementById('slaWindow');
const slaStageChart = document.getElementById('slaStageChart');
const slaLegend = document.getElementById('slaLegend');
const slaMetrics = document.getElementById('slaMetrics');
const utilWindow = document.getElementById('utilWindow');
const utilBarChart = document.getElementById('utilBarChart');
const utilLegend = document.getElementById('utilLegend');
const utilMetrics = document.getElementById('utilMetrics');
const viewModeSelect = document.getElementById('viewMode');
const pvSystemState = document.getElementById('pvSystemState');
const pvWsState = document.getElementById('pvWsState');
const pvActiveLinks = document.getElementById('pvActiveLinks');
const pvPendingBins = document.getElementById('pvPendingBins');
const pvCollections30 = document.getElementById('pvCollections30');
const pvAlertMix = document.getElementById('pvAlertMix');
const pvBins = document.getElementById('pvBins');
const pvTrucks = document.getElementById('pvTrucks');
const pvLastEvent = document.getElementById('pvLastEvent');
const pvUpdatedAt = document.getElementById('pvUpdatedAt');

const svcName = document.getElementById('svcName');
const svcState = document.getElementById('svcState');
const svcSession = document.getElementById('svcSession');
const svcTs = document.getElementById('svcTs');

let ws = null;
let wsReconnectTimer = null;
let wsReconnectAttempts = 0;
let wsShouldReconnect = true;
const events = [];
const knownTypes = new Set(['all']);
const KNOWN_EVENT_TYPES = new Set(['full_received', 'requesting', 'assigned', 'refused', 'completed', 'reset', 'working', 'ready', 'bin_level', 'waiting', 'blocked_not_full', 'truck_state']);
const FLOW_ACTIVE_MS = 7000;
const WS_RECONNECT_BASE_MS = 1000;
const WS_RECONNECT_MAX_MS = 10000;
const UI_EVENT_DEDUP_MS = 800;
const VIEW_MODE_STORAGE_KEY = 'mas-dashboard-view';
const recentUiEvents = new Map();
const flowState = {
  'smart_bin1->control_center': { count: 0, lastAt: null, lastType: '-' },
  'smart_bin2->control_center': { count: 0, lastAt: null, lastType: '-' },
  'smart_bin3->control_center': { count: 0, lastAt: null, lastType: '-' },
  'control_center->truck1': { count: 0, lastAt: null, lastType: '-' },
  'control_center->truck2': { count: 0, lastAt: null, lastType: '-' },
  'control_center->truck3': { count: 0, lastAt: null, lastType: '-' },
  'truck1->smart_bin1': { count: 0, lastAt: null, lastType: '-' },
  'truck1->smart_bin2': { count: 0, lastAt: null, lastType: '-' },
  'truck1->smart_bin3': { count: 0, lastAt: null, lastType: '-' },
  'truck2->smart_bin1': { count: 0, lastAt: null, lastType: '-' },
  'truck2->smart_bin2': { count: 0, lastAt: null, lastType: '-' },
  'truck2->smart_bin3': { count: 0, lastAt: null, lastType: '-' },
  'truck3->smart_bin1': { count: 0, lastAt: null, lastType: '-' },
  'truck3->smart_bin2': { count: 0, lastAt: null, lastType: '-' },
  'truck3->smart_bin3': { count: 0, lastAt: null, lastType: '-' },
  'control_center->logger': { count: 0, lastAt: null, lastType: '-' },
};
const boardState = {
  bins: {
    smart_bin1: { state: 'idle', updatedAt: '-' },
    smart_bin2: { state: 'idle', updatedAt: '-' },
    smart_bin3: { state: 'idle', updatedAt: '-' },
  },
  trucks: {
    truck1: { state: 'ready', updatedAt: '-' },
    truck2: { state: 'ready', updatedAt: '-' },
    truck3: { state: 'ready', updatedAt: '-' },
  },
  controlCenter: { state: 'idle', updatedAt: '-' },
  logger: { state: 'disconnected', updatedAt: '-' },
};
const flowDiagState = {
  waiting: 0,
  refused: 0,
  blocked: 0,
  pendingBins: new Set(),
  lastTs: '-',
};

let dashboardEpochMs = Date.now();

const readBase = () => (apiBaseInput?.value || detectDefaultApiBase()).replace(/\/$/, '');

function detectDefaultApiBase() {
  const { protocol, hostname } = window.location;
  return `${protocol}//${hostname}:8080`;
}

function initApiBase() {
  const current = (apiBaseInput.value || '').trim();
  if (!current || current.includes('localhost')) {
    apiBaseInput.value = detectDefaultApiBase();
  }
}

function createFlowTopology() {
  if (!flowTopology) return;
  flowTopology.innerHTML = `
    <svg class="topology-svg" viewBox="0 0 1000 420" preserveAspectRatio="xMidYMid meet">
      <defs>
        <marker id="flowArrow" markerWidth="12" markerHeight="12" refX="11" refY="6" orient="auto" markerUnits="strokeWidth">
          <path d="M0,0 L12,6 L0,12 z" fill="context-stroke" />
        </marker>
      </defs>

      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="smart_bin1->control_center" x1="192" y1="84" x2="458" y2="182"></line>
      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="smart_bin2->control_center" x1="500" y1="82" x2="500" y2="179"></line>
      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="smart_bin3->control_center" x1="808" y1="84" x2="542" y2="182"></line>

      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="control_center->truck1" x1="458" y1="198" x2="192" y2="315"></line>
      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="control_center->truck2" x1="500" y1="201" x2="500" y2="318"></line>
      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="control_center->truck3" x1="542" y1="198" x2="808" y2="315"></line>

      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="truck1->smart_bin1" x1="150" y1="318" x2="150" y2="82"></line>
      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="truck1->smart_bin2" x1="192" y1="315" x2="492" y2="85"></line>
      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="truck1->smart_bin3" x1="202" y1="311" x2="808" y2="87"></line>

      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="truck2->smart_bin1" x1="492" y1="315" x2="192" y2="87"></line>
      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="truck2->smart_bin2" x1="500" y1="318" x2="500" y2="82"></line>
      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="truck2->smart_bin3" x1="508" y1="315" x2="808" y2="87"></line>

      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="truck3->smart_bin1" x1="798" y1="311" x2="192" y2="87"></line>
      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="truck3->smart_bin2" x1="808" y1="315" x2="508" y2="85"></line>
      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="truck3->smart_bin3" x1="850" y1="318" x2="850" y2="82"></line>

      <line class="topology-line" marker-end="url(#flowArrow)" data-flow-link="control_center->logger" x1="536" y1="189" x2="898" y2="189"></line>
    </svg>

    <div class="topology-node node-bin1"><span class="node-icon">🗑️</span><span class="node-label">smart_bin1</span></div>
    <div class="topology-node node-bin2"><span class="node-icon">🗑️</span><span class="node-label">smart_bin2</span></div>
    <div class="topology-node node-bin3"><span class="node-icon">🗑️</span><span class="node-label">smart_bin3</span></div>
    <div class="topology-node node-cc"><span class="node-icon">🎛️</span><span class="node-label">control_center</span></div>
    <div class="topology-node node-truck1"><span class="node-icon">🚚</span><span class="node-label">truck1</span></div>
    <div class="topology-node node-truck2"><span class="node-icon">🚚</span><span class="node-label">truck2</span></div>
    <div class="topology-node node-truck3"><span class="node-icon">🚚</span><span class="node-label">truck3</span></div>
    <div class="topology-node node-logger"><span class="node-icon">🧾</span><span class="node-label">logger</span></div>
  `;
}

function iconForAgent(id) {
  if (!id) return '•';
  if (id.startsWith('smart_bin')) return '🗑️';
  if (id.startsWith('truck')) return '🚚';
  if (id === 'control_center') return '🎛️';
  if (id === 'logger') return '🧾';
  return '•';
}

function tileClassForState(stateText) {
  const s = String(stateText || '').toLowerCase();
  if (s.includes('full') || s.includes('refused')) return 'tile-warn';
  if (s.includes('dispatching') || s.includes('assigned') || s.includes('working') || s.includes('servicing') || s.includes('busy') || s.includes('cooldown')) return 'tile-live';
  if (s.includes('completed') || s.includes('collected') || s.includes('ready')) return 'tile-ok';
  return '';
}

function extractBinLevel(info) {
  const state = String(info?.state ?? '').toLowerCase();
  const pct = String(info?.state ?? '').match(/(\d+)%/);
  if (pct) return Math.max(0, Math.min(100, Number(pct[1])));
  if (state.includes('full')) return 100;
  if (state.includes('collected') || state.includes('idle') || state.includes('reset') || state.includes('cooldown')) return 0;
  return null;
}

function isFlowLinkActive(info, nowMs) {
  const lastMs = info && info.lastAt ? Date.parse(info.lastAt) : 0;
  return Number.isFinite(lastMs) && lastMs > 0 && nowMs - lastMs <= FLOW_ACTIVE_MS;
}

function readStoredViewMode() {
  try {
    return localStorage.getItem(VIEW_MODE_STORAGE_KEY) || 'standard';
  } catch {
    return 'standard';
  }
}

function storeViewMode(mode) {
  try {
    localStorage.setItem(VIEW_MODE_STORAGE_KEY, mode);
  } catch {
    // no-op
  }
}

function resetDashboardState({ resetEpoch = true } = {}) {
  if (resetEpoch) dashboardEpochMs = Date.now();

  events.length = 0;
  knownTypes.clear();
  knownTypes.add('all');

  Object.keys(flowState).forEach((link) => {
    flowState[link].count = 0;
    flowState[link].lastAt = null;
    flowState[link].lastType = '-';
  });

  boardState.bins.smart_bin1 = { state: 'idle', updatedAt: '-' };
  boardState.bins.smart_bin2 = { state: 'idle', updatedAt: '-' };
  boardState.bins.smart_bin3 = { state: 'idle', updatedAt: '-' };
  boardState.trucks.truck1 = { state: 'ready', updatedAt: '-' };
  boardState.trucks.truck2 = { state: 'ready', updatedAt: '-' };
  boardState.trucks.truck3 = { state: 'ready', updatedAt: '-' };
  boardState.controlCenter = { state: 'idle', updatedAt: '-' };
  boardState.logger = { state: 'disconnected', updatedAt: '-' };

  flowDiagState.waiting = 0;
  flowDiagState.refused = 0;
  flowDiagState.blocked = 0;
  flowDiagState.pendingBins.clear();
  flowDiagState.lastTs = '-';

  renderTypeOptions();
  renderEvents();
  renderStatusBoard();
  renderFlowLinks();
  renderFlowDiagnostics();
  renderCollectionReports();
  renderPresentationView();
}

function applyViewMode(mode) {
  const nextMode = mode === 'presentation' ? 'presentation' : 'standard';
  document.body.classList.toggle('mode-presentation', nextMode === 'presentation');
  if (viewModeSelect) viewModeSelect.value = nextMode;
  storeViewMode(nextMode);
}

function initViewMode() {
  if (!viewModeSelect) return;
  applyViewMode(readStoredViewMode());
  viewModeSelect.addEventListener('change', () => {
    applyViewMode(viewModeSelect.value);
    renderCollectionReports();
  });
}

function renderFlowTopology() {
  if (!flowTopology) return;
  const now = Date.now();
  flowTopology.querySelectorAll('.topology-line').forEach((line) => {
    const key = line.dataset.flowLink;
    const info = flowState[key];
    const active = isFlowLinkActive(info, now);
    line.classList.toggle('active', active);
    line.setAttribute('title', `${key} | msg: ${info?.count ?? 0} | last: ${info?.lastType ?? '-'} | at: ${fmtTs(info?.lastAt)}`);
  });
}

function renderTypeOptions() {
  if (!typeFilter) return;
  const current = typeFilter.value;
  typeFilter.innerHTML = '';
  Array.from(knownTypes).forEach((type) => {
    const opt = document.createElement('option');
    opt.value = type;
    opt.textContent = type;
    typeFilter.appendChild(opt);
  });
  typeFilter.value = knownTypes.has(current) ? current : 'all';
}

function fmtTs(ts) {
  if (!ts) return '-';
  const d = new Date(ts);
  if (Number.isNaN(d.getTime())) return ts;
  return d.toLocaleTimeString();
}

function renderStatusBoard() {
  binBoard.innerHTML = Object.entries(boardState.bins)
    .map(
      ([id, info]) => {
        const level = extractBinLevel(info);
        const levelText = level === null ? '--' : `${level}%`;
        let levelClass = 'level-low';
        if (level !== null && level >= 80) levelClass = 'level-high';
        else if (level !== null && level >= 50) levelClass = 'level-mid';
        const stateClass = tileClassForState(info.state);
        return `
      <div class="status-tile ${stateClass}">
        <div class="tile-id"><span class="tile-icon">${iconForAgent(id)}</span>${id}</div>
        <div class="tile-state">${info.state}</div>
        <div class="bin-progress-wrap">
          <div class="bin-progress-track">
            <div class="bin-progress-fill ${levelClass}" style="width: ${level === null ? 0 : level}%;"></div>
          </div>
          <span class="bin-progress-pct">${levelText}</span>
        </div>
        <div class="tile-ts">updated: ${fmtTs(info.updatedAt)}</div>
      </div>`;
      }
    )
    .join('');

  truckBoard.innerHTML = Object.entries(boardState.trucks)
    .map(
      ([id, info]) => `
      <div class="status-tile ${tileClassForState(info.state)}">
        <div class="tile-id"><span class="tile-icon">${iconForAgent(id)}</span>${id}</div>
        <div class="tile-state">${info.state}</div>
        <div class="tile-ts">updated: ${fmtTs(info.updatedAt)}</div>
      </div>`
    )
    .join('');

  ccCard.innerHTML = `
    <div class="status-tile ${tileClassForState(boardState.controlCenter.state)}">
      <div class="tile-id"><span class="tile-icon">${iconForAgent('control_center')}</span>control_center</div>
      <div class="tile-state">${boardState.controlCenter.state}</div>
      <div class="tile-ts">updated: ${fmtTs(boardState.controlCenter.updatedAt)}</div>
    </div>
  `;

  loggerCard.innerHTML = `
    <div class="status-tile ${tileClassForState(boardState.logger.state)}">
      <div class="tile-id"><span class="tile-icon">${iconForAgent('logger')}</span>logger</div>
      <div class="tile-state">${boardState.logger.state}</div>
      <div class="tile-ts">updated: ${fmtTs(boardState.logger.updatedAt)}</div>
    </div>
  `;

  renderPresentationView();
}

function renderPresentationView() {
  if (!pvSystemState || !pvBins || !pvTrucks) return;

  const nowMs = Date.now();
  const activeLinks = Object.values(flowState).filter((info) => isFlowLinkActive(info, nowMs)).length;
  const pendingCount = flowDiagState.pendingBins.size;
  const thirtyMinAgo = nowMs - (30 * 60 * 1000);
  const completedInWindow = events.filter((evt) => evt.type === 'completed' && Date.parse(evt.ts || '') >= thirtyMinAgo).length;

  pvSystemState.textContent = (svcState?.textContent || '-').trim() || '-';
  pvWsState.textContent = (wsState?.textContent || '-').trim() || '-';
  pvActiveLinks.textContent = String(activeLinks);
  pvPendingBins.textContent = String(pendingCount);
  pvCollections30.textContent = String(completedInWindow);
  pvAlertMix.textContent = `${flowDiagState.waiting}/${flowDiagState.refused}/${flowDiagState.blocked}`;

  pvBins.innerHTML = Object.entries(boardState.bins)
    .map(([id, info]) => `
      <div class="presentation-item ${tileClassForState(info.state)}">
        <span class="tile-icon">${iconForAgent(id)}</span>
        <span>
          <div class="presentation-item-id">${id}</div>
          <div class="presentation-item-state">${info.state}</div>
        </span>
        <span class="presentation-item-time">${fmtTs(info.updatedAt)}</span>
      </div>
    `)
    .join('');

  pvTrucks.innerHTML = Object.entries(boardState.trucks)
    .map(([id, info]) => `
      <div class="presentation-item ${tileClassForState(info.state)}">
        <span class="tile-icon">${iconForAgent(id)}</span>
        <span>
          <div class="presentation-item-id">${id}</div>
          <div class="presentation-item-state">${info.state}</div>
        </span>
        <span class="presentation-item-time">${fmtTs(info.updatedAt)}</span>
      </div>
    `)
    .join('');

  const latestEvent = events[0];
  if (pvLastEvent) {
    if (!latestEvent) {
      pvLastEvent.textContent = '-';
    } else {
      const context = latestEvent.data?.bin || latestEvent.data?.truck || latestEvent.source || '-';
      pvLastEvent.textContent = `${latestEvent.type} (${context})`;
    }
  }
  if (pvUpdatedAt) pvUpdatedAt.textContent = fmtTs(new Date().toISOString());
}

function touchFlowLink(link, ts, type) {
  if (!flowState[link]) return;
  flowState[link].count += 1;
  flowState[link].lastAt = ts;
  flowState[link].lastType = type || '-';
}

function inferFlowLinks(evt) {
  const data = evt.data || {};
  const type = evt.type || 'unknown';
  const ts = evt.ts || new Date().toISOString();
  const bin = data.bin;
  const truck = data.truck;

  if (bin && type === 'full_received') {
    touchFlowLink(`${bin}->control_center`, ts, type);
  }

  if (truck && ['requesting', 'assigned'].includes(type)) {
    touchFlowLink(`control_center->${truck}`, ts, type);
  }

  if (type === 'waiting' && bin) {
    touchFlowLink(`${bin}->control_center`, ts, type);
  }

  if (bin && truck && ['working', 'completed', 'refused'].includes(type)) {
    touchFlowLink(`${truck}->${bin}`, ts, type);
  }

  if (['full_received', 'requesting', 'assigned', 'completed', 'refused', 'waiting', 'blocked_not_full'].includes(type)) {
    touchFlowLink('control_center->logger', ts, type);
  }
}

function renderFlowLinks() {
  if (!flowLinks) return;
  const now = Date.now();

  const ageLabel = (ts) => {
    if (!ts) return 'never';
    const ageSec = Math.max(0, Math.floor((now - new Date(ts).getTime()) / 1000));
    if (ageSec < 2) return 'now';
    if (ageSec < 60) return `${ageSec}s ago`;
    const min = Math.floor(ageSec / 60);
    if (min < 60) return `${min}m ago`;
    const hr = Math.floor(min / 60);
    return `${hr}h ago`;
  };

  const renderFlowCard = (link, info) => {
      const [from, to] = link.split('->');
      const isActive = isFlowLinkActive(info, now);
      const lastAtText = fmtTs(info.lastAt);
      const ageText = ageLabel(info.lastAt);
      return `
        <div class="flow-link ${isActive ? 'active' : 'idle'}">
          <div class="flow-route-row">
            <span class="flow-endpoint flow-from"><span class="flow-icon">${iconForAgent(from)}</span>${from}</span>
            <span class="flow-direction">→</span>
            <span class="flow-endpoint flow-to"><span class="flow-icon">${iconForAgent(to)}</span>${to}</span>
            <span class="flow-status ${isActive ? 'live' : 'quiet'}">${isActive ? 'live' : 'idle'}</span>
          </div>
          <div class="flow-meta-row">
            <span class="flow-meta-chip">msg ${info.count}</span>
            <span class="flow-meta-chip">type ${info.lastType}</span>
            <span class="flow-meta-chip">at ${lastAtText}</span>
            <span class="flow-meta-chip ${isActive ? 'chip-live' : 'chip-idle'}">${ageText}</span>
          </div>
        </div>
      `;
  };

  const groups = [
    {
      title: '1) Bin alerts to control center',
      links: ['smart_bin1->control_center', 'smart_bin2->control_center', 'smart_bin3->control_center'],
    },
    {
      title: '2) Dispatch from control center to trucks',
      links: ['control_center->truck1', 'control_center->truck2', 'control_center->truck3'],
    },
    {
      title: '3) Truck responses and collection',
      links: [
        'truck1->smart_bin1', 'truck1->smart_bin2', 'truck1->smart_bin3',
        'truck2->smart_bin1', 'truck2->smart_bin2', 'truck2->smart_bin3',
        'truck3->smart_bin1', 'truck3->smart_bin2', 'truck3->smart_bin3',
      ],
    },
    {
      title: '4) Control center logging',
      links: ['control_center->logger'],
    },
  ];

  const allLinks = groups.flatMap((group) => group.links);
  const totalActive = allLinks.filter((link) => isFlowLinkActive(flowState[link] || { count: 0, lastAt: null, lastType: '-' }, now)).length;
  const totalMessages = allLinks.reduce((acc, link) => acc + (flowState[link]?.count || 0), 0);

  flowLinks.innerHTML = `
    <div class="flow-summary">
      <span class="flow-summary-chip">links ${allLinks.length}</span>
      <span class="flow-summary-chip flow-summary-live">active ${totalActive}</span>
      <span class="flow-summary-chip">messages ${totalMessages}</span>
    </div>
    ${groups
    .map((group) => {
      const activeInGroup = group.links.filter((link) => isFlowLinkActive(flowState[link] || { count: 0, lastAt: null, lastType: '-' }, now)).length;
      const sortedLinks = [...group.links].sort((a, b) => {
        const aActive = isFlowLinkActive(flowState[a] || { count: 0, lastAt: null, lastType: '-' }, now) ? 1 : 0;
        const bActive = isFlowLinkActive(flowState[b] || { count: 0, lastAt: null, lastType: '-' }, now) ? 1 : 0;
        if (aActive !== bActive) return bActive - aActive;
        const aTs = flowState[a]?.lastAt ? new Date(flowState[a].lastAt).getTime() : 0;
        const bTs = flowState[b]?.lastAt ? new Date(flowState[b].lastAt).getTime() : 0;
        return bTs - aTs;
      });

      return `
      <div class="flow-group">
        <div class="flow-group-head">
          <div class="flow-group-title">${group.title}</div>
          <div class="flow-group-count">${activeInGroup}/${group.links.length} active</div>
        </div>
        <div class="flow-group-grid">
          ${sortedLinks.map((link) => renderFlowCard(link, flowState[link] || { count: 0, lastAt: null, lastType: '-' })).join('')}
        </div>
      </div>
    `;
    })
    .join('')}
  `;
  renderFlowTopology();
}

function renderFlowDiagnostics() {
  if (diagWaitingCount) diagWaitingCount.textContent = String(flowDiagState.waiting);
  if (diagRefusedCount) diagRefusedCount.textContent = String(flowDiagState.refused);
  if (diagBlockedCount) diagBlockedCount.textContent = String(flowDiagState.blocked);
  if (diagCooldownCount) {
    const cooldownCount = Object.values(boardState.bins)
      .filter((info) => String(info?.state || '').toLowerCase().includes('cooldown')).length;
    diagCooldownCount.textContent = String(cooldownCount);
    const cooldownChip = diagCooldownCount.parentElement;
    if (cooldownChip) cooldownChip.classList.toggle('flow-diag-chip-active', cooldownCount > 0);
  }
  if (diagPendingBins) {
    const bins = Array.from(flowDiagState.pendingBins);
    diagPendingBins.textContent = bins.length ? bins.join(', ') : '-';
  }
  if (diagLastTs) diagLastTs.textContent = fmtTs(flowDiagState.lastTs);
}

function resizeCanvasToDisplay(canvas) {
  if (!canvas) return null;
  const dpr = window.devicePixelRatio || 1;
  const width = Math.max(240, Math.floor(canvas.clientWidth * dpr));
  const height = Math.max(160, Math.floor(canvas.clientHeight * dpr));
  if (canvas.width !== width || canvas.height !== height) {
    canvas.width = width;
    canvas.height = height;
  }
  const ctx = canvas.getContext('2d');
  if (!ctx) return null;
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.scale(dpr, dpr);
  return ctx;
}

function drawLineChart(canvas, values, labels) {
  const ctx = resizeCanvasToDisplay(canvas);
  if (!ctx) return;

  const w = canvas.clientWidth;
  const h = canvas.clientHeight;
  const padL = 34;
  const padR = 10;
  const padT = 12;
  const padB = 28;
  const chartW = w - padL - padR;
  const chartH = h - padT - padB;
  const maxV = Math.max(1, ...values);
  const styles = getComputedStyle(document.documentElement);
  const lineColor = styles.getPropertyValue('--accent').trim();
  const gridColor = styles.getPropertyValue('--line').trim();
  const textColor = styles.getPropertyValue('--muted').trim();

  ctx.clearRect(0, 0, w, h);
  ctx.lineWidth = 1;
  ctx.strokeStyle = gridColor;
  ctx.beginPath();
  ctx.moveTo(padL, padT);
  ctx.lineTo(padL, padT + chartH);
  ctx.lineTo(padL + chartW, padT + chartH);
  ctx.stroke();

  for (let i = 1; i <= 4; i += 1) {
    const y = padT + chartH - (chartH * i) / 4;
    ctx.strokeStyle = gridColor;
    ctx.beginPath();
    ctx.moveTo(padL, y);
    ctx.lineTo(padL + chartW, y);
    ctx.stroke();
    ctx.fillStyle = textColor;
    ctx.font = '10px Inter, sans-serif';
    ctx.fillText(String(Math.round((maxV * i) / 4)), 4, y + 3);
  }

  const stepX = values.length > 1 ? chartW / (values.length - 1) : chartW;
  ctx.strokeStyle = lineColor;
  ctx.lineWidth = 2;
  ctx.beginPath();
  values.forEach((v, i) => {
    const x = padL + i * stepX;
    const y = padT + chartH - (v / maxV) * chartH;
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  });
  ctx.stroke();

  ctx.fillStyle = lineColor;
  values.forEach((v, i) => {
    if (v <= 0) return;
    const x = padL + i * stepX;
    const y = padT + chartH - (v / maxV) * chartH;
    ctx.beginPath();
    ctx.arc(x, y, 2.3, 0, Math.PI * 2);
    ctx.fill();
  });

  ctx.fillStyle = textColor;
  ctx.font = '10px Inter, sans-serif';
  const tickEvery = 5;
  labels.forEach((label, i) => {
    if (i % tickEvery !== 0 && i !== labels.length - 1) return;
    const x = padL + i * stepX;
    ctx.fillText(label, x - 10, h - 8);
  });
}

function drawPieChart(canvas, entries) {
  const ctx = resizeCanvasToDisplay(canvas);
  if (!ctx) return;

  const w = canvas.clientWidth;
  const h = canvas.clientHeight;
  const cx = w / 2;
  const cy = h / 2;
  const radius = Math.min(w, h) * 0.34;
  const innerRadius = radius * 0.52;
  const total = entries.reduce((sum, item) => sum + item.value, 0);
  const styles = getComputedStyle(document.documentElement);
  const colors = [
    styles.getPropertyValue('--accent').trim(),
    styles.getPropertyValue('--ok').trim(),
    styles.getPropertyValue('--warn').trim(),
    styles.getPropertyValue('--muted').trim(),
  ];
  const panelColor = styles.getPropertyValue('--panel').trim();
  const textColor = styles.getPropertyValue('--muted').trim();

  ctx.clearRect(0, 0, w, h);

  if (total <= 0) {
    ctx.fillStyle = textColor;
    ctx.font = '12px Inter, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('No collection data yet', cx, cy);
    return;
  }

  let start = -Math.PI / 2;
  entries.forEach((item, idx) => {
    if (item.value <= 0) return;
    const angle = (item.value / total) * Math.PI * 2;
    const end = start + angle;
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.arc(cx, cy, radius, start, end);
    ctx.closePath();
    ctx.fillStyle = colors[idx % colors.length];
    ctx.fill();
    start = end;
  });

  ctx.beginPath();
  ctx.arc(cx, cy, innerRadius, 0, Math.PI * 2);
  ctx.fillStyle = panelColor;
  ctx.fill();

  ctx.textAlign = 'center';
  ctx.fillStyle = textColor;
  ctx.font = '11px Inter, sans-serif';
  ctx.fillText('Collections', cx, cy - 4);
  ctx.font = 'bold 13px Inter, sans-serif';
  ctx.fillText(String(total), cx, cy + 14);
}

function drawBarChart(canvas, entries, opts = {}) {
  const ctx = resizeCanvasToDisplay(canvas);
  if (!ctx) return;
  const w = canvas.clientWidth;
  const h = canvas.clientHeight;
  const padL = 44;
  const padR = 10;
  const padT = 12;
  const padB = 40;
  const chartW = w - padL - padR;
  const chartH = h - padT - padB;
  const maxV = Math.max(1, ...entries.map((e) => e.value || 0));
  const styles = getComputedStyle(document.documentElement);
  const barColor = opts.barColor || styles.getPropertyValue('--accent').trim();
  const gridColor = styles.getPropertyValue('--line').trim();
  const textColor = styles.getPropertyValue('--muted').trim();
  const valueColor = styles.getPropertyValue('--text').trim();
  const suffix = opts.suffix || '';
  const xAxisLabel = opts.xAxisLabel || '';
  const yAxisLabel = opts.yAxisLabel || '';
  const yTickCount = Number.isFinite(opts.yTickCount) ? Math.max(2, opts.yTickCount) : 4;

  ctx.clearRect(0, 0, w, h);

  if (!entries.length || entries.every((e) => !e.value)) {
    ctx.fillStyle = textColor;
    ctx.font = '12px Inter, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('No data yet', w / 2, h / 2);
    return;
  }

  ctx.strokeStyle = gridColor;
  ctx.beginPath();
  ctx.moveTo(padL, padT);
  ctx.lineTo(padL, padT + chartH);
  ctx.lineTo(padL + chartW, padT + chartH);
  ctx.stroke();

  for (let i = 1; i <= yTickCount; i += 1) {
    const ratio = i / yTickCount;
    const y = padT + chartH - ratio * chartH;
    const tickVal = Math.round(ratio * maxV);

    ctx.strokeStyle = gridColor;
    ctx.beginPath();
    ctx.moveTo(padL, y);
    ctx.lineTo(padL + chartW, y);
    ctx.stroke();

    ctx.fillStyle = textColor;
    ctx.font = '10px Inter, sans-serif';
    ctx.textAlign = 'right';
    ctx.fillText(`${tickVal}${suffix}`, padL - 5, y + 3);
  }

  const n = entries.length;
  const slotW = chartW / Math.max(1, n);
  const barW = Math.max(12, Math.min(34, slotW * 0.55));

  entries.forEach((item, idx) => {
    const value = Math.max(0, item.value || 0);
    const barH = (value / maxV) * chartH;
    const x = padL + idx * slotW + (slotW - barW) / 2;
    const y = padT + chartH - barH;

    ctx.fillStyle = item.color || barColor;
    ctx.fillRect(x, y, barW, barH);

    ctx.fillStyle = valueColor;
    ctx.font = '10px Inter, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(`${Math.round(value)}${suffix}`, x + barW / 2, y - 4);

    ctx.fillStyle = textColor;
    ctx.font = '10px Inter, sans-serif';
    ctx.fillText(item.label, x + barW / 2, h - 20);
  });

  if (xAxisLabel) {
    ctx.fillStyle = textColor;
    ctx.font = '10px Inter, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(xAxisLabel, padL + chartW / 2, h - 6);
  }

  if (yAxisLabel) {
    ctx.save();
    ctx.translate(12, padT + chartH / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.fillStyle = textColor;
    ctx.font = '10px Inter, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(yAxisLabel, 0, 0);
    ctx.restore();
  }
}

function percentile(values, p) {
  if (!values.length) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
  return sorted[idx];
}

function fmtSecs(ms) {
  if (!Number.isFinite(ms) || ms < 0) return '-';
  return `${(ms / 1000).toFixed(1)}s`;
}

function renderCollectionReports() {
  if (!collectionLineChart || !collectionPieChart || !collectionPieLegend) return;

  const completed = events
    .filter((evt) => evt.type === 'completed')
    .map((evt) => ({
      tsMs: Date.parse(evt.ts || ''),
      truck: evt.data?.truck || 'unknown',
    }))
    .filter((item) => Number.isFinite(item.tsMs));

  const nowMs = Date.now();
  const windowMin = 30;
  const bucketMs = 60 * 1000;
  const bucketCount = windowMin;
  const startMs = nowMs - bucketCount * bucketMs;
  const buckets = Array(bucketCount).fill(0);

  completed.forEach((item) => {
    if (item.tsMs < startMs || item.tsMs > nowMs) return;
    const idx = Math.min(bucketCount - 1, Math.max(0, Math.floor((item.tsMs - startMs) / bucketMs)));
    buckets[idx] += 1;
  });

  const labels = Array.from({ length: bucketCount }, (_, i) => {
    const d = new Date(startMs + i * bucketMs);
    return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  });

  const truckCounts = {};
  completed.forEach((item) => {
    truckCounts[item.truck] = (truckCounts[item.truck] || 0) + 1;
  });

  const pieEntries = Object.entries(truckCounts)
    .map(([label, value]) => ({ label, value }))
    .sort((a, b) => b.value - a.value);

  drawLineChart(collectionLineChart, buckets, labels);
  drawPieChart(collectionPieChart, pieEntries);

  const totalCompleted = completed.length;
  const completedWindow = buckets.reduce((sum, v) => sum + v, 0);
  if (lineTotal) lineTotal.textContent = `${totalCompleted} total`;
  if (pieWindow) pieWindow.textContent = `${completedWindow} in last 30 min`;

  const styles = getComputedStyle(document.documentElement);
  const legendColors = [
    styles.getPropertyValue('--accent').trim(),
    styles.getPropertyValue('--ok').trim(),
    styles.getPropertyValue('--warn').trim(),
    styles.getPropertyValue('--muted').trim(),
  ];
  collectionPieLegend.innerHTML = pieEntries.length
    ? pieEntries
      .map((entry, idx) => {
        const pct = totalCompleted > 0 ? Math.round((entry.value / totalCompleted) * 100) : 0;
        return `<span class="pie-item"><span class="pie-swatch" style="background:${legendColors[idx % legendColors.length]}"></span>${entry.label}: ${entry.value} (${pct}%)</span>`;
      })
      .join('')
    : '<span class="pie-item">No completed collections yet</span>';

  const relevant = events
    .filter((evt) => ['full_received', 'requesting', 'assigned', 'completed', 'reset', 'truck_state', 'working', 'ready'].includes(evt.type))
    .map((evt) => ({ evt, tsMs: Date.parse(evt.ts || '') }))
    .filter((x) => Number.isFinite(x.tsMs))
    .sort((a, b) => a.tsMs - b.tsMs);

  const stage = {
    fullToDispatch: [],
    dispatchToAssign: [],
    assignToComplete: [],
    fullToComplete: [],
    completeToReset: [],
  };

  const perBin = {};
  relevant.forEach(({ evt, tsMs }) => {
    const bin = evt.data?.bin;
    if (!bin) return;
    perBin[bin] = perBin[bin] || {};
    const row = perBin[bin];

    if (evt.type === 'full_received') {
      row.fullAt = tsMs;
      row.requestAt = null;
      row.assignedAt = null;
      row.completedAt = null;
    } else if (evt.type === 'requesting' && row.fullAt) {
      row.requestAt = tsMs;
      stage.fullToDispatch.push(tsMs - row.fullAt);
    } else if (evt.type === 'assigned' && row.requestAt) {
      row.assignedAt = tsMs;
      stage.dispatchToAssign.push(tsMs - row.requestAt);
    } else if (evt.type === 'completed') {
      row.completedAt = tsMs;
      if (row.assignedAt) stage.assignToComplete.push(tsMs - row.assignedAt);
      if (row.fullAt) stage.fullToComplete.push(tsMs - row.fullAt);
    } else if (evt.type === 'reset' && row.completedAt) {
      stage.completeToReset.push(tsMs - row.completedAt);
    }
  });

  if (slaWindow) slaWindow.textContent = 'last 30 min';
  if (slaMetrics) {
    const items = [
      ['Full → Dispatch', stage.fullToDispatch],
      ['Dispatch → Assign', stage.dispatchToAssign],
      ['Assign → Complete', stage.assignToComplete],
      ['Full → Complete', stage.fullToComplete],
      ['Complete → Reset', stage.completeToReset],
    ];
    slaMetrics.innerHTML = items
      .map(([name, arr]) => {
        const vals = arr.filter((ms) => ms >= 0 && ms <= 60 * 60 * 1000);
        const avg = vals.length ? vals.reduce((a, b) => a + b, 0) / vals.length : null;
        const p95 = percentile(vals, 95);
        return `<div class="metric-row"><span class="metric-name">${name}</span><span class="metric-value">avg ${fmtSecs(avg)} / p95 ${fmtSecs(p95)}</span><span class="metric-count">n=${vals.length}</span></div>`;
      })
      .join('');

    const slaThresholds = {
      'Full → Dispatch': { good: 25, warn: 50 },
      'Dispatch → Assign': { good: 20, warn: 40 },
      'Assign → Complete': { good: 45, warn: 90 },
      'Full → Complete': { good: 80, warn: 150 },
      'Complete → Reset': { good: 20, warn: 40 },
    };
    const okColor = styles.getPropertyValue('--ok').trim();
    const midColor = styles.getPropertyValue('--accent').trim();
    const warnColor = styles.getPropertyValue('--warn').trim();

    const slaBars = items.map(([name, arr]) => {
      const vals = arr.filter((ms) => ms >= 0 && ms <= 60 * 60 * 1000);
      const avg = vals.length ? vals.reduce((a, b) => a + b, 0) / vals.length : 0;
      const avgSec = avg / 1000;
      const th = slaThresholds[name] || { good: 30, warn: 60 };
      const color = avgSec <= th.good ? okColor : (avgSec <= th.warn ? midColor : warnColor);
      const short = name
        .replace('Full → Dispatch', 'F→D')
        .replace('Dispatch → Assign', 'D→A')
        .replace('Assign → Complete', 'A→C')
        .replace('Full → Complete', 'F→C')
        .replace('Complete → Reset', 'C→R');
      return { label: short, value: avgSec, color };
    });
    if (slaStageChart) {
      drawBarChart(slaStageChart, slaBars, {
        suffix: 's',
        xAxisLabel: 'Stages',
        yAxisLabel: 'Avg Time (s)',
      });
    }

    if (slaLegend) {
      slaLegend.innerHTML = `
        <span class="pie-item"><span class="pie-swatch" style="background:${okColor}"></span>good ≤ target</span>
        <span class="pie-item"><span class="pie-swatch" style="background:${midColor}"></span>attention ≤ warning</span>
        <span class="pie-item"><span class="pie-swatch" style="background:${warnColor}"></span>slow &gt; warning</span>
      `;
    }
  }

  const trucks = ['truck1', 'truck2', 'truck3'];
  const truckState = Object.fromEntries(
    trucks.map((truck) => [truck, { lastState: 'available', lastTs: startMs, busyMs: 0 }])
  );

  const truckEvents = relevant
    .map(({ evt, tsMs }) => {
      let truck = evt.data?.truck;
      let state = null;
      if (evt.type === 'truck_state' && truck) {
        state = String(evt.data?.state || '').toLowerCase().startsWith('busy') ? 'busy' : 'available';
      } else if (evt.type === 'working' && truck) {
        state = 'busy';
      } else if (evt.type === 'ready' && truck) {
        state = 'available';
      }
      if (!truck || !state || !truckState[truck]) return null;
      return { truck, state, tsMs };
    })
    .filter(Boolean);

  truckEvents.forEach(({ truck, state, tsMs }) => {
    if (tsMs < startMs || tsMs > nowMs) return;
    const info = truckState[truck];
    if (info.lastState === 'busy') info.busyMs += Math.max(0, tsMs - info.lastTs);
    info.lastState = state;
    info.lastTs = tsMs;
  });

  trucks.forEach((truck) => {
    const info = truckState[truck];
    if (info.lastState === 'busy') info.busyMs += Math.max(0, nowMs - info.lastTs);
  });

  const denom = Math.max(1, nowMs - startMs);
  if (utilWindow) utilWindow.textContent = 'last 30 min';
  if (utilMetrics) {
    utilMetrics.innerHTML = trucks
      .map((truck) => {
        const pct = Math.max(0, Math.min(100, Math.round((truckState[truck].busyMs / denom) * 100)));
        return `<div class="util-row"><span class="metric-name">${truck}</span><span class="util-track"><span class="util-fill" style="width:${pct}%;"></span></span><span class="metric-value">${pct}% busy</span></div>`;
      })
      .join('');

    const okColor = styles.getPropertyValue('--ok').trim();
    const midColor = styles.getPropertyValue('--accent').trim();
    const warnColor = styles.getPropertyValue('--warn').trim();
    const utilBars = trucks.map((truck) => {
      const pct = Math.max(0, Math.min(100, Math.round((truckState[truck].busyMs / denom) * 100)));
      const color = pct < 25 ? warnColor : (pct <= 85 ? okColor : midColor);
      return {
        label: truck.replace('truck', 't'),
        value: pct,
        color,
      };
    });
    if (utilBarChart) {
      drawBarChart(utilBarChart, utilBars, {
        suffix: '%',
        xAxisLabel: 'Trucks',
        yAxisLabel: 'Busy (%)',
      });
    }

    if (utilLegend) {
      utilLegend.innerHTML = `
        <span class="pie-item"><span class="pie-swatch" style="background:${warnColor}"></span>underutilized &lt; 25%</span>
        <span class="pie-item"><span class="pie-swatch" style="background:${okColor}"></span>normal 25–85%</span>
        <span class="pie-item"><span class="pie-swatch" style="background:${midColor}"></span>high &gt; 85%</span>
      `;
    }
  }
}

function updateBoardFromEvent(evt) {
  const ts = evt.ts || new Date().toISOString();
  const type = evt.type || 'unknown';
  const data = evt.data || {};

  const setStateIfChanged = (target, stateText) => {
    if (!target) return;
    if (String(target.state) === String(stateText)) return;
    target.state = stateText;
    target.updatedAt = ts;
  };

  if (['full_received', 'requesting', 'assigned', 'refused', 'completed', 'waiting', 'blocked_not_full'].includes(type)) {
    setStateIfChanged(boardState.controlCenter, type);
  }

  if ((evt.source && String(evt.source).startsWith('tmux:')) || evt.source === 'logger-pane' || evt.source === 'mas-control-api') {
    setStateIfChanged(boardState.logger, 'active');
  }

  const bin = data.bin;
  const truck = data.truck;

  if (bin && boardState.bins[bin]) {
    if (type === 'bin_level') {
      const level = Number(data.level ?? 0);
      if (level === 0 && String(boardState.bins[bin].state || '').includes('cooldown')) {
        setStateIfChanged(boardState.bins[bin], 'cooldown(0%)');
      } else {
        setStateIfChanged(boardState.bins[bin], `${data.level ?? '?'}%`);
      }
    }
    else if (type === 'full_received') setStateIfChanged(boardState.bins[bin], 'full');
    else if (type === 'requesting') setStateIfChanged(boardState.bins[bin], 'dispatching');
    else if (type === 'assigned') setStateIfChanged(boardState.bins[bin], `assigned(${truck || '-'})`);
    else if (type === 'completed') setStateIfChanged(boardState.bins[bin], 'collected');
    else if (type === 'reset') setStateIfChanged(boardState.bins[bin], 'cooldown(0%)');
    else if (type === 'working') setStateIfChanged(boardState.bins[bin], `servicing(${truck || '-'})`);
  }

  if (truck && boardState.trucks[truck]) {
    if (type === 'requesting') setStateIfChanged(boardState.trucks[truck], `requested(${bin || '-'})`);
    else if (type === 'assigned') setStateIfChanged(boardState.trucks[truck], `assigned(${bin || '-'})`);
    else if (type === 'working') setStateIfChanged(boardState.trucks[truck], `working(${bin || '-'})`);
    else if (type === 'refused') setStateIfChanged(boardState.trucks[truck], `refused(${bin || '-'})`);
    else if (type === 'completed') setStateIfChanged(boardState.trucks[truck], `completed(${bin || '-'})`);
    else if (type === 'ready') setStateIfChanged(boardState.trucks[truck], 'ready');
    else if (type === 'truck_state') setStateIfChanged(boardState.trucks[truck], data.state || 'ready');
  }

  if (type === 'waiting') {
    flowDiagState.waiting += 1;
    if (bin) flowDiagState.pendingBins.add(bin);
    flowDiagState.lastTs = ts;
  } else if (type === 'refused') {
    flowDiagState.refused += 1;
    flowDiagState.lastTs = ts;
  } else if (type === 'blocked_not_full') {
    flowDiagState.blocked += 1;
    if (bin) flowDiagState.pendingBins.add(bin);
    flowDiagState.lastTs = ts;
  } else if (['assigned', 'completed', 'reset'].includes(type) && bin) {
    flowDiagState.pendingBins.delete(bin);
    flowDiagState.lastTs = ts;
  }

  renderStatusBoard();
  inferFlowLinks(evt);
  renderFlowLinks();
  renderFlowDiagnostics();
  renderCollectionReports();
}

function normalizeEvent(raw) {
  if (raw && typeof raw === 'object') return raw;
  return {
    type: 'raw',
    ts: new Date().toISOString(),
    source: 'ws',
    data: { raw: String(raw) },
  };
}

function deriveEventFromText(text) {
  if (!text || typeof text !== 'string') return null;

  let m = text.match(/Bin\s+(\w+)\s*\|\s*level:\s*(\d+)%/i);
  if (m) return { type: 'bin_level', data: { bin: m[1].trim(), level: Number(m[2]) } };

  m = text.match(/Bin\s+(\w+)\s*\|\s*alert:\s*full/i);
  if (m) return { type: 'full_received', data: { bin: m[1].trim() } };

  m = text.match(/full_received\(([^)]+)\)/);
  if (m) return { type: 'full_received', data: { bin: m[1].trim() } };

  m = text.match(/requesting\(([^,]+),\s*([^,]+),\s*([^)]+)\)/);
  if (m) return { type: 'requesting', data: { truck: m[1].trim(), bin: m[2].trim(), mode: m[3].trim() } };

  m = text.match(/assigned\(([^,]+),\s*([^)]+)\)/);
  if (m) return { type: 'assigned', data: { truck: m[1].trim(), bin: m[2].trim() } };

  m = text.match(/refused\(([^,]+),\s*([^)]+)\)/);
  if (m) return { type: 'refused', data: { truck: m[1].trim(), bin: m[2].trim() } };

  m = text.match(/completed\(([^,]+),\s*([^)]+)\)/);
  if (m) return { type: 'completed', data: { truck: m[1].trim(), bin: m[2].trim() } };

  m = text.match(/working\(([^,]+),\s*([^)]+)\)/);
  if (m) return { type: 'working', data: { truck: m[1].trim(), bin: m[2].trim() } };

  m = text.match(/ready\(([^)]+)\)/);
  if (m) return { type: 'ready', data: { truck: m[1].trim() } };

  m = text.match(/reset\(([^)]+)\)/);
  if (m) return { type: 'reset', data: { bin: m[1].trim() } };

  m = text.match(/Control center\s*\|\s*alert:\s*full received from\s*(\w+)/i);
  if (m) return { type: 'full_received', data: { bin: m[1].trim() } };

  m = text.match(/Control center\s*\|\s*dispatch:\s*truck=(\w+),\s*bin=(\w+)/i);
  if (m) return { type: 'requesting', data: { truck: m[1].trim(), bin: m[2].trim(), mode: 'normal' } };

  m = text.match(/Control center\s*\|\s*assigned:\s*truck=(\w+),\s*bin=(\w+)/i);
  if (m) return { type: 'assigned', data: { truck: m[1].trim(), bin: m[2].trim() } };

  m = text.match(/Control center\s*\|\s*retry:\s*truck=(\w+) refused,\s*bin=(\w+)/i);
  if (m) return { type: 'refused', data: { truck: m[1].trim(), bin: m[2].trim() } };

  m = text.match(/Control center\s*\|\s*waiting:\s*bin=(\w+) queued after refusal/i);
  if (m) return { type: 'waiting', data: { bin: m[1].trim() } };

  m = text.match(/blocked_not_full\(([^)]+)\)/i);
  if (m) return { type: 'blocked_not_full', data: { bin: m[1].trim() } };

  m = text.match(/Control center\s*\|\s*done:\s*truck=(\w+) collected bin=(\w+)/i);
  if (m) return { type: 'completed', data: { truck: m[1].trim(), bin: m[2].trim() } };

  m = text.match(/Truck\s+(\w+)\s*\|\s*decision:\s*accept\s+(\w+)/i);
  if (m) return { type: 'working', data: { truck: m[1].trim(), bin: m[2].trim() } };

  m = text.match(/Truck\s+(\w+)\s*\|\s*decision:\s*refuse\s+(\w+)/i);
  if (m) return { type: 'refused', data: { truck: m[1].trim(), bin: m[2].trim() } };

  m = text.match(/Truck\s+(\w+)\s*\|\s*request:\s*collect\s+(\w+)/i);
  if (m) return { type: 'requesting', data: { truck: m[1].trim(), bin: m[2].trim(), mode: 'normal' } };

  m = text.match(/Truck\s+(\w+)\s*\|\s*state:\s*(busy|avai[a-z]*)/i);
  if (m) {
    const rawState = m[2].trim().toLowerCase();
    const state = rawState.startsWith('avai') ? 'available' : rawState;
    return { type: 'truck_state', data: { truck: m[1].trim(), state } };
  }

  m = text.match(/Bin\s+(\w+)\s*\|\s*reset:/i);
  if (m) return { type: 'reset', data: { bin: m[1].trim() } };

  return null;
}

function enrichEvent(eventObj) {
  const evt = { ...eventObj, data: { ...(eventObj.data || {}) } };
  if (KNOWN_EVENT_TYPES.has(evt.type)) return evt;

  const candidates = [evt.data?.raw, evt.data?.line, evt.raw].filter(Boolean);
  for (const text of candidates) {
    const derived = deriveEventFromText(String(text));
    if (derived) {
      evt.type = derived.type;
      evt.data = { ...evt.data, ...derived.data };
      break;
    }
  }
  return evt;
}

function shouldDropDuplicateEvent(evt) {
  const type = evt?.type || 'unknown';
  const data = evt?.data || {};
  const key = [type, data.bin || '-', data.truck || '-', data.level ?? '-', data.state || '-', data.mode || '-'].join('|');
  const now = Date.now();
  const last = recentUiEvents.get(key);
  if (last && now - last < UI_EVENT_DEDUP_MS) return true;
  recentUiEvents.set(key, now);
  if (recentUiEvents.size > 400) {
    for (const [k, t] of recentUiEvents.entries()) {
      if (now - t > UI_EVENT_DEDUP_MS * 4) recentUiEvents.delete(k);
    }
  }
  return false;
}

function formatData(data) {
  if (!data) return '-';
  if (typeof data === 'string') return data;
  return Object.entries(data)
    .map(([k, v]) => `${k}=${v}`)
    .join(', ');
}

function passesFilters(evt) {
  const selectedType = typeFilter ? typeFilter.value : 'all';
  const typeOk = selectedType === 'all' || evt.type === selectedType;
  const agentNeedle = (agentFilter?.value || '').trim().toLowerCase();
  if (!agentNeedle) return typeOk;
  const blob = `${evt.source ?? ''} ${JSON.stringify(evt.data ?? {})}`.toLowerCase();
  return typeOk && blob.includes(agentNeedle);
}

function renderEvents() {
  if (!eventCards || !totalCount || !visibleCount) return;
  eventCards.innerHTML = '';
  const filtered = events.filter(passesFilters);
  totalCount.textContent = String(events.length);
  visibleCount.textContent = String(filtered.length);

  if (filtered.length === 0) {
    const empty = document.createElement('div');
    empty.className = 'event-empty';
    empty.textContent = 'No events matching current filters.';
    eventCards.appendChild(empty);
    renderPresentationView();
    return;
  }

  filtered.slice(0, 200).forEach((evt) => {
    const card = document.createElement('div');
    card.className = 'event-card';
    card.innerHTML = `
      <div class="event-head">
        <span class="event-type">${evt.type ?? 'unknown'}</span>
        <span class="event-ts">${evt.ts ?? '-'}</span>
      </div>
      <div class="event-meta">source: ${evt.source ?? '-'}</div>
      <div class="event-data">${formatData(evt.data)}</div>
    `;
    eventCards.appendChild(card);
  });

  renderPresentationView();
}

function setWsBadge(state) {
  if (wsState) wsState.textContent = state;
  renderPresentationView();
}

function scheduleWsReconnect() {
  if (!wsShouldReconnect || wsReconnectTimer) return;
  const delay = Math.min(WS_RECONNECT_BASE_MS * (2 ** wsReconnectAttempts), WS_RECONNECT_MAX_MS);
  wsReconnectAttempts += 1;
  setWsBadge(`reconnecting in ${Math.ceil(delay / 1000)}s`);
  wsReconnectTimer = setTimeout(() => {
    wsReconnectTimer = null;
    connectWs();
  }, delay);
}

function downloadTextFile(filename, content, mimeType) {
  const blob = new Blob([content], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

function exportEventsJson() {
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const payload = JSON.stringify(events, null, 2);
  downloadTextFile(`mas-events-${stamp}.json`, payload, 'application/json');
}

function exportFilteredEventsJson() {
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filtered = events.filter(passesFilters);
  const payload = JSON.stringify(filtered, null, 2);
  downloadTextFile(`mas-events-filtered-${stamp}.json`, payload, 'application/json');
}

function toCsvValue(v) {
  const s = typeof v === 'string' ? v : JSON.stringify(v);
  return `"${String(s).replaceAll('"', '""')}"`;
}

function exportEventsCsv() {
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const header = ['id', 'ts', 'type', 'source', 'severity', 'data'].join(',');
  const lines = events.map((evt) => [
    toCsvValue(evt.id ?? ''),
    toCsvValue(evt.ts ?? ''),
    toCsvValue(evt.type ?? ''),
    toCsvValue(evt.source ?? ''),
    toCsvValue(evt.severity ?? ''),
    toCsvValue(evt.data ?? ''),
  ].join(','));
  const csv = [header, ...lines].join('\n');
  downloadTextFile(`mas-events-${stamp}.csv`, csv, 'text/csv;charset=utf-8');
}

function exportFilteredEventsCsv() {
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filtered = events.filter(passesFilters);
  const header = ['id', 'ts', 'type', 'source', 'severity', 'data'].join(',');
  const lines = filtered.map((evt) => [
    toCsvValue(evt.id ?? ''),
    toCsvValue(evt.ts ?? ''),
    toCsvValue(evt.type ?? ''),
    toCsvValue(evt.source ?? ''),
    toCsvValue(evt.severity ?? ''),
    toCsvValue(evt.data ?? ''),
  ].join(','));
  const csv = [header, ...lines].join('\n');
  downloadTextFile(`mas-events-filtered-${stamp}.csv`, csv, 'text/csv;charset=utf-8');
}

async function fetchStatus() {
  if (!svcName || !svcState || !svcSession || !svcTs) return;
  try {
    const res = await fetch(`${readBase()}/api/v1/system/status`);
    const data = await res.json();
    svcName.textContent = data.service ?? '-';
    svcState.textContent = data.state ?? '-';
    svcSession.textContent = data.session ?? '-';
    svcTs.textContent = data.timestamp ?? '-';
    renderPresentationView();
  } catch {
    svcName.textContent = 'unreachable';
    svcState.textContent = 'failed';
    svcSession.textContent = '-';
    svcTs.textContent = '-';
    renderPresentationView();
  }
}

async function bootstrapOperations() {
  if (!opResult) return;
  await fetchStatus();

  const alreadyHasResult = opResult.textContent && opResult.textContent.trim() !== 'No operation executed yet.';
  if (alreadyHasResult) return;

  if ((svcState.textContent || '').trim() === 'running') {
    opResult.textContent = 'System already running (started outside dashboard). Use Restart or Healthcheck for explicit operation logs.';
    return;
  }

  await runAction('start');
}

async function runAction(action) {
  if (opResult) opResult.textContent = `Executing ${action}...`;
  document.querySelectorAll('[data-action]').forEach((b) => (b.disabled = true));
  try {
    if (action === 'start' || action === 'restart') {
      resetDashboardState({ resetEpoch: true });
    }
    const res = await fetch(`${readBase()}/api/v1/system/${action}`, { method: 'POST' });
    const data = await res.json();
    if (opResult) opResult.textContent = JSON.stringify(data, null, 2);
    await fetchStatus();
  } catch (err) {
    if (opResult) opResult.textContent = `Action failed: ${String(err)}`;
  } finally {
    document.querySelectorAll('[data-action]').forEach((b) => (b.disabled = false));
  }
}

function connectWs() {
  wsShouldReconnect = true;

  if (wsReconnectTimer) {
    clearTimeout(wsReconnectTimer);
    wsReconnectTimer = null;
  }

  if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) {
    return;
  }

  const wsUrl = readBase().replace(/^http/, 'ws') + '/ws/events';
  ws = new WebSocket(wsUrl);
  setWsBadge('connecting');

  ws.onopen = () => {
    wsReconnectAttempts = 0;
    setWsBadge('connected');

    resetDashboardState({ resetEpoch: true });
    events.unshift(normalizeEvent({
      type: 'info',
      source: 'client',
      ts: new Date().toISOString(),
      data: { raw: `websocket connected: ${wsUrl}` },
    }));
    knownTypes.add('info');
    renderTypeOptions();
    renderEvents();
  };

  ws.onmessage = (evt) => {
    let parsed = evt.data;
    try {
      parsed = JSON.parse(evt.data);
    } catch {
      parsed = { type: 'raw', source: 'ws', ts: new Date().toISOString(), data: { raw: evt.data } };
    }
    const eventObj = enrichEvent(normalizeEvent(parsed));
    const tsMs = Date.parse(eventObj.ts || '');
    if (Number.isFinite(tsMs) && tsMs < dashboardEpochMs) return;
    if (shouldDropDuplicateEvent(eventObj)) return;
    events.unshift(eventObj);
    knownTypes.add(eventObj.type ?? 'unknown');
    updateBoardFromEvent(eventObj);
    renderTypeOptions();
    renderEvents();
  };

  ws.onclose = () => {
    setWsBadge('disconnected');
    boardState.logger.state = 'disconnected';
    boardState.logger.updatedAt = new Date().toISOString();
    renderStatusBoard();
    events.unshift(normalizeEvent({
      type: 'info',
      source: 'client',
      ts: new Date().toISOString(),
      data: { raw: 'websocket closed' },
    }));
    knownTypes.add('info');
    renderTypeOptions();
    renderEvents();
    scheduleWsReconnect();
  };

  ws.onerror = () => {
    setWsBadge('error');
    boardState.logger.state = 'error';
    boardState.logger.updatedAt = new Date().toISOString();
    renderStatusBoard();
    events.unshift(normalizeEvent({
      type: 'error',
      source: 'client',
      ts: new Date().toISOString(),
      data: { raw: 'websocket error' },
    }));
    knownTypes.add('error');
    renderTypeOptions();
    renderEvents();
    scheduleWsReconnect();
  };
}

document.querySelectorAll('[data-action]').forEach((button) => {
  button.addEventListener('click', () => runAction(button.dataset.action));
});

if (connectWsBtn) connectWsBtn.addEventListener('click', connectWs);
if (clearEventsBtn) clearEventsBtn.addEventListener('click', () => resetDashboardState({ resetEpoch: true }));
if (exportJsonBtn) exportJsonBtn.addEventListener('click', exportEventsJson);
if (exportCsvBtn) exportCsvBtn.addEventListener('click', exportEventsCsv);
if (exportFilteredJsonBtn) exportFilteredJsonBtn.addEventListener('click', exportFilteredEventsJson);
if (exportFilteredCsvBtn) exportFilteredCsvBtn.addEventListener('click', exportFilteredEventsCsv);
if (typeFilter) typeFilter.addEventListener('change', renderEvents);
if (agentFilter) agentFilter.addEventListener('input', renderEvents);

setInterval(fetchStatus, 5000);
initApiBase();
initViewMode();
bootstrapOperations();
renderTypeOptions();
renderEvents();
renderStatusBoard();
createFlowTopology();
renderFlowLinks();
renderFlowDiagnostics();
renderCollectionReports();
renderPresentationView();
setInterval(renderFlowLinks, 1000);
window.addEventListener('resize', renderCollectionReports);
connectWs();
