'use client';

import { useQuery } from '@tanstack/react-query';
import { useParams, useRouter } from 'next/navigation';
import { MapPin, Phone, User, Clock, AlertTriangle, ArrowLeft, Stethoscope } from 'lucide-react';
import Link from 'next/link';

async function fetchSOSDetail(id: string) {
  const res = await fetch(`/api/sos/${id}`);
  if (!res.ok) throw new Error('Failed to fetch SOS detail');
  return res.json();
}

export default function SOSDetailPage() {
  const { id } = useParams();
  const router = useRouter();
  
  const { data: alert, isLoading, error } = useQuery({
    queryKey: ['sos-detail', id],
    queryFn: () => fetchSOSDetail(id as string),
    enabled: !!id,
    refetchInterval: 5000, // Keep polling for location updates
  });

  if (isLoading) return <div className="p-8 text-center">Loading alert details...</div>;
  if (error) return <div className="p-8 text-center text-red-600">Error loading alert details</div>;
  if (!alert) return <div className="p-8 text-center">Alert not found</div>;

  const patient = alert.patientId;

  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center space-x-4">
        <Link href="/dashboard/sos" className="p-2 hover:bg-gray-100 rounded-full">
          <ArrowLeft className="h-6 w-6 text-black" />
        </Link>
        <h1 className="text-2xl font-bold text-black">Emergency Alert Details</h1>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Patient Info, Contacts, Status */}
        <div className="space-y-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 className="text-lg font-semibold mb-4 flex items-center text-black">
              <User className="mr-2 h-5 w-5 text-gray-700" /> Patient Information
            </h2>
            <div className="space-y-4">
              <div className="flex items-center">
                <div className="h-12 w-12 rounded-full bg-gray-200 flex items-center justify-center mr-4 overflow-hidden">
                  {patient?.profilePictureUrl ? (
                    <img src={patient.profilePictureUrl} alt={patient.name} className="h-full w-full object-cover" />
                  ) : (
                    <span className="text-xl font-bold text-black">{patient?.name?.[0]}</span>
                  )}
                </div>
                <div>
                  <p className="font-bold text-lg text-black">{patient?.name}</p>
                  <p className="text-sm text-black">{patient?.email}</p>
                </div>
              </div>
              
              <div className="pt-4 border-t border-gray-100 space-y-3">
                <div className="flex justify-between">
                  <span className="text-black">Phone</span>
                  <span className="font-medium text-black">{patient?.phone}</span>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 className="text-lg font-semibold mb-4 flex items-center text-black">
              <Phone className="mr-2 h-5 w-5 text-blue-600" /> Emergency Contacts
            </h2>
            <div className="space-y-4">
              {patient?.emergencyContacts?.map((contact: any, index: number) => (
                <div key={index} className="flex items-start p-4 bg-gray-50 rounded-lg">
                  <div className="bg-blue-100 p-2 rounded-full mr-4">
                    <User className="h-5 w-5 text-blue-600" />
                  </div>
                  <div>
                    <p className="font-medium text-black">{contact.name}</p>
                    <p className="text-sm text-black">{contact.relation}</p>
                    <p className="text-sm font-mono text-blue-600 mt-1">{contact.phone}</p>
                  </div>
                </div>
              ))}
              {(!patient?.emergencyContacts || patient.emergencyContacts.length === 0) && (
                <p className="text-black italic">No emergency contacts listed.</p>
              )}
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 className="text-lg font-semibold mb-4 flex items-center text-black">
              <Clock className="mr-2 h-5 w-5 text-orange-500" /> Alert Status
            </h2>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-black">Status</span>
                <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                  alert.status === 'active' ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'
                }`}>
                  {alert.status.toUpperCase()}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-black">Started At</span>
                <span className="font-medium text-sm text-black">
                  {new Date(alert.timestamp).toLocaleString()}
                </span>
              </div>
              
              {alert.status === 'active' && (
                <div className="pt-4 mt-4 border-t border-gray-100">
                  <p className="text-sm text-black mb-3">
                    Once the emergency is handled, mark this alert as resolved.
                  </p>
                  <button 
                    className="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded-lg transition-colors flex items-center justify-center"
                    onClick={async () => {
                      if (confirm('Are you sure you want to resolve this SOS alert?')) {
                        await fetch('/api/sos', {
                          method: 'PATCH',
                          headers: { 'Content-Type': 'application/json' },
                          body: JSON.stringify({ id: alert._id, status: 'resolved' })
                        });
                        router.refresh();
                      }
                    }}
                  >
                    <CheckCircle className="mr-2 h-4 w-4" /> Mark as Resolved
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Right Column: Map & Recent Doctors */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 className="text-lg font-semibold mb-4 flex items-center text-black">
              <MapPin className="mr-2 h-5 w-5 text-red-600" /> Live Location
            </h2>
            <div className="bg-gray-100 rounded-lg h-96 flex items-center justify-center relative overflow-hidden">
               {alert.location?.lat && alert.location?.lng ? (
                 <iframe
                   width="100%"
                   height="100%"
                   frameBorder="0"
                   style={{ border: 0 }}
                   src={`https://maps.google.com/maps?q=${alert.location.lat},${alert.location.lng}&z=15&output=embed`}
                   allowFullScreen
                 ></iframe>
               ) : (
                 <div className="text-center p-6">
                   <MapPin className="h-12 w-12 text-red-500 mx-auto mb-2 animate-bounce" />
                   <p className="font-mono text-lg">{typeof alert.location === 'string' ? alert.location : JSON.stringify(alert.location)}</p>
                 </div>
               )}
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 className="text-lg font-semibold mb-4 flex items-center text-black">
              <Stethoscope className="mr-2 h-5 w-5 text-green-600" /> Recent Doctors
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {alert.doctors?.map((doctor: any, index: number) => (
                <div key={index} className="flex items-center p-4 bg-gray-50 rounded-lg">
                  <div className="h-12 w-12 rounded-full bg-green-100 flex items-center justify-center mr-4 overflow-hidden">
                     {doctor.profileImage ? (
                        <img src={doctor.profileImage} alt={doctor.name} className="h-full w-full object-cover" />
                     ) : (
                        <Stethoscope className="h-6 w-6 text-green-600" />
                     )}
                  </div>
                  <div>
                    <p className="font-medium text-black">{doctor.name}</p>
                    <p className="text-sm text-black">{doctor.specialization}</p>
                    <p className="text-sm font-mono text-green-600 mt-1">{doctor.phone}</p>
                  </div>
                </div>
              ))}
              {(!alert.doctors || alert.doctors.length === 0) && (
                <p className="text-black italic">No recent doctors found.</p>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

import { CheckCircle } from 'lucide-react';
