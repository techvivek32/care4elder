'use client';

import { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { AlertOctagon, CheckCircle, MapPin, ExternalLink, Trash2, Search, Filter } from 'lucide-react';

async function fetchSOS(params: Record<string, string>) {
  const qs = new URLSearchParams(params).toString();
  const res = await fetch(`/api/sos?${qs}`);
  if (!res.ok) throw new Error('Failed to fetch SOS alerts');
  return res.json();
}

async function resolveSOS(id: string) {
  const res = await fetch('/api/sos', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id, status: 'resolved' }),
  });
  if (!res.ok) throw new Error('Failed to resolve alert');
  return res.json();
}

async function deleteSOS(id: string) {
  const res = await fetch(`/api/sos/${id}`, { method: 'DELETE' });
  if (!res.ok) throw new Error('Failed to delete alert');
  return res.json();
}

async function bulkDeleteSOS(ids: string[]) {
  const res = await fetch('/api/sos', {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ids }),
  });
  if (!res.ok) throw new Error('Failed to bulk delete');
  return res.json();
}

export default function SOSPage() {
  const queryClient = useQueryClient();

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [selected, setSelected] = useState<string[]>([]);

  const queryParams = useMemo(() => {
    const p: Record<string, string> = {};
    if (search) p.search = search;
    if (statusFilter) p.status = statusFilter;
    if (dateFrom) p.dateFrom = dateFrom;
    if (dateTo) p.dateTo = dateTo;
    return p;
  }, [search, statusFilter, dateFrom, dateTo]);

  const { data: alerts = [], isLoading, error } = useQuery({
    queryKey: ['active-sos', queryParams],
    queryFn: () => fetchSOS(queryParams),
    refetchInterval: 5000,
  });

  const resolveMutation = useMutation({
    mutationFn: resolveSOS,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['active-sos'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteSOS,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['active-sos'] }),
  });

  const bulkDeleteMutation = useMutation({
    mutationFn: bulkDeleteSOS,
    onSuccess: () => {
      setSelected([]);
      queryClient.invalidateQueries({ queryKey: ['active-sos'] });
    },
  });

  const allIds: string[] = alerts.map((a: any) => a._id);
  const allSelected = allIds.length > 0 && allIds.every((id) => selected.includes(id));

  const toggleSelect = (id: string) =>
    setSelected((prev) => prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]);

  const toggleSelectAll = () =>
    setSelected(allSelected ? [] : allIds);

  const handleBulkDelete = () => {
    if (selected.length === 0) return;
    if (confirm(`Delete ${selected.length} selected alert(s)?`)) {
      bulkDeleteMutation.mutate(selected);
    }
  };

  if (isLoading) return <div className="p-6">Loading alerts...</div>;
  if (error) return <div className="p-6 text-red-600">Error loading alerts</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-800 flex items-center">
        <AlertOctagon className="mr-2 h-8 w-8 text-red-600" /> SOS Alerts Management
      </h1>

      {/* Filters */}
      <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200 space-y-3">
        <div className="flex flex-wrap gap-3">
          {/* Search */}
          <div className="relative flex-1 min-w-[200px]">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search by patient name or phone..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-md text-sm bg-white text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Status filter */}
          <div className="relative min-w-[160px]">
            <Filter className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-md text-sm bg-white text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 appearance-none"
            >
              <option value="">All Status</option>
              <option value="active">Active (Not Resolved)</option>
              <option value="resolved">Resolved</option>
            </select>
          </div>

          {/* Date From */}
          <div className="flex items-center gap-2">
            <label className="text-sm text-gray-600 whitespace-nowrap">From:</label>
            <input
              type="date"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
              className="border border-gray-300 rounded-md px-3 py-2 text-sm bg-white text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Date To */}
          <div className="flex items-center gap-2">
            <label className="text-sm text-gray-600 whitespace-nowrap">To:</label>
            <input
              type="date"
              value={dateTo}
              onChange={(e) => setDateTo(e.target.value)}
              className="border border-gray-300 rounded-md px-3 py-2 text-sm bg-white text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Clear filters */}
          {(search || statusFilter || dateFrom || dateTo) && (
            <button
              onClick={() => { setSearch(''); setStatusFilter(''); setDateFrom(''); setDateTo(''); }}
              className="px-3 py-2 text-sm text-gray-600 border border-gray-300 rounded-md hover:bg-gray-50"
            >
              Clear
            </button>
          )}
        </div>
      </div>

      {/* Bulk action bar */}
      {selected.length > 0 && (
        <div className="flex items-center gap-3 bg-red-50 border border-red-200 rounded-lg px-4 py-3">
          <span className="text-sm font-medium text-red-700">{selected.length} selected</span>
          <button
            onClick={handleBulkDelete}
            disabled={bulkDeleteMutation.isPending}
            className="flex items-center gap-1 bg-red-600 text-white px-3 py-1.5 rounded-md text-sm hover:bg-red-700 disabled:opacity-50"
          >
            <Trash2 className="h-4 w-4" />
            {bulkDeleteMutation.isPending ? 'Deleting...' : 'Delete Selected'}
          </button>
          <button
            onClick={() => setSelected([])}
            className="text-sm text-gray-500 hover:text-gray-700"
          >
            Cancel
          </button>
        </div>
      )}

      {/* Select All row */}
      {alerts.length > 0 && (
        <div className="flex items-center gap-2 px-1">
          <input
            type="checkbox"
            checked={allSelected}
            onChange={toggleSelectAll}
            className="h-4 w-4 rounded border-gray-300 text-blue-600"
          />
          <span className="text-sm text-gray-600">Select All ({alerts.length})</span>
        </div>
      )}

      {/* Alerts list */}
      <div className="space-y-4">
        {alerts.length === 0 ? (
          <div className="bg-gray-50 p-6 rounded-md text-gray-500 text-center">No alerts found.</div>
        ) : (
          alerts.map((alert: any) => {
            const isResolved = alert.status === 'resolved';
            const isChecked = selected.includes(alert._id);
            return (
              <div
                key={alert._id}
                className={`border-l-4 p-4 shadow-sm rounded-r-md flex flex-col md:flex-row justify-between items-start gap-4 ${
                  isResolved ? 'bg-green-50 border-green-500' : 'bg-red-50 border-red-500'
                }`}
              >
                {/* Checkbox */}
                <div className="flex items-start pt-1">
                  <input
                    type="checkbox"
                    checked={isChecked}
                    onChange={() => toggleSelect(alert._id)}
                    className="h-4 w-4 rounded border-gray-300 text-blue-600"
                  />
                </div>

                <div className="flex-1">
                  <div className="flex items-center gap-3">
                    <h3 className={`text-lg font-bold ${isResolved ? 'text-green-800' : 'text-red-800'}`}>
                      {isResolved ? 'Resolved Alert' : 'Active Emergency'}
                    </h3>
                    <span className={`px-2 py-1 rounded-full text-xs font-bold uppercase tracking-wide ${
                      isResolved ? 'bg-green-200 text-green-800' : 'bg-red-200 text-red-800 animate-pulse'
                    }`}>
                      {alert.status}
                    </span>
                  </div>
                  <p className={`text-sm mt-2 ${isResolved ? 'text-green-700' : 'text-red-700'}`}>
                    <span className="font-semibold">Patient:</span> {alert.patientId?.name || 'Unknown'} <br />
                    <span className="font-semibold">Phone:</span> {alert.patientId?.phone || 'N/A'} <br />
                    <span className="font-semibold">Time:</span> {new Date(alert.timestamp).toLocaleString()}
                  </p>
                  <div className="mt-2 text-sm text-gray-600 flex items-center">
                    <MapPin className="h-4 w-4 mr-1" />
                    Location: {typeof alert.location === 'string' ? alert.location : JSON.stringify(alert.location)}
                  </div>
                </div>

                <div className="flex flex-col space-y-2 w-full md:w-auto">
                  <Link
                    href={`/dashboard/sos/${alert._id}`}
                    className="bg-blue-600 text-white px-4 py-2 rounded-md shadow-sm hover:bg-blue-700 flex items-center justify-center transition-colors"
                  >
                    <ExternalLink className="mr-2 h-4 w-4" /> View Details
                  </Link>

                  {!isResolved ? (
                    <button
                      onClick={() => resolveMutation.mutate(alert._id)}
                      disabled={resolveMutation.isPending}
                      className="bg-white text-green-600 px-4 py-2 border border-green-200 rounded-md shadow-sm hover:bg-green-50 flex items-center justify-center transition-colors disabled:opacity-50"
                    >
                      <CheckCircle className="mr-2 h-4 w-4" /> Mark Resolved
                    </button>
                  ) : (
                    <button disabled className="bg-gray-100 text-gray-400 px-4 py-2 border border-gray-200 rounded-md shadow-sm flex items-center justify-center cursor-not-allowed">
                      <CheckCircle className="mr-2 h-4 w-4" /> Resolved
                    </button>
                  )}

                  <button
                    onClick={() => {
                      if (confirm('Delete this alert?')) deleteMutation.mutate(alert._id);
                    }}
                    disabled={deleteMutation.isPending}
                    className="bg-white text-gray-600 px-4 py-2 border border-gray-200 rounded-md shadow-sm hover:bg-gray-100 flex items-center justify-center transition-colors disabled:opacity-50"
                  >
                    <Trash2 className="mr-2 h-4 w-4" /> Delete
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
