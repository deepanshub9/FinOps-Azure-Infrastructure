const apiBase = '/api/v1';

const form = document.getElementById('workloadForm');
const workloadsBody = document.getElementById('workloadsBody');
const recommendationsList = document.getElementById('recommendationsList');
const insightCards = document.getElementById('insightCards');
const cardTemplate = document.getElementById('cardTemplate');
const refreshBtn = document.getElementById('refreshBtn');
const seedDataBtn = document.getElementById('seedDataBtn');
const workloadCount = document.getElementById('workloadCount');
const statusMessage = document.getElementById('statusMessage');

const currency = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function formatProvider(provider) {
  if (provider === 'gcp') return 'GCP';
  if (provider === 'onprem') return 'On-Prem';
  return provider.charAt(0).toUpperCase() + provider.slice(1);
}

function metricNote(label, insights) {
  switch (label) {
    case 'Total Monthly Cost':
      return `${insights.low_utilization_workloads} workloads need closer review.`;
    case 'Potential Savings':
      return 'Based on the current recommendation set.';
    case 'Low Utilization Workloads':
      return 'Services averaging below 30% combined utilization.';
    case 'Average CPU':
      return 'Helps flag overprovisioned compute.';
    case 'Average Memory':
      return 'Useful when rightsizing memory-heavy apps.';
    case 'Auto-Shutdown Coverage':
      return 'Higher coverage usually means lower off-hours waste.';
    default:
      return '';
  }
}

async function request(url, options = {}) {
  const response = await fetch(url, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });

  if (!response.ok) {
    let detail = 'Request failed';
    try {
      const payload = await response.json();
      detail = payload.detail || detail;
    } catch {
      detail = response.statusText;
    }
    throw new Error(detail);
  }

  if (response.status === 204) return null;
  return response.json();
}

function card(label, value, note) {
  const node = cardTemplate.content.firstElementChild.cloneNode(true);
  node.querySelector('.label').textContent = label;
  node.querySelector('.value').textContent = value;
  node.querySelector('.note').textContent = note;
  return node;
}

function renderWorkloads(workloads) {
  workloadsBody.innerHTML = '';
  workloadCount.textContent = `${workloads.length} workload${workloads.length === 1 ? '' : 's'}`;

  if (workloads.length === 0) {
    workloadsBody.innerHTML = '<tr><td colspan="9"><div class="empty-state">No workloads yet. Use the form above or load the demo data to populate the dashboard.</div></td></tr>';
    return;
  }

  workloads.forEach((item) => {
    const name = escapeHtml(item.name);
    const team = escapeHtml(item.owner_team);
    const provider = formatProvider(item.provider);
    const criticality = escapeHtml(item.criticality);
    const shutdownLabel = item.auto_shutdown_enabled ? 'Enabled' : 'Not enabled';
    const row = document.createElement('tr');
    row.innerHTML = `
      <td>
        <strong class="workload-name">${name}</strong>
        <span class="workload-subline">Managed service</span>
      </td>
      <td>${team}</td>
      <td><span class="provider-pill">${provider}</span></td>
      <td>${currency.format(item.monthly_cost_usd)}</td>
      <td>
        <div class="util-cell">
          <div class="util-head"><span>CPU</span><span>${item.cpu_utilization_pct}%</span></div>
          <div class="meter"><span style="width:${Math.max(0, Math.min(100, item.cpu_utilization_pct))}%"></span></div>
        </div>
      </td>
      <td>
        <div class="util-cell">
          <div class="util-head"><span>Memory</span><span>${item.memory_utilization_pct}%</span></div>
          <div class="meter"><span style="width:${Math.max(0, Math.min(100, item.memory_utilization_pct))}%"></span></div>
        </div>
      </td>
      <td><span class="criticality-pill ${criticality}">${criticality.toUpperCase()}</span></td>
      <td><span class="shutdown-pill ${item.auto_shutdown_enabled ? 'enabled' : 'disabled'}">${shutdownLabel}</span></td>
      <td><button class="delete-btn" data-id="${item.id}">Delete</button></td>
    `;
    workloadsBody.appendChild(row);
  });
}

