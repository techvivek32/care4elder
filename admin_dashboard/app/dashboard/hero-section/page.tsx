'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Trash2, Edit2, MoveUp, MoveDown, ToggleLeft, ToggleRight, Image as ImageIcon, Save, X } from 'lucide-react';

interface HeroSection {
  _id: string;
  title: string;
  subtitle: string;
  imageUrl: string;
  order: number;
  isActive: boolean;
  type: 'patient' | 'doctor' | 'both';
}

async function fetchHeroes() {
  const res = await fetch('/api/hero-sections');
  if (!res.ok) throw new Error('Failed to fetch hero sections');
  return res.json();
}

export default function HeroSectionPage() {
  const queryClient = useQueryClient();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingHero, setEditingHero] = useState<HeroSection | null>(null);
  const [formData, setFormData] = useState({
    title: '',
    subtitle: '',
    imageUrl: '',
    type: 'both' as 'patient' | 'doctor' | 'both',
    isActive: true,
    order: 0,
  });
  const [isUploading, setIsUploading] = useState(false);

  const { data: heroes, isLoading } = useQuery<HeroSection[]>({
    queryKey: ['hero-sections'],
    queryFn: fetchHeroes,
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => fetch('/api/hero-sections', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    }).then(res => res.json()),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['hero-sections'] });
      setIsModalOpen(false);
      resetForm();
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string, data: any }) => fetch(`/api/hero-sections/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    }).then(res => res.json()),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['hero-sections'] });
      setIsModalOpen(false);
      setEditingHero(null);
      resetForm();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => fetch(`/api/hero-sections/${id}`, { method: 'DELETE' }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['hero-sections'] }),
  });

  const resetForm = () => {
    setFormData({
      title: '',
      subtitle: '',
      imageUrl: '',
      type: 'both',
      isActive: true,
      order: heroes ? heroes.length : 0,
    });
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsUploading(true);
    const formData = new FormData();
    formData.append('file', file);

    try {
      const res = await fetch('/api/upload', {
        method: 'POST',
        body: formData,
      });
      const data = await res.json();
      if (data.urls && data.urls.length > 0) {
        setFormData(prev => ({ ...prev, imageUrl: data.urls[0] }));
      }
    } catch (error) {
      console.error('Upload failed:', error);
    } finally {
      setIsUploading(false);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (editingHero) {
      updateMutation.mutate({ id: editingHero._id, data: formData });
    } else {
      createMutation.mutate(formData);
    }
  };

  const toggleStatus = (hero: HeroSection) => {
    updateMutation.mutate({ id: hero._id, data: { isActive: !hero.isActive } });
  };

  const moveOrder = (hero: HeroSection, direction: 'up' | 'down') => {
    if (!heroes) return;
    const index = heroes.findIndex(h => h._id === hero._id);
    if (direction === 'up' && index > 0) {
      const prevHero = heroes[index - 1];
      updateMutation.mutate({ id: hero._id, data: { order: prevHero.order } });
      updateMutation.mutate({ id: prevHero._id, data: { order: hero.order } });
    } else if (direction === 'down' && index < heroes.length - 1) {
      const nextHero = heroes[index + 1];
      updateMutation.mutate({ id: hero._id, data: { order: nextHero.order } });
      updateMutation.mutate({ id: nextHero._id, data: { order: hero.order } });
    }
  };

  if (isLoading) return <div className="p-8">Loading Hero Sections...</div>;

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-2xl font-bold text-gray-800">Hero Section Management</h1>
        <button
          onClick={() => {
            resetForm();
            setEditingHero(null);
            setIsModalOpen(true);
          }}
          className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
        >
          <Plus className="w-4 h-4 mr-2" />
          Add New Slide
        </button>
      </div>

      <div className="bg-white rounded-xl shadow overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-gray-50 border-b">
              <th className="px-6 py-4 text-sm font-semibold text-gray-600">Image</th>
              <th className="px-6 py-4 text-sm font-semibold text-gray-600">Content</th>
              <th className="px-6 py-4 text-sm font-semibold text-gray-600">Type</th>
              <th className="px-6 py-4 text-sm font-semibold text-gray-600">Order</th>
              <th className="px-6 py-4 text-sm font-semibold text-gray-600">Status</th>
              <th className="px-6 py-4 text-sm font-semibold text-gray-600 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {heroes?.map((hero, index) => (
              <tr key={hero._id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <div className="w-20 h-12 bg-gray-100 rounded overflow-hidden">
                    <img src={hero.imageUrl} alt={hero.title} className="w-full h-full object-cover" />
                  </div>
                </td>
                <td className="px-6 py-4">
                  <div className="font-medium text-gray-800">{hero.title}</div>
                  <div className="text-xs text-gray-500">{hero.subtitle}</div>
                </td>
                <td className="px-6 py-4">
                  <span className="px-2 py-1 text-xs font-medium rounded-full bg-blue-50 text-blue-600 capitalize">
                    {hero.type}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center space-x-1">
                    <button 
                      onClick={() => moveOrder(hero, 'up')}
                      disabled={index === 0}
                      className="p-1 hover:bg-gray-200 rounded disabled:opacity-30"
                    >
                      <MoveUp className="w-4 h-4 text-gray-600" />
                    </button>
                    <button 
                      onClick={() => moveOrder(hero, 'down')}
                      disabled={index === (heroes.length - 1)}
                      className="p-1 hover:bg-gray-200 rounded disabled:opacity-30"
                    >
                      <MoveDown className="w-4 h-4 text-gray-600" />
                    </button>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <button onClick={() => toggleStatus(hero)} className="focus:outline-none">
                    {hero.isActive ? (
                      <ToggleRight className="w-8 h-8 text-green-500" />
                    ) : (
                      <ToggleLeft className="w-8 h-8 text-gray-400" />
                    )}
                  </button>
                </td>
                <td className="px-6 py-4 text-right space-x-2">
                  <button 
                    onClick={() => {
                      setEditingHero(hero);
                      setFormData({
                        title: hero.title,
                        subtitle: hero.subtitle,
                        imageUrl: hero.imageUrl,
                        type: hero.type,
                        isActive: hero.isActive,
                        order: hero.order,
                      });
                      setIsModalOpen(true);
                    }}
                    className="p-2 text-blue-600 hover:bg-blue-50 rounded"
                  >
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button 
                    onClick={() => {
                      if(confirm('Are you sure you want to delete this slide?')) {
                        deleteMutation.mutate(hero._id);
                      }
                    }}
                    className="p-2 text-red-600 hover:bg-red-50 rounded"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-lg overflow-hidden">
            <div className="flex justify-between items-center p-6 border-b">
              <h2 className="text-xl font-bold text-gray-900">
                {editingHero ? 'Edit Slide' : 'Add New Slide'}
              </h2>
              <button onClick={() => setIsModalOpen(false)} className="text-gray-500 hover:text-gray-700">
                <X className="w-6 h-6" />
              </button>
            </div>
            
            <form onSubmit={handleSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-900 mb-1">Title</label>
                <input
                  type="text"
                  required
                  value={formData.title}
                  onChange={e => setFormData({ ...formData, title: e.target.value })}
                  className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none text-gray-900"
                  placeholder="Slide title"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-900 mb-1">Subtitle</label>
                <input
                  type="text"
                  value={formData.subtitle}
                  onChange={e => setFormData({ ...formData, subtitle: e.target.value })}
                  className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none text-gray-900"
                  placeholder="Slide subtitle"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-900 mb-1">Target Audience</label>
                <select
                  value={formData.type}
                  onChange={e => setFormData({ ...formData, type: e.target.value as any })}
                  className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none text-gray-900"
                >
                  <option value="patient">Patient App</option>
                  <option value="doctor">Doctor App</option>
                  <option value="both">Both Apps</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-900 mb-1">Slide Image</label>
                <div className="mt-1 flex items-center space-x-4">
                  {formData.imageUrl ? (
                    <div className="relative w-24 h-24 border rounded-lg overflow-hidden bg-gray-50">
                      <img src={formData.imageUrl} className="w-full h-full object-cover" />
                      <button 
                        type="button"
                        onClick={() => setFormData({ ...formData, imageUrl: '' })}
                        className="absolute top-1 right-1 p-1 bg-white/80 rounded-full text-red-600 shadow-sm"
                      >
                        <X className="w-3 h-3" />
                      </button>
                    </div>
                  ) : (
                    <label className="w-24 h-24 border-2 border-dashed rounded-lg flex flex-col items-center justify-center cursor-pointer hover:bg-gray-50 transition">
                      <ImageIcon className="w-8 h-8 text-gray-400" />
                      <span className="text-[10px] text-gray-500 mt-1">Upload</span>
                      <input type="file" className="hidden" accept="image/*" onChange={handleFileUpload} />
                    </label>
                  )}
                  <div className="flex-1 text-xs text-gray-500">
                    {isUploading ? 'Uploading...' : 'Recommended size: 1200x600px. Max 2MB.'}
                  </div>
                </div>
              </div>

              <div className="flex items-center space-x-2 pt-2">
                <input 
                  type="checkbox"
                  id="isActive"
                  checked={formData.isActive}
                  onChange={e => setFormData({ ...formData, isActive: e.target.checked })}
                  className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
                />
                <label htmlFor="isActive" className="text-sm font-medium text-gray-900">Active Slide</label>
              </div>

              <div className="flex justify-end space-x-3 pt-6 border-t">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={createMutation.isPending || updateMutation.isPending || isUploading}
                  className="flex items-center px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition disabled:opacity-50"
                >
                  <Save className="w-4 h-4 mr-2" />
                  {editingHero ? 'Update Slide' : 'Save Slide'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
