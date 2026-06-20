import { useEffect, useMemo, useState } from 'react';

const TOKEN_STORAGE_KEY = 'depass-admin-token';

function readStoredToken() {
    try {
        return window.localStorage.getItem(TOKEN_STORAGE_KEY) || '';
    } catch {
        return '';
    }
}

function storeToken(token) {
    try {
        if (token) {
            window.localStorage.setItem(TOKEN_STORAGE_KEY, token);
        } else {
            window.localStorage.removeItem(TOKEN_STORAGE_KEY);
        }
    } catch {
        // Ignore storage failures so the dashboard still works in constrained browsers.
    }
}

function formatValue(value) {
    if (value === null || value === undefined) {
        return 'null';
    }

    if (typeof value === 'boolean') {
        return value ? 'Enabled' : 'Disabled';
    }

    if (typeof value === 'object') {
        return JSON.stringify(value, null, 2);
    }

    return String(value);
}

function parseDraftValue(rawValue) {
    const trimmed = rawValue.trim();
    if (trimmed.length === 0) {
        return null;
    }

    try {
        return JSON.parse(trimmed);
    } catch {
        return rawValue;
    }
}

function buildHeaders(token, extraHeaders = {}) {
    return {
        Accept: 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...extraHeaders,
    };
}

async function requestJson(path, token, options = {}) {
    const response = await fetch(path, {
        credentials: 'same-origin',
        method: options.method || 'GET',
        headers: buildHeaders(token, options.body ? { 'Content-Type': 'application/json' } : {}),
        body: options.body ? JSON.stringify(options.body) : undefined,
    });

    const text = await response.text();
    let payload = null;

    if (text) {
        try {
            payload = JSON.parse(text);
        } catch {
            payload = text;
        }
    }

    if (!response.ok) {
        const message = payload?.message || `HTTP ${response.status}`;
        throw new Error(message);
    }

    return payload;
}

function StatCard({ title, value, subtitle }) {
    return (
        <div className="rounded-3xl border border-[#e8e5df] bg-white p-6 shadow-sm shadow-[#00000005] dark:border-[#31302b] dark:bg-[#111111]">
            <p className="text-xs uppercase tracking-[0.24em] text-[#8a8579]">{title}</p>
            <p className="mt-4 text-3xl font-semibold text-[#1b1b18] dark:text-[#f8f4ef]">{value}</p>
            <p className="mt-3 text-sm text-[#6f6b61] dark:text-[#a9a79f]">{subtitle}</p>
        </div>
    );
}

function Section({ title, subtitle, actions, children }) {
    return (
        <section className="overflow-hidden rounded-[2rem] border border-[#e6e2d8] bg-white shadow-sm shadow-[#00000005] dark:border-[#2f2d27] dark:bg-[#121212]">
            <div className="flex flex-col gap-3 border-b border-[#ece9e1] px-6 py-5 dark:border-[#2a2923] lg:flex-row lg:items-start lg:justify-between">
                <div>
                    <h2 className="text-lg font-semibold text-[#1b1b18] dark:text-[#f8f4ef]">{title}</h2>
                    {subtitle ? <p className="mt-1 text-sm text-[#6f6b61] dark:text-[#a9a79f]">{subtitle}</p> : null}
                </div>
                {actions ? <div className="flex flex-wrap gap-2">{actions}</div> : null}
            </div>
            {children}
        </section>
    );
}

function ToggleChip({ label, enabled, onToggle }) {
    return (
        <button
            type="button"
            onClick={onToggle}
            className={`flex items-center justify-between gap-3 rounded-2xl border px-4 py-3 text-left transition ${
                enabled
                    ? 'border-[#f7b2a9] bg-[#fff6f4] text-[#b02a1d] dark:border-[#6a2c25] dark:bg-[#2b140f] dark:text-[#f5c7bf]'
                    : 'border-[#e8e5df] bg-white text-[#1b1b18] dark:border-[#31302b] dark:bg-[#171713] dark:text-[#f8f4ef]'
            }`}
        >
            <span className="font-medium">{label}</span>
            <span className={`rounded-full px-3 py-1 text-xs font-semibold ${enabled ? 'bg-[#b02a1d] text-white' : 'bg-[#d8d3c7] text-[#4b4a45] dark:bg-[#2f2d27] dark:text-[#a9a79f]'}`}>
                {enabled ? 'On' : 'Off'}
            </span>
        </button>
    );
}