function renderInsights(insights) {
  insightCards.innerHTML = '';
  const metrics = [
    ['Total Monthly Cost', currency.format(insights.total_monthly_cost_usd)],
    ['Potential Savings', currency.format(insights.estimated_monthly_savings_usd)],
    ['Low Utilization Workloads', String(insights.low_utilization_workloads)],
    ['Average CPU', `${insights.average_cpu_utilization_pct}%`],
    ['Average Memory', `${insights.average_memory_utilization_pct}%`],
    ['Auto-Shutdown Coverage', `${insights.auto_shutdown_coverage_pct}%`],
  ];

  metrics.forEach(([label, value]) => {
    insightCards.appendChild(card(label, value, metricNote(label, insights)));
  });

  recommendationsList.innerHTML = '';
  if (!insights.recommendations.length) {
    recommendationsList.innerHTML = '<li><div class="empty-state">No recommendations yet. Add workloads and the advisor will rank savings opportunities here.</div></li>';
    return;
  }

  insights.recommendations.slice(0, 8).forEach((item) => {
    const li = document.createElement('li');
    li.innerHTML = `
      <span class="recommendation-rank">${recommendationsList.children.length + 1}</span>
      <div class="recommendation-copy">
        <strong>${escapeHtml(item.workload_name)}</strong>
        <p>${escapeHtml(item.recommendation)}</p>
        <span class="badge ${item.priority}">${item.priority.toUpperCase()} PRIORITY</span>
      </div>
      <div class="recommendation-meta">
        <span class="savings">${currency.format(item.estimated_savings_usd)}</span>
        <small>Estimated monthly savings</small>
      </div>
    `;
    recommendationsList.appendChild(li);
  });
}

async function refresh() {
  statusMessage.textContent = 'Refreshing dashboard data...';

  try {
    const [workloads, insights] = await Promise.all([
      request(`${apiBase}/workloads`),
      request(`${apiBase}/insights`),
    ]);
    renderWorkloads(workloads);
    renderInsights(insights);
    statusMessage.textContent = `Last refreshed at ${new Date().toLocaleTimeString()}.`;
  } catch (error) {
    statusMessage.textContent = `Unable to load dashboard data: ${error.message}`;
    throw error;
  }
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  const data = new FormData(form);
  const payload = {
    name: data.get('name'),
    owner_team: data.get('owner_team'),
    provider: data.get('provider'),
    monthly_cost_usd: Number(data.get('monthly_cost_usd')),
    cpu_utilization_pct: Number(data.get('cpu_utilization_pct')),
    memory_utilization_pct: Number(data.get('memory_utilization_pct')),
    criticality: data.get('criticality'),
    auto_shutdown_enabled: data.get('auto_shutdown_enabled') === 'on',
  };

  try {
    await request(`${apiBase}/workloads`, { method: 'POST', body: JSON.stringify(payload) });
    form.reset();
    await refresh();
  } catch (error) {
    alert(error.message);
  }
});

workloadsBody.addEventListener('click', async (event) => {
  const target = event.target;
  if (!target.classList.contains('delete-btn')) return;

  const id = target.getAttribute('data-id');
  if (!confirm('Delete this workload?')) return;

  try {
    await request(`${apiBase}/workloads/${id}`, { method: 'DELETE' });
    await refresh();
  } catch (error) {
    alert(error.message);
  }
});

refreshBtn.addEventListener('click', refresh);

seedDataBtn.addEventListener('click', async () => {
  const demo = [
    {
      name: 'product-catalog-api',
      owner_team: 'commerce',
      provider: 'azure',
      monthly_cost_usd: 1800,
      cpu_utilization_pct: 22,
      memory_utilization_pct: 34,
      criticality: 'medium',
      auto_shutdown_enabled: false,
    },
    {
      name: 'analytics-worker',
      owner_team: 'data',
      provider: 'azure',
      monthly_cost_usd: 2400,
      cpu_utilization_pct: 67,
      memory_utilization_pct: 71,
      criticality: 'high',
      auto_shutdown_enabled: false,
    },
    {
      name: 'internal-dev-portal',
      owner_team: 'platform',
      provider: 'aws',
      monthly_cost_usd: 650,
      cpu_utilization_pct: 18,
      memory_utilization_pct: 29,
      criticality: 'low',
      auto_shutdown_enabled: true,
    },
  ];

  try {
    await Promise.all(demo.map((item) => request(`${apiBase}/workloads`, { method: 'POST', body: JSON.stringify(item) })));
    await refresh();
  } catch (error) {
    alert(error.message);
  }
});

refresh().catch((error) => {
  alert(error.message);
});
