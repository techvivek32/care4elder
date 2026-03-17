'use client';

import { useState, useEffect } from 'react';
import { CheckCircle, XCircle, Clock, RefreshCw } from 'lucide-react';

interface RefundRequest {
  _id: string;
  patientName: string;
  doctorName: string;
  amount: number;
  reason: string;
  status: 'pending' | 'approved' | 'rejected';
  adminNote?: string;
  createdAt: string;
}

export default function RefundRequestsPage() {
  const [refunds, setRefunds] = useState<RefundRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('all');
  const [processing, setProcessing] = useState<string | null>(null);
  const [adminNote, setAdminNote] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const fetchRefunds = async () => {
    setLoading(true);
    try {
      const url = filter === 'all' ? '/api/refund-requests' : `/api/refund-requests?status=${filter}`;
      const res = await fetch(url);
      const data = await res.json();
      setRefunds(data.refunds || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchRefunds(); }, [filter]);

  const handleAction = async (id: string, status: 'approved' | 'rejected') => {
    setProcessing(id);
    try {
      const res = await fetch(`/api/refund-requests/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status, adminNote: adminNote || undefined }),
      });
      if (res.ok) {
        setAdminNote('');
        setSelectedId(null);
        fetchRefunds();
      }
    } finally {
      setProcessing(null);
    }
  };

  const statusBadge = (status: string) => {
    if (status === 'pending') return <span className="px-2 py-1 text-xs font-semibold bg-yellow-100 text-yellow-800 rounded-full flex items-center gap-1"><Clock className="h-3 w-3" />Pending</span>;
    if (status === 'approved') return <span className="px-2 py-1 text-xs font-semibold bg-green-100 text-green-800 rounded-full flex items-center gap-1"><CheckCircle className="h-3 w-3" />Approved</span>;
    return <span className="px-2 py-1 text-xs font-semibold bg-red-100 text-red-800 rounded-full flex items-center gap-1"><XCircle className="h-3 w-3" />Rejected</span>;
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-900">Refund Requests</h1>
        <button onClick={fetchRefunds} className="flex items-center gap-2 px-3 py-2 text-sm border rounded-md hover:bg-gray-50">
          <RefreshCw className="h-4 w-4" /> Refresh
        </button>
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2">
        {(['all', 'pending', 'approved', 'rejected'] as const).map(f => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2 text-sm rounded-md font-medium capitalize ${filter === f ? 'bg-blue-600 text-white' : 'bg-white border text-gray-600 hover:bg-gray-50'}`}
          >
            {f}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="text-center py-12 text-gray-500">Loading...</div>
      ) : refunds.length === 0 ? (
        <div className="text-center py-12 text-gray-500">No refund requests found.</div>
      ) : (
        <div className="bg-white shadow rounded-lg overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                {['Patient', 'Doctor', 'Amount', 'Reason', 'Status', 'Date', 'Actions'].map(h => (
                  <th key={h} className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {refunds.map(r => (
                <tr key={r._id}>
                  <td className="px-6 py-4 text-sm text-gray-900">{r.patientName || '—'}</td>
                  <td className="px-6 py-4 text-sm text-gray-900">{r.doctorName || '—'}</td>
                  <td className="px-6 py-4 text-sm font-semibold text-gray-900">₹{Number(r.amount).toFixed(2)}</td>
                  <td className="px-6 py-4 text-sm text-gray-600 max-w-xs truncate">{r.reason}</td>
                  <td className="px-6 py-4">{statusBadge(r.status)}</td>
                  <td className="px-6 py-4 text-sm text-gray-500">{new Date(r.createdAt).toLocaleDateString()}</td>
                  <td className="px-6 py-4">
                    {r.status === 'pending' ? (
                      <div className="flex flex-col gap-2">
                        {selectedId === r._id && (
                          <input
                            type="text"
                            placeholder="Admin note (optional)"
                            value={adminNote}
                            onChange={e => setAdminNote(e.target.value)}
                            className="text-xs border rounded px-2 py-1 w-40"
                          />
                        )}
                        <div className="flex gap-2">
                          <button
                            onClick={() => { setSelectedId(r._id); handleAction(r._id, 'approved'); }}
                            disabled={processing === r._id}
                            className="px-3 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50"
                          >
                            Approve
                          </button>
                          <button
                            onClick={() => { setSelectedId(r._id); handleAction(r._id, 'rejected'); }}
                            disabled={processing === r._id}
                            className="px-3 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700 disabled:opacity-50"
                          >
                            Reject
                          </button>
                        </div>
                      </div>
                    ) : (
                      <span className="text-xs text-gray-400">{r.adminNote || '—'}</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