function ConfigEditor({ row, value, onValueChange, onSave, onDelete, saving }) {
    return (
        <div className="rounded-3xl border border-[#e8e5df] bg-[#fcfbf8] p-5 dark:border-[#2f2d27] dark:bg-[#171713]">
            <div className="flex flex-col gap-2 lg:flex-row lg:items-start lg:justify-between">
                <div>
                    <p className="text-xs uppercase tracking-[0.24em] text-[#8a8579]">{row.key}</p>
                    <p className="mt-1 text-sm text-[#6f6b61] dark:text-[#a9a79f]">{row.description || 'No description provided.'}</p>
                </div>
                <div className="flex gap-2">
                    <button
                        type="button"
                        onClick={() => onSave(row)}
                        className="rounded-full bg-[#1b1b18] px-4 py-2 text-sm font-semibold text-white transition hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-[#f8f4ef] dark:text-[#1b1b18]"
                        disabled={saving}
                    >
                        {saving ? 'Saving...' : 'Save'}
                    </button>
                    <button
                        type="button"
                        onClick={() => onDelete(row)}
                        className="rounded-full border border-[#f0c2bc] px-4 py-2 text-sm font-semibold text-[#b02a1d] transition hover:bg-[#fff4f2] disabled:cursor-not-allowed disabled:opacity-60 dark:border-[#6a2c25] dark:hover:bg-[#2b140f]"
                        disabled={saving}
                    >
                        Delete
                    </button>
                </div>
            </div>

            <textarea
                value={value}
                onChange={(event) => onValueChange(row.id, event.target.value)}
                spellCheck="false"
                rows={Math.max(4, String(value || '').split('\n').length)}
                className="mt-4 w-full rounded-2xl border border-[#ded9cf] bg-white px-4 py-3 font-mono text-sm text-[#1b1b18] outline-none transition focus:border-[#fa3e2c] dark:border-[#31302b] dark:bg-[#111111] dark:text-[#f8f4ef]"
            />
        </div>
    );
}

