'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Plus,
  Pencil,
  Trash2,
  Bell,
  Loader2,
  X,
  Users,
  Stethoscope,
} from 'lucide-react';

type Audience = 'patients' | 'doctors' | 'both';
type NotifType = 'emergency' | 'appointment' | 'tip' | 'general';

interface AdminBroadcastRow {
  _id: string;
  title: string;
  body: string;
  type: NotifType;
  topic: string;
  audience: Audience;
  recipientCount: number;
  createdAt: string;
  updatedAt: string;
}

const emptyForm = {
  title: '',
  body: '',
  type: 'general' as NotifType,
  topic: '',
  audience: 'patients' as Audience,
};

export default function AdminNotificationsPage() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editing, setEditing] = useState<AdminBroadcastRow | null>(null);
  const [formData, setFormData] = useState(emptyForm);

  const queryClient = useQueryClient();

  const { data: broadcasts, isLoading } = useQuery<AdminBroadcastRow[]>({
    queryKey: ['admin-notifications'],
    queryFn: async () => {
      const res = await fetch('/api/admin/notifications');
      if (!res.ok) throw new Error('Failed to load notifications');
      return res.json();
    },
  });

  const createMutation = useMutation({
    mutationFn: async (data: typeof emptyForm) => {
      const res = await fetch('/api/admin/notifications', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || 'Failed to send');
      return json;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-notifications'] });
      setIsModalOpen(false);
      resetForm();
    },
  });

  const updateMutation = useMutation({
    mutationFn: async ({
      id,
      data,
    }: {
      id: string;
      data: typeof emptyForm;
    }) => {
      const res = await fetch(`/api/admin/notifications/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || 'Failed to update');
      return json;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-notifications'] });
      setIsModalOpen(false);
      resetForm();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const res = await fetch(`/api/admin/notifications/${id}`, {
        method: 'DELETE',
      });
      if (!res.ok) {
        const json = await res.json();
        throw new Error(json.error || 'Failed to delete');
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-notifications'] });
    },
  });

  const resetForm = () => {
    setFormData(emptyForm);
    setEditing(null);
  };

  const openCreate = () => {
    resetForm();
    setIsModalOpen(true);
  };

  const openEdit = (row: AdminBroadcastRow) => {
    setEditing(row);
    setFormData({
      title: row.title,
      body: row.body,
      type: row.type,
      topic: row.topic || '',
      audience: row.audience,
    });
    setIsModalOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (editing) {
      updateMutation.mutate({ id: editing._id, data: formData });
    } else {
      createMutation.mutate(formData);
    }
  };

  const audienceLabel = (a: Audience) => {
    if (a === 'patients') return 'Patients app';
    if (a === 'doctors') return 'Doctors app';
    return 'Patients & doctors';
  };

  const typeLabel = (t: NotifType) =>
    t.charAt(0).toUpperCase() + t.slice(1);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">Push notifications</h1>
          <p className="text-sm text-gray-500 mt-1">
            Create broadcasts by tag (type), topic, and audience. Recipients see
            them in the in-app notification list (patient and doctor apps).
          </p>
        </div>
        <button
          type="button"
          onClick={openCreate}
          className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Plus className="w-5 h-5 mr-2" />
          New notification
        </button>
      </div>

      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="bg-gray-50 text-left text-gray-600">
              <tr>
                <th className="px-4 py-3 font-semibold">Title</th>
                <th className="px-4 py-3 font-semibold">Topic</th>
                <th className="px-4 py-3 font-semibold">Tag</th>
                <th className="px-4 py-3 font-semibold">Audience</th>
                <th className="px-4 py-3 font-semibold">Recipients</th>
                <th className="px-4 py-3 font-semibold">Sent</th>
                <th className="px-4 py-3 font-semibold w-28">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {(broadcasts || []).length === 0 && (
                <tr>
                  <td
                    colSpan={7}
                    className="px-4 py-12 text-center text-gray-500"
                  >
                    No broadcasts yet. Create one to notify patients and/or
                    doctors.
                  </td>
                </tr>
              )}
              {(broadcasts || []).map((row) => (
                <tr key={row._id} className="hover:bg-gray-50/80">
                  <td className="px-4 py-3 font-medium text-gray-900 max-w-[200px]">
                    <span className="line-clamp-2">{row.title}</span>
                  </td>
                  <td className="px-4 py-3 text-gray-600 max-w-[140px]">
                    {row.topic || '—'}
                  </td>
                  <td className="px-4 py-3">
                    <span className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium bg-blue-50 text-blue-700">
                      {typeLabel(row.type)}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-700">
                    <span className="flex items-center gap-1">
                      {row.audience === 'patients' && (
                        <Users className="w-4 h-4 text-gray-400" />
                      )}
                      {row.audience === 'doctors' && (
                        <Stethoscope className="w-4 h-4 text-gray-400" />
                      )}
                      {row.audience === 'both' && (
                        <>
                          <Users className="w-4 h-4 text-gray-400" />
                          <Stethoscope className="w-4 h-4 text-gray-400" />
                        </>
                      )}
                      {audienceLabel(row.audience)}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-800 tabular-nums">
                    {row.recipientCount}
                  </td>
                  <td className="px-4 py-3 text-gray-500 whitespace-nowrap">
                    {new Date(row.createdAt).toLocaleString()}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex gap-1">
                      <button
                        type="button"
                        onClick={() => openEdit(row)}
                        className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg"
                        title="Edit"
                      >
                        <Pencil className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          if (
                            confirm(
                              'Delete this broadcast and remove all copies from user devices?'
                            )
                          ) {
                            deleteMutation.mutate(row._id);
                          }
                        }}
                        className="p-2 text-red-600 hover:bg-red-50 rounded-lg"
                        title="Delete"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40">
          <div className="bg-white rounded-2xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between p-4 border-b">
              <div className="flex items-center gap-2">
                <Bell className="w-5 h-5 text-blue-600" />
                <h2 className="text-lg font-bold text-gray-800">
                  {editing ? 'Edit broadcast' : 'New broadcast'}
                </h2>
              </div>
              <button
                type="button"
                onClick={() => {
                  setIsModalOpen(false);
                  resetForm();
                }}
                className="p-2 rounded-lg hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <form onSubmit={handleSubmit} className="p-4 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Title
                </label>
                <input
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  value={formData.title}
                  onChange={(e) =>
                    setFormData({ ...formData, title: e.target.value })
                  }
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Message body
                </label>
                <textarea
                  required
                  rows={4}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  value={formData.body}
                  onChange={(e) =>
                    setFormData({ ...formData, body: e.target.value })
                  }
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Topic (optional label, e.g. &quot;Holiday hours&quot;)
                </label>
                <input
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  value={formData.topic}
                  onChange={(e) =>
                    setFormData({ ...formData, topic: e.target.value })
                  }
                  placeholder="Shown in the app with the notification"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Tag (controls icon / category in app)
                </label>
                <select
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  value={formData.type}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      type: e.target.value as NotifType,
                    })
                  }
                >
                  <option value="general">General</option>
                  <option value="appointment">Appointment</option>
                  <option value="tip">Tip</option>
                  <option value="emergency">Emergency</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Audience
                </label>
                <select
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                  value={formData.audience}
                  disabled={!!editing}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      audience: e.target.value as Audience,
                    })
                  }
                >
                  <option value="patients">Patients only</option>
                  <option value="doctors">Doctors only</option>
                  <option value="both">Both</option>
                </select>
                {editing && (
                  <p className="text-xs text-amber-700 mt-1">
                    Audience cannot be changed when editing; only text and tag
                    update existing copies.
                  </p>
                )}
              </div>
              {(createMutation.error || updateMutation.error) && (
                <p className="text-sm text-red-600">
                  {(createMutation.error || updateMutation.error)?.message}
                </p>
              )}
              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => {
                    setIsModalOpen(false);
                    resetForm();
                  }}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={
                    createMutation.isPending || updateMutation.isPending
                  }
                  className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-60 flex items-center justify-center gap-2"
                >
                  {(createMutation.isPending || updateMutation.isPending) && (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  )}
                  {editing ? 'Save changes' : 'Send to apps'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