export default function App() {
    const [token, setToken] = useState(() => readStoredToken());
    const [loginForm, setLoginForm] = useState({ username: 'admin', password: '' });
    const [dashboard, setDashboard] = useState(null);
    const [events, setEvents] = useState([]);
    const [drafts, setDrafts] = useState({});
    const [newConfig, setNewConfig] = useState({
        key: '',
        description: '',
        value: '{\n  "enabled": true\n}',
    });
    const [loading, setLoading] = useState(Boolean(token));
    const [savingKey, setSavingKey] = useState('');
    const [error, setError] = useState('');
    const [notice, setNotice] = useState('');

    useEffect(() => {
        if (!token) {
            return;
        }

        let active = true;

        async function loadDashboard() {
            setLoading(true);
            setError('');

            try {
                const [dashboardPayload, eventsPayload] = await Promise.all([
                    requestJson('/api/admin/dashboard', token),
                    requestJson('/api/events', token),
                ]);

                if (!active) {
                    return;
                }

                setDashboard(dashboardPayload);
                setEvents(Array.isArray(eventsPayload.data) ? eventsPayload.data : []);

                const nextDrafts = {};
                for (const row of dashboardPayload.configurations || []) {
                    nextDrafts[row.id] = formatValue(row.value);
                }
                setDrafts(nextDrafts);
            } catch (caughtError) {
                if (!active) {
                    return;
                }

                setError(caughtError.message || 'Unable to load the admin console.');
                storeToken('');
                setToken('');
            } finally {
                if (active) {
                    setLoading(false);
                }
            }
        }

        loadDashboard();

        return () => {
            active = false;
        };
    }, [token]);

    const configurations = dashboard?.configurations || [];
    const featureConfigs = useMemo(
        () => configurations.filter((row) => row.key.startsWith('features.')),
        [configurations],
    );
    const serviceConfigs = useMemo(
        () => configurations.filter((row) => row.key.startsWith('services.')),
        [configurations],
    );

    async function handleLogin(event) {
        event.preventDefault();
        setLoading(true);
        setError('');
        setNotice('');

        try {
            const payload = await requestJson('/api/login', null, {
                method: 'POST',
                body: loginForm,
            });

            if (!payload?.token) {
                throw new Error('Login did not return an API token.');
            }

            storeToken(payload.token);
            setToken(payload.token);
            setNotice(`Signed in as ${payload.user?.username || loginForm.username}.`);
        } catch (caughtError) {
            setError(caughtError.message || 'Unable to sign in.');
        } finally {
            setLoading(false);
        }
    }

    async function reload() {
        if (!token) {
            return;
        }

        setLoading(true);
        setError('');

        try {
            const [dashboardPayload, eventsPayload] = await Promise.all([
                requestJson('/api/admin/dashboard', token),
                requestJson('/api/events', token),
            ]);

            setDashboard(dashboardPayload);
            setEvents(Array.isArray(eventsPayload.data) ? eventsPayload.data : []);

            const nextDrafts = {};
            for (const row of dashboardPayload.configurations || []) {
                nextDrafts[row.id] = formatValue(row.value);
            }
            setDrafts(nextDrafts);
            setNotice('Dashboard refreshed.');
        } catch (caughtError) {
            setError(caughtError.message || 'Unable to refresh the admin console.');
        } finally {
            setLoading(false);
        }
    }

    function handleLogout() {
        storeToken('');
        setToken('');
        setDashboard(null);
        setEvents([]);
        setDrafts({});
        setNotice('Signed out.');
    }

    function updateDraft(rowId, value) {
        setDrafts((current) => ({
            ...current,
            [rowId]: value,
        }));
    }

    async function saveConfiguration(row) {
        setSavingKey(row.id);
        setError('');
        setNotice('');

        try {
            const nextValue = parseDraftValue(drafts[row.id] ?? formatValue(row.value));
            const payload = {
                value: nextValue,
                description: row.description || '',
            };

            const response = await requestJson(`/api/configurations/${row.id}`, token, {
                method: 'PATCH',
                body: payload,
            });

            setDashboard((current) => {
                if (!current) {
                    return current;
                }

                return {
                    ...current,
                    configurations: current.configurations.map((item) =>
                        item.id === row.id ? response.configuration : item,
                    ),
                    features: current.features,
                    services: current.services,
                };
            });

            setDrafts((current) => ({
                ...current,
                [row.id]: formatValue(response.configuration.value),
            }));
            setNotice(`Saved ${row.key}.`);
        } catch (caughtError) {
            setError(caughtError.message || `Unable to save ${row.key}.`);
        } finally {
            setSavingKey('');
        }
    }

    async function deleteConfiguration(row) {
        if (!window.confirm(`Delete ${row.key}?`)) {
            return;
        }

        setSavingKey(row.id);
        setError('');
        setNotice('');

        try {
            await requestJson(`/api/configurations/${row.id}`, token, {
                method: 'DELETE',
            });

            await reload();
            setNotice(`Deleted ${row.key}.`);
        } catch (caughtError) {
            setError(caughtError.message || `Unable to delete ${row.key}.`);
        } finally {
            setSavingKey('');
        }
    }

    async function createConfiguration(event) {
        event.preventDefault();
        setSavingKey('new');
        setError('');
        setNotice('');

        try {
            const payload = {
                key: newConfig.key.trim(),
                description: newConfig.description.trim() || null,
                value: parseDraftValue(newConfig.value),
            };

            if (!payload.key) {
                throw new Error('A configuration key is required.');
            }

            await requestJson('/api/configurations', token, {
                method: 'POST',
                body: payload,
            });

            setNewConfig({
                key: '',
                description: '',
                value: '{\n  "enabled": true\n}',
            });
            await reload();
            setNotice(`Created ${payload.key}.`);
        } catch (caughtError) {
            setError(caughtError.message || 'Unable to create configuration.');
        } finally {
            setSavingKey('');
        }
    }

    function toggleSetting(row, flagKey) {
        const currentValue = row.value && typeof row.value === 'object' ? row.value : {};
        const nextValue = {
            ...currentValue,
            [flagKey]: !Boolean(currentValue[flagKey]),
        };

        setDrafts((current) => ({
            ...current,
            [row.id]: JSON.stringify(nextValue, null, 2),
        }));
    }

    if (!token) {
        return (
            <main className="min-h-screen bg-[#F7F5F0] text-[#1b1b18] dark:bg-[#0a0a0a] dark:text-[#F8F4EF]">
                <div className="mx-auto flex min-h-screen max-w-7xl items-center px-6 py-10 lg:px-10">
                    <div className="grid w-full gap-6 lg:grid-cols-[1.1fr_0.9fr]">
                        <div className="rounded-[2rem] border border-[#e6e2d8] bg-white p-8 shadow-sm shadow-[#00000005] dark:border-[#2f2d27] dark:bg-[#121212]">
                            <p className="text-sm uppercase tracking-[0.28em] text-[#9d988b] dark:text-[#b8b5ad]">Admin dashboard</p>
                            <h1 className="mt-3 text-4xl font-semibold text-[#1b1b18] dark:text-[#f8f4ef]">GatePassX operations console</h1>
                            <p className="mt-4 max-w-2xl text-sm leading-7 text-[#6f6b61] dark:text-[#b2afa7]">
                                Sign in with a super-admin account to manage feature flags, release services, and operational settings from the same Laravel backend that powers the app.
                            </p>
                            <div className="mt-8 grid gap-4 sm:grid-cols-3">
                                <StatCard title="Live stats" value="Realtime" subtitle="Connected through the API token you provide." />
                                <StatCard title="Settings" value="Editable" subtitle="Feature flags, services, and configuration rows." />
                                <StatCard title="Scope" value="Admin only" subtitle="Uses the same API permissions as the backend." />
                            </div>
                        </div>
                        <form onSubmit={handleLogin} className="rounded-[2rem] border border-[#e6e2d8] bg-white p-8 shadow-sm shadow-[#00000005] dark:border-[#2f2d27] dark:bg-[#121212]">
                            <h2 className="text-lg font-semibold text-[#1b1b18] dark:text-[#f8f4ef]">Sign in</h2>
                            <p className="mt-1 text-sm text-[#6f6b61] dark:text-[#a9a79f]">Use an existing admin username and password from your seeded Laravel users.</p>
                            <label className="mt-6 block text-sm font-medium text-[#1b1b18] dark:text-[#f8f4ef]">
                                Username
                                <input
                                    value={loginForm.username}
                                    onChange={(event) => setLoginForm((current) => ({ ...current, username: event.target.value }))}
                                    className="mt-2 w-full rounded-2xl border border-[#ded9cf] bg-[#fcfbf8] px-4 py-3 outline-none transition focus:border-[#fa3e2c] dark:border-[#31302b] dark:bg-[#171713] dark:text-[#f8f4ef]"
                                />
                            </label>
                            <label className="mt-4 block text-sm font-medium text-[#1b1b18] dark:text-[#f8f4ef]">
                                Password
                                <input
                                    type="password"
                                    value={loginForm.password}
                                    onChange={(event) => setLoginForm((current) => ({ ...current, password: event.target.value }))}
                                    className="mt-2 w-full rounded-2xl border border-[#ded9cf] bg-[#fcfbf8] px-4 py-3 outline-none transition focus:border-[#fa3e2c] dark:border-[#31302b] dark:bg-[#171713] dark:text-[#f8f4ef]"
                                />
                            </label>
                            <button
                                type="submit"
                                className="mt-6 w-full rounded-full bg-[#1b1b18] px-5 py-3 text-sm font-semibold text-white transition hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-[#f8f4ef] dark:text-[#1b1b18]"
                                disabled={loading}
                            >
                                {loading ? 'Signing in...' : 'Open admin console'}
                            </button>
                            {error ? <p className="mt-4 rounded-2xl border border-[#f0c2bc] bg-[#fff4f2] px-4 py-3 text-sm text-[#b02a1d] dark:border-[#6a2c25] dark:bg-[#2b140f] dark:text-[#f5c7bf]">{error}</p> : null}
                            {notice ? <p className="mt-4 rounded-2xl border border-[#d7e8d8] bg-[#eff8ef] px-4 py-3 text-sm text-[#1e7a49] dark:border-[#294732] dark:bg-[#112219] dark:text-[#b9e3c5]">{notice}</p> : null}
                        </form>
                    </div>
                </div>
            </main>
        );
    }

    return (
        <main className="min-h-screen bg-[#F7F5F0] text-[#1b1b18] dark:bg-[#0a0a0a] dark:text-[#F8F4EF]">
            <div className="mx-auto max-w-7xl px-6 py-8 lg:px-10">
                <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
                    <div>
                        <p className="text-sm uppercase tracking-[0.28em] text-[#9d988b] dark:text-[#b8b5ad]">Admin dashboard</p>
                        <h1 className="mt-3 text-4xl font-semibold text-[#1b1b18] dark:text-[#f8f4ef]">GatePassX operations</h1>
                        <p className="mt-4 max-w-2xl text-sm leading-7 text-[#6f6b61] dark:text-[#b2afa7]">
                            Manage release flags, backend services, and system settings from one place while keeping the admin console tethered to the same API permissions as the mobile app.
                        </p>
                    </div>
                    <div className="flex flex-wrap gap-3">
                        <button
                            type="button"
                            onClick={reload}
                            className="rounded-full border border-[#d6d0c5] bg-white px-5 py-3 text-sm font-semibold text-[#1b1b18] transition hover:bg-[#fcfbf8] dark:border-[#31302b] dark:bg-[#111111] dark:text-[#f8f4ef]"
                            disabled={loading}
                        >
                            Refresh
                        </button>
                        <button
                            type="button"
                            onClick={handleLogout}
                            className="rounded-full bg-[#1b1b18] px-5 py-3 text-sm font-semibold text-white transition hover:opacity-90 dark:bg-[#f8f4ef] dark:text-[#1b1b18]"
                        >
                            Sign out
                        </button>
                    </div>
                </div>

                {error ? (
                    <div className="mt-8 rounded-3xl border border-[#f2d7d5] bg-[#fff4f2] p-6 text-sm text-[#b02a1d] dark:border-[#5f2119] dark:bg-[#2b140f] dark:text-[#f5c7bf]">
                        {error}
                    </div>
                ) : null}

                {notice ? (
                    <div className="mt-8 rounded-3xl border border-[#d7e8d8] bg-[#eff8ef] p-6 text-sm text-[#1e7a49] dark:border-[#294732] dark:bg-[#112219] dark:text-[#b9e3c5]">
                        {notice}
                    </div>
                ) : null}

                <div className="mt-8 grid gap-5 lg:grid-cols-5">
                    <StatCard title="Events" value={dashboard?.stats?.events ?? 0} subtitle="Total event records in system" />
                    <StatCard title="Passes" value={dashboard?.stats?.passes ?? 0} subtitle="Generated passes across events" />
                    <StatCard title="Approved devices" value={dashboard?.stats?.approved_devices ?? 0} subtitle="Active device bindings" />
                    <StatCard title="Pending devices" value={dashboard?.stats?.pending_devices ?? 0} subtitle="Gate scanners waiting approval" />
                    <StatCard title="Templates" value={dashboard?.stats?.templates ?? 0} subtitle="Badge and manifest templates" />
                </div>

                <div className="mt-8 grid gap-8 lg:grid-cols-2">
                    <Section
                        title="Feature settings"
                        subtitle="Edit feature flags that control the mobile app experience."
                        actions={
                            <button
                                type="button"
                                onClick={reload}
                                className="rounded-full border border-[#d6d0c5] px-4 py-2 text-sm font-semibold text-[#1b1b18] dark:border-[#31302b] dark:text-[#f8f4ef]"
                            >
                                Sync
                            </button>
                        }
                    >
                        <div className="grid gap-3 px-6 py-6">
                            {featureConfigs.length > 0 ? (
                                featureConfigs.map((row) => {
                                    const value = row.value && typeof row.value === 'object' ? row.value : {};

                                    return (
                                        <div key={row.id} className="rounded-3xl border border-[#ece9e1] p-4 dark:border-[#2a2923]">
                                            <div className="flex flex-col gap-1 md:flex-row md:items-start md:justify-between">
                                                <div>
                                                    <p className="font-semibold text-[#1b1b18] dark:text-[#f8f4ef]">{row.key}</p>
                                                    <p className="text-sm text-[#6f6b61] dark:text-[#a9a79f]">{row.description || 'No description provided.'}</p>
                                                </div>
                                                <p className="text-xs uppercase tracking-[0.2em] text-[#8a8579] dark:text-[#b8b5ad]">Feature flags</p>
                                            </div>
                                            <div className="mt-4 grid gap-3 sm:grid-cols-2">
                                                {Object.keys(value).length > 0 ? (
                                                    Object.entries(value).map(([flagKey, flagValue]) => (
                                                        <ToggleChip
                                                            key={flagKey}
                                                            label={flagKey}
                                                            enabled={Boolean(flagValue)}
                                                            onToggle={() => toggleSetting(row, flagKey)}
                                                        />
                                                    ))
                                                ) : (
                                                    <p className="text-sm text-[#6f6b61] dark:text-[#a9a79f]">No flags configured yet.</p>
                                                )}
                                            </div>
                                            <div className="mt-4 flex gap-2">
                                                <button
                                                    type="button"
                                                    onClick={() => saveConfiguration(row)}
                                                    className="rounded-full bg-[#1b1b18] px-4 py-2 text-sm font-semibold text-white transition hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-[#f8f4ef] dark:text-[#1b1b18]"
                                                    disabled={savingKey === row.id}
                                                >
                                                    {savingKey === row.id ? 'Saving...' : 'Save feature set'}
                                                </button>
                                                <button
                                                    type="button"
                                                    onClick={() => setDrafts((current) => ({ ...current, [row.id]: JSON.stringify(value, null, 2) }))}
                                                    className="rounded-full border border-[#d6d0c5] px-4 py-2 text-sm font-semibold text-[#1b1b18] dark:border-[#31302b] dark:text-[#f8f4ef]"
                                                >
                                                    Reset draft
                                                </button>
                                            </div>
                                            <textarea
                                                value={drafts[row.id] ?? formatValue(row.value)}
                                                onChange={(event) => updateDraft(row.id, event.target.value)}
                                                spellCheck="false"
                                                rows={5}
                                                className="mt-4 w-full rounded-2xl border border-[#ded9cf] bg-[#fcfbf8] px-4 py-3 font-mono text-sm text-[#1b1b18] outline-none transition focus:border-[#fa3e2c] dark:border-[#31302b] dark:bg-[#111111] dark:text-[#f8f4ef]"
                                            />
                                        </div>
                                    );
                                })
                            ) : (
                                <p className="px-2 py-4 text-sm text-[#6f6b61] dark:text-[#a9a79f]">No feature settings are seeded yet.</p>
                            )}
                        </div>
                    </Section>

                    <Section
                        title="Release services"
                        subtitle="Control the release pipeline toggles that keep workflow builds predictable."
                    >
                        <div className="grid gap-3 px-6 py-6">
                            {serviceConfigs.length > 0 ? (
                                serviceConfigs.map((row) => {
                                    const value = row.value && typeof row.value === 'object' ? row.value : {};

                                    return (
                                        <div key={row.id} className="rounded-3xl border border-[#ece9e1] p-4 dark:border-[#2a2923]">
                                            <div className="flex flex-col gap-1 md:flex-row md:items-start md:justify-between">
                                                <div>
                                                    <p className="font-semibold text-[#1b1b18] dark:text-[#f8f4ef]">{row.key}</p>
                                                    <p className="text-sm text-[#6f6b61] dark:text-[#a9a79f]">{row.description || 'No description provided.'}</p>
                                                </div>
                                                <p className="text-xs uppercase tracking-[0.2em] text-[#8a8579] dark:text-[#b8b5ad]">Services</p>
                                            </div>
                                            <div className="mt-4 grid gap-3 sm:grid-cols-2">
                                                {Object.keys(value).length > 0 ? (
                                                    Object.entries(value).map(([flagKey, flagValue]) => (
                                                        <ToggleChip
                                                            key={flagKey}
                                                            label={flagKey}
                                                            enabled={Boolean(flagValue)}
                                                            onToggle={() => toggleSetting(row, flagKey)}
                                                        />
                                                    ))
                                                ) : (
                                                    <p className="text-sm text-[#6f6b61] dark:text-[#a9a79f]">No service flags configured yet.</p>
                                                )}
                                            </div>
                                            <div className="mt-4 flex gap-2">
                                                <button
                                                    type="button"
                                                    onClick={() => saveConfiguration(row)}
                                                    className="rounded-full bg-[#1b1b18] px-4 py-2 text-sm font-semibold text-white transition hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-[#f8f4ef] dark:text-[#1b1b18]"
                                                    disabled={savingKey === row.id}
                                                >
                                                    {savingKey === row.id ? 'Saving...' : 'Save service set'}
                                                </button>
                                                <button
                                                    type="button"
                                                    onClick={() => setDrafts((current) => ({ ...current, [row.id]: JSON.stringify(value, null, 2) }))}
                                                    className="rounded-full border border-[#d6d0c5] px-4 py-2 text-sm font-semibold text-[#1b1b18] dark:border-[#31302b] dark:text-[#f8f4ef]"
                                                >
                                                    Reset draft
                                                </button>
                                            </div>
                                            <textarea
                                                value={drafts[row.id] ?? formatValue(row.value)}
                                                onChange={(event) => updateDraft(row.id, event.target.value)}
                                                spellCheck="false"
                                                rows={5}
                                                className="mt-4 w-full rounded-2xl border border-[#ded9cf] bg-[#fcfbf8] px-4 py-3 font-mono text-sm text-[#1b1b18] outline-none transition focus:border-[#fa3e2c] dark:border-[#31302b] dark:bg-[#111111] dark:text-[#f8f4ef]"
                                            />
                                        </div>
                                    );
                                })
                            ) : (
                                <p className="px-2 py-4 text-sm text-[#6f6b61] dark:text-[#a9a79f]">No service settings are seeded yet.</p>
                            )}
                        </div>
                    </Section>
                </div>

                <div className="mt-8 grid gap-8 lg:grid-cols-[1.1fr_0.9fr]">
                    <Section
                        title="Configuration manager"
                        subtitle="Create, edit, or delete any system configuration entry."
                    >
                        <div className="grid gap-4 px-6 py-6">
                            <form onSubmit={createConfiguration} className="rounded-3xl border border-[#ece9e1] p-5 dark:border-[#2a2923]">
                                <div className="grid gap-4 md:grid-cols-2">
                                    <label className="text-sm font-medium text-[#1b1b18] dark:text-[#f8f4ef]">
                                        Key
                                        <input
                                            value={newConfig.key}
                                            onChange={(event) => setNewConfig((current) => ({ ...current, key: event.target.value }))}
                                            placeholder="features.mobile_app.push_notifications"
                                            className="mt-2 w-full rounded-2xl border border-[#ded9cf] bg-[#fcfbf8] px-4 py-3 outline-none transition focus:border-[#fa3e2c] dark:border-[#31302b] dark:bg-[#171713] dark:text-[#f8f4ef]"
                                        />
                                    </label>
                                    <label className="text-sm font-medium text-[#1b1b18] dark:text-[#f8f4ef]">
                                        Description
                                        <input
                                            value={newConfig.description}
                                            onChange={(event) => setNewConfig((current) => ({ ...current, description: event.target.value }))}
                                            placeholder="Describe what this setting controls"
                                            className="mt-2 w-full rounded-2xl border border-[#ded9cf] bg-[#fcfbf8] px-4 py-3 outline-none transition focus:border-[#fa3e2c] dark:border-[#31302b] dark:bg-[#171713] dark:text-[#f8f4ef]"
                                        />
                                    </label>
                                </div>
                                <label className="mt-4 block text-sm font-medium text-[#1b1b18] dark:text-[#f8f4ef]">
                                    Value
                                    <textarea
                                        value={newConfig.value}
                                        onChange={(event) => setNewConfig((current) => ({ ...current, value: event.target.value }))}
                                        rows={4}
                                        spellCheck="false"
                                        className="mt-2 w-full rounded-2xl border border-[#ded9cf] bg-[#fcfbf8] px-4 py-3 font-mono text-sm outline-none transition focus:border-[#fa3e2c] dark:border-[#31302b] dark:bg-[#171713] dark:text-[#f8f4ef]"
                                    />
                                </label>
                                <button
                                    type="submit"
                                    className="mt-4 rounded-full bg-[#fa3e2c] px-5 py-3 text-sm font-semibold text-white transition hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-60"
                                    disabled={savingKey === 'new'}
                                >
                                    {savingKey === 'new' ? 'Creating...' : 'Create setting'}
                                </button>
                            </form>

                            <div className="grid gap-4">
                                {configurations.map((row) => (
                                    <ConfigEditor
                                        key={row.id}
                                        row={row}
                                        value={drafts[row.id] ?? formatValue(row.value)}
                                        onValueChange={updateDraft}
                                        onSave={saveConfiguration}
                                        onDelete={deleteConfiguration}
                                        saving={savingKey === row.id}
                                    />
                                ))}
                            </div>
                        </div>
                    </Section>

                    <Section
                        title="Recent events"
                        subtitle="Live event listing from the authenticated API."
                    >
                        <div className="overflow-x-auto px-6 py-6">
                            <table className="min-w-full text-left text-sm leading-6">
                                <thead className="bg-[#f2efe9] text-[#6f6b61] dark:bg-[#161615] dark:text-[#a9a79f]">
                                    <tr>
                                        <th className="px-4 py-3 font-medium uppercase tracking-[0.16em]">Event</th>
                                        <th className="px-4 py-3 font-medium uppercase tracking-[0.16em]">Status</th>
                                        <th className="px-4 py-3 font-medium uppercase tracking-[0.16em]">Date</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {events.length > 0 ? (
                                        events.map((event) => (
                                            <tr key={event.id} className="border-b border-[#ece9e1] last:border-b-0 dark:border-[#2a2923]">
                                                <td className="px-4 py-4 text-[#1b1b18] dark:text-[#f8f4ef]">{event.name ?? 'Unnamed Event'}</td>
                                                <td className="px-4 py-4 text-[#6f6b61] dark:text-[#a9a79f]">{event.status ?? '-'}</td>
                                                <td className="px-4 py-4 text-[#6f6b61] dark:text-[#a9a79f]">{event.date ?? '-'}</td>
                                            </tr>
                                        ))
                                    ) : (
                                        <tr>
                                            <td className="px-4 py-6 text-sm text-[#6f6b61] dark:text-[#a9a79f]" colSpan="3">
                                                No events available yet.
                                            </td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </Section>
                </div>
            </div>
        </main>
    );
}
